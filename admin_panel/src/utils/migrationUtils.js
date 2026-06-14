/**
 * Migration Utilities for Product-Category Relationship Fix
 * 
 * This utility provides functions to:
 * 1. Scan all existing products
 * 2. Recalculate product counts from actual products collection
 * 3. Update every category document
 * 4. Repair existing products with incorrect category field format
 * 5. Safe to run multiple times
 */

import { collection, getDocs, updateDoc, doc, writeBatch } from 'firebase/firestore'
import { db } from '../services/firebase'

const PRODUCTS_COLLECTION = 'products'
const CATEGORIES_COLLECTION = 'categories'

/**
 * Log migration event with consistent formatting
 */
const logMigration = (level, title, data = {}) => {
  const timestamp = new Date().toISOString()
  const prefix = {
    INFO: '📋',
    SUCCESS: '✅',
    WARNING: '⚠️',
    ERROR: '❌',
    DEBUG: '🔍'
  }[level] || '📋'

  console.log(`${prefix} [${timestamp}] ${title}`, data)
}

/**
 * Step 1: Scan all products and get their category distribution
 */
export const scanProducts = async () => {
  logMigration('INFO', 'MIGRATION: Starting product scan...')

  try {
    const snapshot = await getDocs(collection(db, PRODUCTS_COLLECTION))
    const products = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))

    const categoryDistribution = {}
    const categoryIssues = []

    products.forEach(product => {
      const category = product.category || 'UNCATEGORIZED'
      categoryDistribution[category] = (categoryDistribution[category] || 0) + 1

      // Check for issues in category field
      if (!product.category) {
        categoryIssues.push({ id: product.id, name: product.name, issue: 'missing category' })
      } else if (typeof product.category !== 'string') {
        categoryIssues.push({ id: product.id, name: product.name, issue: 'invalid category type', value: product.category })
      }
    })

    logMigration('INFO', 'MIGRATION: Product scan complete', {
      totalProducts: products.length,
      uniqueCategories: Object.keys(categoryDistribution).length,
      distribution: categoryDistribution,
      issues: categoryIssues.length > 0 ? categoryIssues : 'none'
    })

    return { products, categoryDistribution, categoryIssues }
  } catch (error) {
    logMigration('ERROR', 'MIGRATION: Failed to scan products', { error: error.message })
    throw error
  }
}

/**
 * Step 2: Scan categories and get current state
 */
export const scanCategories = async () => {
  logMigration('INFO', 'MIGRATION: Starting category scan...')

  try {
    const snapshot = await getDocs(collection(db, CATEGORIES_COLLECTION))
    const categories = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }))

    logMigration('INFO', 'MIGRATION: Category scan complete', {
      totalCategories: categories.length,
      categories: categories.map(c => ({ id: c.id, name: c.name, currentCount: c.productCount }))
    })

    return categories
  } catch (error) {
    logMigration('ERROR', 'MIGRATION: Failed to scan categories', { error: error.message })
    throw error
  }
}

/**
 * Step 3: Calculate correct product counts based on actual products
 */
export const calculateCorrectCounts = async () => {
  logMigration('INFO', 'MIGRATION: Calculating correct product counts...')

  try {
    const { products } = await scanProducts()
    const categories = await scanCategories()

    const correctCounts = {}
    products.forEach(product => {
      const category = product.category || 'UNCATEGORIZED'
      correctCounts[category] = (correctCounts[category] || 0) + 1
    })

    const countChanges = []
    categories.forEach(category => {
      const currentCount = category.productCount || 0
      const correctCount = correctCounts[category.name] || 0
      if (currentCount !== correctCount) {
        countChanges.push({
          id: category.id,
          name: category.name,
          currentCount,
          correctCount,
          difference: correctCount - currentCount
        })
      }
    })

    logMigration('INFO', 'MIGRATION: Correct counts calculated', {
      correctCounts,
      changesRequired: countChanges.length,
      changes: countChanges
    })

    return { correctCounts, countChanges }
  } catch (error) {
    logMigration('ERROR', 'MIGRATION: Failed to calculate counts', { error: error.message })
    throw error
  }
}

/**
 * Step 4: Update all category documents with correct product counts
 */
export const updateCategoryProductCounts = async () => {
  logMigration('INFO', 'MIGRATION: Updating category product counts...')

  try {
    const { correctCounts, countChanges } = await calculateCorrectCounts()

    if (countChanges.length === 0) {
      logMigration('SUCCESS', 'MIGRATION: All category counts are already correct', { message: 'No updates needed' })
      return { updated: 0, changes: [] }
    }

    const batch = writeBatch(db)
    let updateCount = 0

    countChanges.forEach(change => {
      logMigration('DEBUG', 'MIGRATION: Queuing category count update', {
        category: change.name,
        from: change.currentCount,
        to: change.correctCount,
        delta: change.difference
      })

      const categoryRef = doc(db, CATEGORIES_COLLECTION, change.id)
      batch.update(categoryRef, {
        productCount: change.correctCount,
        updatedAt: new Date().toISOString(),
        migrationFixedAt: new Date().toISOString()
      })
      updateCount++
    })

    await batch.commit()

    logMigration('SUCCESS', 'MIGRATION: Category product counts updated', {
      updated: updateCount,
      changes: countChanges
    })

    return { updated: updateCount, changes: countChanges }
  } catch (error) {
    logMigration('ERROR', 'MIGRATION: Failed to update category counts', { error: error.message })
    throw error
  }
}

/**
 * Step 5: Repair products with invalid category format
 * Converts invalid category values to valid category IDs by matching against category collection
 */
export const repairProductCategories = async () => {
  logMigration('INFO', 'MIGRATION: Repairing product categories...')

  try {
    const { products, categoryIssues } = await scanProducts()
    const categories = await scanCategories()

    // Create mappings
    const categoryNameToId = new Map(categories.map(c => [c.name, c.id]))
    const categoryIdSet = new Set(categories.map(c => c.id))

    const repairs = []
    const batch = writeBatch(db)

    products.forEach(product => {
      if (!product.category) {
        // Product has no category - flag as issue but don't repair
        logMigration('DEBUG', 'MIGRATION: Product missing category', {
          id: product.id,
          name: product.name,
          action: 'will leave as is (no category assignment)'
        })
        return
      }

      // Check if category is already a valid ID
      const isValidId = categoryIdSet.has(product.category)

      if (!isValidId) {
        // Category might be a name, try to convert it to ID
        const possibleId = categoryNameToId.get(product.category)
        if (possibleId) {
          repairs.push({
            id: product.id,
            name: product.name,
            from: product.category,
            to: possibleId,
            type: 'NAME_TO_ID_CONVERSION'
          })

          logMigration('DEBUG', 'MIGRATION: Queuing product category repair', {
            id: product.id,
            from: product.category,
            to: possibleId
          })

          const productRef = doc(db, PRODUCTS_COLLECTION, product.id)
          batch.update(productRef, {
            category: possibleId,
            updatedAt: new Date().toISOString(),
            migrationFixedAt: new Date().toISOString()
          })
        } else {
          // Category doesn't match any known category ID or name - log as issue
          logMigration('WARNING', 'MIGRATION: Unknown category in product', {
            id: product.id,
            name: product.name,
            category: product.category,
            action: 'no matching category found, skipping'
          })
        }
      }
    })

    if (repairs.length > 0) {
      await batch.commit()
      logMigration('SUCCESS', 'MIGRATION: Product categories repaired', {
        repaired: repairs.length,
        repairs
      })
    } else {
      logMigration('SUCCESS', 'MIGRATION: All product categories are valid', {
        message: 'No repairs needed'
      })
    }

    return { repaired: repairs.length, repairs }
  } catch (error) {
    logMigration('ERROR', 'MIGRATION: Failed to repair product categories', { error: error.message })
    throw error
  }
}

/**
 * MAIN: Run complete migration
 * Safe to run multiple times - only updates what has changed
 */
export const runCompleteMigration = async () => {
  logMigration('INFO', '═══════════════════════════════════════')
  logMigration('INFO', '🔧 STARTING COMPLETE MIGRATION')
  logMigration('INFO', '═══════════════════════════════════════')

  const startTime = Date.now()

  try {
    // Step 1: Scan current state
    logMigration('INFO', '--- Step 1: Scanning Current State ---')
    const initialScan = await scanProducts()

    // Step 2: Repair product categories
    logMigration('INFO', '--- Step 2: Repairing Product Categories ---')
    const repairResult = await repairProductCategories()

    // Step 3: Update category counts
    logMigration('INFO', '--- Step 3: Updating Category Counts ---')
    const countResult = await updateCategoryProductCounts()

    // Step 4: Verify results
    logMigration('INFO', '--- Step 4: Verifying Results ---')
    const finalScan = await scanProducts()
    const finalCategories = await scanCategories()

    const elapsedTime = Date.now() - startTime

    logMigration('SUCCESS', '═══════════════════════════════════════')
    logMigration('SUCCESS', '🎉 MIGRATION COMPLETE')
    logMigration('SUCCESS', '═══════════════════════════════════════')

    const summary = {
      duration: `${elapsedTime}ms`,
      results: {
        productsRepaired: repairResult.repaired,
        categoriesUpdated: countResult.updated,
        totalProducts: finalScan.products.length,
        totalCategories: finalCategories.length,
        categoryDistribution: finalScan.categoryDistribution
      },
      before: {
        totalProducts: initialScan.products.length,
        distribution: initialScan.categoryDistribution
      },
      after: {
        totalProducts: finalScan.products.length,
        distribution: finalScan.categoryDistribution
      }
    }

    logMigration('SUCCESS', 'MIGRATION: Summary', summary)

    return summary
  } catch (error) {
    logMigration('ERROR', '═══════════════════════════════════════')
    logMigration('ERROR', '❌ MIGRATION FAILED')
    logMigration('ERROR', '═══════════════════════════════════════', { error: error.message })
    throw error
  }
}

/**
 * Verify migration results
 * Returns detailed report of current state
 */
export const verifyMigrationResults = async () => {
  logMigration('INFO', 'MIGRATION: Verifying results...')

  try {
    const { products, categoryDistribution } = await scanProducts()
    const categories = await scanCategories()

    const report = {
      timestamp: new Date().toISOString(),
      products: {
        total: products.length,
        byCategory: categoryDistribution,
        withoutCategory: products.filter(p => !p.category).length
      },
      categories: categories.map(c => ({
        id: c.id,
        name: c.name,
        storedCount: c.productCount,
        actualCount: categoryDistribution[c.name] || 0,
        matches: c.productCount === (categoryDistribution[c.name] || 0)
      })),
      allCountsCorrect: categories.every(c => c.productCount === (categoryDistribution[c.name] || 0))
    }

    logMigration('INFO', 'MIGRATION: Verification report', report)

    return report
  } catch (error) {
    logMigration('ERROR', 'MIGRATION: Verification failed', { error: error.message })
    throw error
  }
}

/**
 * Export all utility functions for window access in browser console
 */
export const migrationUtils = {
  runCompleteMigration,
  scanProducts,
  scanCategories,
  calculateCorrectCounts,
  updateCategoryProductCounts,
  repairProductCategories,
  verifyMigrationResults,
  logMigration
}

// Make available globally in browser console
if (typeof window !== 'undefined') {
  window.migrationUtils = migrationUtils
}

export default migrationUtils
