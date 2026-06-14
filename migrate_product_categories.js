/**
 * MIGRATION: Fix Product Category Values
 * 
 * Changes all products from using category NAMES to category IDs
 * Example: "Visiting Cards" → "CAT001"
 * 
 * REQUIREMENTS:
 * - GOOGLE_APPLICATION_CREDENTIALS env var pointing to Firebase service account key
 * 
 * HOW TO RUN:
 * 1. Get Firebase service account key from: https://console.firebase.google.com/project/print-5cc56/settings/serviceaccounts/adminsdk
 * 2. Save as: printx/serviceAccountKey.json
 * 3. Set env var: set GOOGLE_APPLICATION_CREDENTIALS=serviceAccountKey.json
 * 4. Run: node migrate_product_categories.js
 */

import admin from 'firebase-admin';
import { mockCategories } from './admin_panel/src/data/mockData.js';
import fs from 'fs';
import path from 'path';

// Category name to ID mapping (from mockData.js)
const categoryNameToId = {
  'Visiting Cards': 'CAT001',
  'T-Shirts & Apparel': 'CAT002',
  'Banners & Signage': 'CAT003',
  'Drinkware': 'CAT004',
  'Flyers & Brochures': 'CAT005',
  'Stationery': 'CAT006',
  'Office Essentials': 'CAT007',
  'Stickers & Labels': 'CAT008',
  'Invitations': 'CAT009',
  'Bags & Accessories': 'CAT010',
  'Gifts': 'CAT011',
  'Photo Prints': 'CAT012',
};

// Find service account key
const serviceAccountPath = path.join(process.cwd(), 'serviceAccountKey.json');
let serviceAccount = null;

if (!fs.existsSync(serviceAccountPath)) {
  console.log('❌ serviceAccountKey.json not found!');
  console.log('\n📖 SETUP INSTRUCTIONS:');
  console.log('1. Go to: https://console.firebase.google.com/u/0/project/print-5cc56/settings/serviceaccounts/adminsdk');
  console.log('2. Click "Generate new private key"');
  console.log('3. Save the JSON file as: printx/serviceAccountKey.json');
  console.log('4. Run this script again\n');
  process.exit(1);
}

try {
  serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
} catch (error) {
  console.log('❌ Failed to parse serviceAccountKey.json:', error.message);
  process.exit(1);
}

// Initialize Firebase Admin
try {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log(`✅ Initialized Firebase for project: ${serviceAccount.project_id}`);
} catch (error) {
  console.log('❌ Failed to initialize Firebase:', error.message);
  process.exit(1);
}

const db = admin.firestore();

async function runMigration() {
  try {
    console.log('\n' + '='.repeat(80));
    console.log('MIGRATION: Fix Product Category Values');
    console.log('='.repeat(80));

    console.log('\n📂 Category Mapping:');
    Object.entries(categoryNameToId).forEach(([name, id]) => {
      console.log(`  "${name}" → "${id}"`);
    });

    // Fetch all products from Firestore
    console.log('\n📥 Fetching products from Firestore...');
    const snapshot = await db.collection('products').get();
    console.log(`  Found ${snapshot.size} products`);

    if (snapshot.size === 0) {
      console.log('  ℹ️  No products found. Nothing to migrate.');
      process.exit(0);
    }

    // Analyze what needs to be fixed
    console.log('\n🔍 Analyzing products...');
    let toFix = [];
    let alreadyCorrect = [];
    let unmappedCategories = new Set();

    snapshot.forEach((doc) => {
      const product = doc.data();
      const currentCategory = product.category;
      const correctCategoryId = categoryNameToId[currentCategory];

      if (!correctCategoryId) {
        if (!['general', 'cat', ''].includes(currentCategory)) {
          unmappedCategories.add(currentCategory);
        }
        if (currentCategory !== 'general') {
          alreadyCorrect.push({ id: doc.id, name: product.name, category: currentCategory });
        }
      } else {
        toFix.push({ id: doc.id, name: product.name, oldCategory: currentCategory, newCategory: correctCategoryId });
      }
    });

    if (unmappedCategories.size > 0) {
      console.log(`  ⚠️  Found ${unmappedCategories.size} unmapped categories:`, Array.from(unmappedCategories));
    }

    if (alreadyCorrect.length > 0) {
      console.log(`  ✅ ${alreadyCorrect.length} products already have correct category`);
    }

    if (toFix.length === 0) {
      console.log(`  ✅ All ${snapshot.size} products already use category IDs!`);
      console.log('\nNo migration needed.');
      process.exit(0);
    }

    console.log(`  ❌ ${toFix.length} products need fixing:`);
    toFix.slice(0, 5).forEach((p) => {
      console.log(`    - ${p.id}: "${p.oldCategory}" → "${p.newCategory}"`);
    });
    if (toFix.length > 5) {
      console.log(`    ... and ${toFix.length - 5} more`);
    }

    // Perform the migration
    console.log('\n💾 Updating Firestore...');
    const batch = db.batch();
    let updateCount = 0;

    toFix.forEach((product) => {
      const docRef = db.collection('products').doc(product.id);
      batch.update(docRef, {
        category: product.newCategory,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      updateCount++;
    });

    await batch.commit();
    console.log(`  ✅ Updated ${updateCount} products`);

    // Verify the migration
    console.log('\n🔎 Verifying migration...');
    const verifySnapshot = await db.collection('products').get();
    let fixed = 0;
    let stillWrong = 0;

    verifySnapshot.forEach((doc) => {
      const product = doc.data();
      const mappedId = categoryNameToId[product.category];
      
      if (mappedId) {
        // This was in toFix and should now be fixed
        if (product.category === mappedId) {
          fixed++;
        } else {
          stillWrong++;
        }
      }
    });

    console.log(`  ✅ Successfully fixed: ${fixed} products`);
    if (stillWrong > 0) {
      console.log(`  ❌ Still need fixing: ${stillWrong} products`);
    }

    console.log('\n' + '='.repeat(80));
    console.log('Migration completed successfully! ✅');
    console.log('='.repeat(80));
    console.log('\nNext steps:');
    console.log('1. Restart the Flutter mobile app');
    console.log('2. Category pages should now show products');
    console.log('3. Verify in admin panel and mobile app');

  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  }
}

runMigration().then(() => {
  admin.app().delete();
  process.exit(0);
});
