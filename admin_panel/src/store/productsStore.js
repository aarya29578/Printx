import { create } from 'zustand'
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  writeBatch,
  increment,
} from 'firebase/firestore'


import { db, isFirebaseConfigured, serverTimestamp } from '../services/firebase'

const COLLECTION = 'products'
const CATEGORIES_COLLECTION = 'categories'

const omitUndefined = (values) =>
  Object.fromEntries(Object.entries(values).filter(([, value]) => value !== undefined))

const PRODUCT_UPLOAD_URL =
  import.meta.env.VITE_BANNER_UPLOAD_URL ||
  'https://jenishaonlineservice.com/printx/api/upload-banner.php'

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
    const categoryRef = doc(db, CATEGORIES_COLLECTION, categoryId)

    await updateDoc(categoryRef, {
      productCount: increment(delta),
      updatedAt: serverTimestamp(),
    })
  } catch (error) {
    // keep behavior non-fatal
    console.error(`❌ [FIRESTORE] Failed to update category product count:`, {
      categoryId,
      delta,
      error: error?.message,
    })
  }
}

const readProductsFromFirestore = async () => {
  const snapshot = await getDocs(collection(db, COLLECTION))
  return snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
}

export const useProductsStore = create((set, get) => ({
  products: [],
  hasLoadedCloud: false,
  isLoadingCloud: false,
  cloudError: null,

  filters: { query: '', category: 'all', status: 'all' },
  selectedProduct: null,

  loadProducts: async () => {
    if (!isFirebaseConfigured) return

    set({ isLoadingCloud: true, cloudError: null })

    try {
      const items = await readProductsFromFirestore()
      console.log('📦 [PRODUCT FETCH] count=', items.length)
      console.log('🧱 [PRODUCT FETCH] collection=', COLLECTION)
      console.log(
        '🗂️ [PRODUCT FETCH] documentIds=',
        items.map((p) => p.id),
      )

      // Required: log raw firestore docs
      // (We log again by doc.id/doc.data() here by re-reading from items)
      // Note: items come from map({id,...data}); keep log format required.
      items.forEach((p) => {
        // eslint-disable-next-line no-console
        console.log('📦 [FIRESTORE PRODUCT RAW]', {
          id: p.id,
          category: p.category,
          status: p.status,
          payload: p,
        })
      })

      set({
        products: items,
        hasLoadedCloud: true,
        isLoadingCloud: false,
      })
    } catch (error) {
      set({
        cloudError: error?.message || 'Failed to load products',
        isLoadingCloud: false,
      })
    }
  },

  setFilters: (partial) =>
    set((state) => ({ filters: { ...state.filters, ...partial } })),

  selectProduct: (id) =>
    set((state) => ({
      selectedProduct: state.products.find((p) => p.id === id) || null,
    })),

  addProduct: async (product) => {
    const id = `PRD${Date.now()}`
    const { imageFile, ...productData } = product

    let imageUrl = productData.imageUrl || null

    console.log('🧾 [PRODUCT CREATE] collection=', COLLECTION)
    console.log('🧾 [PRODUCT CREATE] generatedDocumentId=', id)
    console.log('🧾 [PRODUCT CREATE] payload(before image upload)=', {
      id,
      ...productData,
    })

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
      imageUrl: imageUrl || productData.imageUrl || null,
      createdAt: product?.createdAt || new Date().toISOString(),
    }

    const nextSafe = omitUndefined(next)

    // optimistic UI
    set((state) => ({ products: [nextSafe, ...state.products] }))

    if (!isFirebaseConfigured) return

    const finalSavedPayload = {
      ...nextSafe,
      updatedAt: serverTimestamp(),
    }

    console.log('🧾 [PRODUCT CREATE] finalSavedPayload=', {
      collection: COLLECTION,
      id,
      payload: finalSavedPayload,
    })

    const productRef = doc(db, COLLECTION, id)
    await setDoc(productRef, finalSavedPayload)

    // Verification: immediately read back
    const verifySnap = await getDoc(productRef)
    console.log('🔎 [PRODUCT CREATE VERIFY] collection=', COLLECTION)
    console.log('🔎 [PRODUCT CREATE VERIFY] documentId=', id)
    console.log('🔎 [PRODUCT CREATE VERIFY] exists=', verifySnap.exists())
    console.log(
      '🔎 [PRODUCT CREATE VERIFY] returnedData=',
      verifySnap.exists() ? verifySnap.data() : null,
    )

    await updateCategoryProductCount(categoryId, 1)
  },

  updateProduct: async (id, updates) => {
    console.log('✏️ [PRODUCT UPDATE] collection=', COLLECTION)
    console.log('✏️ [PRODUCT UPDATE] documentId=', id)
    console.log('✏️ [PRODUCT UPDATE] payload=', { id, ...updates })

    const { imageFile, _previousCategory, ...productUpdates } = updates

    let imageUrl = productUpdates.imageUrl
    if (imageFile) {
      imageUrl = await uploadProductImage(imageFile, id)
    }

    const newCategoryId = productUpdates.category ?? ''
    const oldCategoryId = _previousCategory ?? ''

    const nextUpdates = omitUndefined({
      ...productUpdates,
      imageUrl: imageUrl || productUpdates.imageUrl,
    })

    // optimistic UI
    set((state) => ({
      products: state.products.map((item) =>
        item.id === id ? { ...item, ...nextUpdates } : item
      ),
    }))

    if (!isFirebaseConfigured) return

    const finalUpdatePayload = {
      ...nextUpdates,
      updatedAt: serverTimestamp(),
    }

    console.log('✏️ [PRODUCT UPDATE] finalUpdatePayload=', {
      collection: COLLECTION,
      id,
      payload: finalUpdatePayload,
    })

    const productRef = doc(db, COLLECTION, id)
    await updateDoc(productRef, finalUpdatePayload)

    // Verification: immediately read back
    const verifySnap = await getDoc(productRef)
    console.log('🔎 [PRODUCT UPDATE VERIFY] collection=', COLLECTION)
    console.log('🔎 [PRODUCT UPDATE VERIFY] documentId=', id)
    console.log('🔎 [PRODUCT UPDATE VERIFY] exists=', verifySnap.exists())
    console.log(
      '🔎 [PRODUCT UPDATE VERIFY] returnedData=',
      verifySnap.exists() ? verifySnap.data() : null,
    )

    if (oldCategoryId && oldCategoryId !== newCategoryId) {
      await updateCategoryProductCount(oldCategoryId, -1)
      await updateCategoryProductCount(newCategoryId, 1)
    } else if (!oldCategoryId && newCategoryId) {
      await updateCategoryProductCount(newCategoryId, 1)
    } else if (oldCategoryId && !newCategoryId) {
      await updateCategoryProductCount(oldCategoryId, -1)
    }
  },

  deleteProduct: async (id) => {
    console.log('🗑️ [PRODUCT DELETE] collection=', COLLECTION)
    console.log('🗑️ [PRODUCT DELETE] documentId=', id)

    const state = get()
    const product = state.products.find((p) => p.id === id)
    const categoryId = product?.category ?? ''

    // Optimistic UI first
    set((state2) => ({
      products: state2.products.filter((item) => item.id !== id),
    }))

    if (!isFirebaseConfigured) return

    try {
      const productRef = doc(db, COLLECTION, id)
      await deleteDoc(productRef)

      // Verification: ensure doc no longer exists
      const verifySnap = await getDoc(productRef)
      console.log('🔎 [PRODUCT DELETE VERIFY] collection=', COLLECTION)
      console.log('🔎 [PRODUCT DELETE VERIFY] documentId=', id)
      console.log('🔎 [PRODUCT DELETE VERIFY] exists=', verifySnap.exists())

      if (categoryId) {
        await updateCategoryProductCount(categoryId, -1)
      }
    } catch (error) {
      console.error('❌ [PRODUCT DELETE] failed:', error)
      toast?.error?.('Failed to delete product')

      // Revert optimistic deletion (best-effort)
      set((state2) => ({
        products: product ? [product, ...state2.products.filter((item) => item.id !== id)] : state2.products,
      }))

      throw error
    }
  },

  toggleStatus: async (id) => {
    let nextStatus = 'draft'

    set((state) => ({
      products: state.products.map((item) => {
        if (item.id !== id) return item
        nextStatus = item.status === 'active' ? 'draft' : 'active'
        return { ...item, status: nextStatus }
      }),
    }))

    if (!isFirebaseConfigured) return

    await updateDoc(doc(db, COLLECTION, id), {
      status: nextStatus,
      updatedAt: serverTimestamp(),
    })
  },

  setStatusBulk: async (ids, status) => {
    set((state) => ({
      products: state.products.map((item) =>
        ids.includes(item.id) ? { ...item, status } : item
      ),
    }))

    if (!isFirebaseConfigured) return

    const batch = writeBatch(db)
    ids.forEach((id) => {
      batch.update(doc(db, COLLECTION, id), {
        status,
        updatedAt: serverTimestamp(),
      })
    })

    await batch.commit()
  },

  deleteBulk: async (ids) => {
    const state = get()

    const categoryDeltas = {}
    ids.forEach((id) => {
      const product = state.products.find((p) => p.id === id)
      if (product?.category) {
        categoryDeltas[product.category] =
          (categoryDeltas[product.category] || 0) - 1
      }
    })

    set((state2) => ({
      products: state2.products.filter((item) => !ids.includes(item.id)),
    }))

    if (!isFirebaseConfigured) return

    const batch = writeBatch(db)
    ids.forEach((id) => {
      batch.delete(doc(db, COLLECTION, id))
    })
    await batch.commit()

    for (const [categoryId, delta] of Object.entries(categoryDeltas)) {
      if (delta < 0) {
        await updateCategoryProductCount(categoryId, delta)
      }
    }
  },

  clearAllProducts: async () => {
    if (!isFirebaseConfigured) return

    const state = get()
    const allProductIds = state.products.map((p) => p.id)

    if (allProductIds.length === 0) {
      console.log('✅ [PRODUCT CLEAR] No products to delete')
      return
    }

    console.log('🗑️ [PRODUCT CLEAR ALL] Deleting', allProductIds.length, 'products')

    // Clear from UI immediately
    set({ products: [] })

    // Delete from Firestore in batches (500 per batch is Firestore limit)
    const batchSize = 500
    for (let i = 0; i < allProductIds.length; i += batchSize) {
      const batch = writeBatch(db)
      const batchIds = allProductIds.slice(i, i + batchSize)

      batchIds.forEach((id) => {
        batch.delete(doc(db, COLLECTION, id))
      })

      await batch.commit()
      console.log(`✅ [PRODUCT CLEAR] Deleted batch ${Math.floor(i / batchSize) + 1}`)
    }

    // Reset all category product counts
    const categoryDeltas = {}
    state.products.forEach((product) => {
      if (product?.category) {
        categoryDeltas[product.category] = (categoryDeltas[product.category] || 0) - 1
      }
    })

    for (const [categoryId, delta] of Object.entries(categoryDeltas)) {
      await updateCategoryProductCount(categoryId, delta)
    }

    console.log('✅ [PRODUCT CLEAR ALL] Complete - all products deleted')
  },
}))


