import { create } from 'zustand'
import { collection, deleteDoc, doc, getDocs, setDoc, updateDoc, writeBatch, increment } from 'firebase/firestore'
import { mockProducts } from '../data/mockData'
import { db, isFirebaseConfigured, serverTimestamp } from '../services/firebase'

const COLLECTION = 'products'
const CATEGORIES_COLLECTION = 'categories'
const PRODUCT_UPLOAD_URL = import.meta.env.VITE_BANNER_UPLOAD_URL || 'https://jenishaonlineservice.com/printx/api/upload-banner.php'

const omitUndefined = (values) => Object.fromEntries(Object.entries(values).filter(([, value]) => value !== undefined))

const uploadProductImage = async (file, productId) => {
  if (!file) return null
  const formData = new FormData()
  formData.append('bannerId', productId)
  formData.append('image', file)

  const response = await fetch(PRODUCT_UPLOAD_URL, {
    method: 'POST',
    body: formData,
  })

  const data = await response.json().catch(() => null)
  if (!response.ok) {
    throw new Error(data?.error || 'Failed to upload product image')
  }
  if (!data?.url) {
    throw new Error('Upload endpoint did not return an image URL')
  }
  return data.url
}

/**
 * Update category productCount in Firestore
 * @param {string} categoryId - The category ID (Firestore document ID)
 * @param {number} delta - +1 to increment, -1 to decrement
 */
const updateCategoryProductCount = async (categoryId, delta) => {
  if (!isFirebaseConfigured || !categoryId) return

  try {
    console.log(`📊 [FIRESTORE] Updating category product count:`, {
      categoryId,
      delta,
      operation: delta > 0 ? 'INCREMENT' : 'DECREMENT'
    })

    const categoryRef = doc(db, CATEGORIES_COLLECTION, categoryId)
    
    // Update the category document
    await updateDoc(categoryRef, {
      productCount: increment(delta),
      updatedAt: serverTimestamp(),
    })
    console.log(`✅ [FIRESTORE] Category product count updated:`, {
      categoryId,
      delta,
      result: `(incremented by ${delta})`
    })
  } catch (error) {
    console.error(`❌ [FIRESTORE] Failed to update category product count:`, {
      categoryId,
      delta,
      error: error.message
    })
  }
}

const readProductsFromFirestore = async () => {
  const snapshot = await getDocs(collection(db, COLLECTION))
  return snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
}

const seedProductsInFirestore = async () => {
  const batch = writeBatch(db)
  mockProducts.forEach((item) => {
    batch.set(doc(db, COLLECTION, item.id), {
      ...item,
      createdAt: item.createdAt || new Date().toISOString(),
      updatedAt: serverTimestamp(),
    })
  })
  await batch.commit()
}

export const useProductsStore = create((set, get) => ({
  products: mockProducts,
  hasLoadedCloud: false,
  isLoadingCloud: false,
  cloudError: null,
  filters: { query: '', category: 'all', status: 'all' },
  selectedProduct: null,
  loadProducts: async () => {
    if (!isFirebaseConfigured) return
    set({ isLoadingCloud: true, cloudError: null })
    try {
      let items = await readProductsFromFirestore()
      if (!items.length) {
        await seedProductsInFirestore()
        items = await readProductsFromFirestore()
      }
      set({ products: items, hasLoadedCloud: true, isLoadingCloud: false })
    } catch (error) {
      set({ cloudError: error?.message || 'Failed to load products', isLoadingCloud: false })
    }
  },
  setFilters: (partial) => set((state) => ({ filters: { ...state.filters, ...partial } })),
  selectProduct: (id) => set((state) => ({ selectedProduct: state.products.find((p) => p.id === id) || null })),
  addProduct: async (product) => {
    const id = `PRD${Date.now()}`
    const { imageFile, ...productData } = product
    let imageUrl = productData.imageUrl || null

    if (imageFile) {
      imageUrl = await uploadProductImage(imageFile, id)
    }
    
    const categoryId = productData.category ?? ''
    
    const next = {
      ...productData,
      name: productData.name ?? '',
      sku: productData.sku ?? `SKU-${Date.now()}`,
      category: categoryId,
      id,
      imageUrl: imageUrl || productData.imageUrl || 'https://picsum.photos/seed/new-product/400/300',
      createdAt: product.createdAt || new Date().toISOString(),
    }
    const nextSafe = omitUndefined(next)
    set((state) => ({ products: [nextSafe, ...state.products] }))
    
    if (!isFirebaseConfigured) return
    
    // Save product and increment category count
    await setDoc(doc(db, COLLECTION, id), { ...nextSafe, updatedAt: serverTimestamp() })
    await updateCategoryProductCount(categoryId, 1)
  },
  updateProduct: async (id, updates) => {
    const { imageFile, _previousCategory, ...productUpdates } = updates
    let imageUrl = productUpdates.imageUrl
    if (imageFile) {
      imageUrl = await uploadProductImage(imageFile, id)
    }
    
    const newCategoryId = productUpdates.category ?? ''
    const oldCategoryId = _previousCategory ?? ''
    
    console.log('✏️ [UPDATE] Updating product:', {
      id,
      oldCategoryId,
      newCategoryId,
      categoryChanged: oldCategoryId !== newCategoryId,
      timestamp: new Date().toISOString()
    })
    
    const nextUpdates = omitUndefined({ ...productUpdates, imageUrl: imageUrl || productUpdates.imageUrl })
    set((state) => ({ products: state.products.map((item) => (item.id === id ? { ...item, ...nextUpdates } : item)) }))
    
    if (!isFirebaseConfigured) return
    
    // Update product
    await updateDoc(doc(db, COLLECTION, id), { ...nextUpdates, updatedAt: serverTimestamp() })
    
    // If category changed, update counts for both old and new categories
    if (oldCategoryId && oldCategoryId !== newCategoryId) {
      console.log('📊 [UPDATE] Category changed, updating counts:', { from: oldCategoryId, to: newCategoryId })
      await updateCategoryProductCount(oldCategoryId, -1)  // Decrement old
      await updateCategoryProductCount(newCategoryId, 1)   // Increment new
    } else if (!oldCategoryId && newCategoryId) {
      // Category was added (was previously empty)
      console.log('📊 [UPDATE] Category assigned, incrementing:', { categoryId: newCategoryId })
      await updateCategoryProductCount(newCategoryId, 1)
    } else if (oldCategoryId && !newCategoryId) {
      // Category was removed
      console.log('📊 [UPDATE] Category removed, decrementing:', { categoryId: oldCategoryId })
      await updateCategoryProductCount(oldCategoryId, -1)
    }
  },
  deleteProduct: async (id) => {
    console.log('[DELETE] Step 1: deleteProduct() called with id:', id)

    const product = get().products.find((p) => p.id === id)
    const categoryId = product?.category ?? ''

    console.log('[DELETE] Step 2: product found:', product ? `name="${product.name}" category="${categoryId}"` : 'NOT FOUND in store')

    // Optimistic removal from UI
    set((state) => ({ products: state.products.filter((item) => item.id !== id) }))
    console.log('[DELETE] Step 3: optimistic UI update applied')

    if (!isFirebaseConfigured) {
      console.warn('[DELETE] Step 4: Firebase NOT configured — Firestore delete skipped. Product will return on reload.')
      return
    }

    const path = `${COLLECTION}/${id}`
    console.log('[DELETE] Step 4: calling deleteDoc on path:', path)

    try {
      await deleteDoc(doc(db, COLLECTION, id))
      console.log('[DELETE] Step 5: deleteDoc SUCCESS for path:', path)
    } catch (err) {
      console.error('[DELETE] Step 5: deleteDoc FAILED:', err.code, err.message)
      throw err
    }

    if (categoryId) {
      console.log('[DELETE] Step 6: decrementing category count for:', categoryId)
      await updateCategoryProductCount(categoryId, -1)
    } else {
      console.log('[DELETE] Step 6: no category — skipping count update')
    }

    console.log('[DELETE] Step 7: deleteProduct() complete')
  },
  toggleStatus: async (id) => {
    let nextStatus = 'draft'
    set((state) => ({
      products: state.products.map((item) => {
        if (item.id !== id) return item
        nextStatus = item.status === 'active' ? 'draft' : 'active'
        console.log('🔄 [STATUS] Toggling product status:', { id, nextStatus })
        return { ...item, status: nextStatus }
      }),
    }))
    if (!isFirebaseConfigured) return
    await updateDoc(doc(db, COLLECTION, id), { status: nextStatus, updatedAt: serverTimestamp() })
  },
  setStatusBulk: async (ids, status) => {
    set((state) => ({
      products: state.products.map((item) => (ids.includes(item.id) ? { ...item, status } : item)),
    }))
    if (!isFirebaseConfigured) return
    const batch = writeBatch(db)
    ids.forEach((id) => {
      batch.update(doc(db, COLLECTION, id), { status, updatedAt: serverTimestamp() })
    })
    await batch.commit()
    console.log('🔄 [BULK] Updated status for products:', { count: ids.length, status })
  },
  deleteBulk: async (ids) => {
    const { products } = get()

    const categoryDeltas = {}
    ids.forEach(id => {
      const product = products.find(p => p.id === id)
      if (product?.category) {
        categoryDeltas[product.category] = (categoryDeltas[product.category] || 0) - 1
      }
    })
    
    console.log('🗑️ [BULK] Deleting products:', { ids, categoryDeltas })
    
    set((state) => ({ products: state.products.filter((item) => !ids.includes(item.id)) }))
    
    if (!isFirebaseConfigured) return
    
    // Delete all products
    const batch = writeBatch(db)
    ids.forEach((id) => {
      batch.delete(doc(db, COLLECTION, id))
    })
    await batch.commit()
    
    // Update category counts
    for (const [categoryId, delta] of Object.entries(categoryDeltas)) {
      if (delta < 0) {
        await updateCategoryProductCount(categoryId, delta)
      }
    }
  },
}))

