import { create } from 'zustand'
import { collection, deleteDoc, doc, getDocs, getDoc, setDoc, updateDoc, writeBatch } from 'firebase/firestore'
import { mockCategories } from '../data/mockData'
import { db, isFirebaseConfigured, serverTimestamp } from '../services/firebase'

const COLLECTION = 'categories'

const readCategoriesFromFirestore = async () => {
  const snapshot = await getDocs(collection(db, COLLECTION))
  return snapshot.docs.map((item) => {
    const data = item.data()
    // Ensure all required fields have defaults
    const category = {
      id: item.id,
      name: data.name || item.id,
      icon: data.icon || 'tag',
      productCount: data.productCount ?? 0,
      color: data.color || '#4F46E5',
      status: data.status || 'active',
      order: data.order ?? 0,
      imageUrl: data.imageUrl || '',
      description: data.description || '',
      ...data
    }
    return category
  })
}

const seedCategoriesInFirestore = async () => {
  const batch = writeBatch(db)
  mockCategories.forEach((item) => {
    batch.set(doc(db, COLLECTION, item.id), { ...item, updatedAt: serverTimestamp() })
  })
  await batch.commit()
}

export const useCategoriesStore = create((set) => ({
  categories: mockCategories,
  hasLoadedCloud: false,
  isLoadingCloud: false,
  cloudError: null,
  loadCategories: async () => {
    if (!isFirebaseConfigured) return
    set({ isLoadingCloud: true, cloudError: null })
    try {
      let items = await readCategoriesFromFirestore()
      if (!items.length) {
        await seedCategoriesInFirestore()
        items = await readCategoriesFromFirestore()
      }
      const sorted = [...items].sort((a, b) => (b.order || 0) - (a.order || 0))
      set({ categories: sorted, hasLoadedCloud: true, isLoadingCloud: false })
    } catch (error) {
      set({ cloudError: error?.message || 'Failed to load categories', isLoadingCloud: false })
    }
  },
  reorderCategories: async (newOrder) => {
    const total = newOrder.length
    const ordered = newOrder.map((item, index) => ({ ...item, order: total - index }))
    set({ categories: ordered })
    if (!isFirebaseConfigured) return
    const batch = writeBatch(db)
    ordered.forEach((item) => {
      batch.update(doc(db, COLLECTION, item.id), { order: item.order, updatedAt: serverTimestamp() })
    })
    await batch.commit()
  },
  addCategory: async (payload) => {
    let nextOrder = payload.order || 1
    set((state) => {
      nextOrder = payload.order || Math.max(0, ...state.categories.map((item) => item.order || 0)) + 1
      return { categories: [{ ...payload, order: nextOrder }, ...state.categories] }
    })
    if (!isFirebaseConfigured) return
    await setDoc(doc(db, COLLECTION, payload.id), {
      ...payload,
      order: nextOrder,
      updatedAt: serverTimestamp(),
    })
  },
  updateCategory: async (id, updates) => {
    set((state) => ({
      categories: state.categories.map((item) => (item.id === id ? { ...item, ...updates } : item)),
    }))
    if (!isFirebaseConfigured) return
    await updateDoc(doc(db, COLLECTION, id), { ...updates, updatedAt: serverTimestamp() })
  },
  deleteCategory: async (id) => {
    set((state) => ({ categories: state.categories.filter((item) => item.id !== id) }))
    if (!isFirebaseConfigured) return
    await deleteDoc(doc(db, COLLECTION, id))
  },
  // Refresh a single category from Firestore (called after product operations)
  refreshCategory: async (categoryId) => {
    if (!isFirebaseConfigured || !categoryId) return
    try {
      const docSnap = await getDoc(doc(db, COLLECTION, categoryId))
      if (docSnap.exists()) {
        const data = docSnap.data()
        const category = {
          id: docSnap.id,
          name: data.name || docSnap.id,
          icon: data.icon || 'tag',
          productCount: data.productCount ?? 0,
          color: data.color || '#4F46E5',
          status: data.status || 'active',
          order: data.order ?? 0,
          imageUrl: data.imageUrl || '',
          description: data.description || '',
          ...data,
        }
        set((state) => ({
          categories: state.categories.map((item) =>
            item.id === categoryId ? category : item
          ),
        }))
      }
    } catch (error) {
      console.error('Failed to refresh category:', error)
    }
  },
}))
