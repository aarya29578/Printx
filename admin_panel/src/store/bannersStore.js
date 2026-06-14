import { create } from 'zustand'
import { collection, deleteDoc, doc, getDocs, setDoc, updateDoc, writeBatch } from 'firebase/firestore'
import { mockBanners } from '../data/mockData'
import { db, isFirebaseConfigured, serverTimestamp } from '../services/firebase'

const COLLECTION = 'banners'
const BANNER_UPLOAD_URL = import.meta.env.VITE_BANNER_UPLOAD_URL || 'https://jenishaonlineservice.com/printx/api/upload-banner.php'

const sortBanners = (items) => [...items].sort((a, b) => (a.position || 0) - (b.position || 0))

const normalizeBanner = (item, index = 0) => ({
  ...item,
  position: Number(item.position || index + 1),
  status: item.status || 'active',
})

const readBannersFromFirestore = async () => {
  const snapshot = await getDocs(collection(db, COLLECTION))
  return snapshot.docs.map((item) => normalizeBanner({ id: item.id, ...item.data() }))
}

const seedBannersInFirestore = async () => {
  const batch = writeBatch(db)
  mockBanners.forEach((item, index) => {
    batch.set(doc(db, COLLECTION, item.id), {
      ...item,
      position: item.position || index + 1,
      status: item.status || 'active',
      createdAt: item.createdAt || new Date().toISOString(),
      updatedAt: serverTimestamp(),
    })
  })
  await batch.commit()
}

const uploadBannerImage = async (file, bannerId) => {
  if (!file) return null
  const formData = new FormData()
  formData.append('bannerId', bannerId)
  formData.append('image', file)

  const response = await fetch(BANNER_UPLOAD_URL, {
    method: 'POST',
    body: formData,
  })

  const data = await response.json().catch(() => null)
  if (!response.ok) {
    throw new Error(data?.error || 'Failed to upload banner image')
  }
  if (!data?.url) {
    throw new Error('Upload endpoint did not return an image URL')
  }
  return data.url
}

const nextPosition = (items) => Math.max(0, ...items.map((item) => item.position || 0)) + 1

export const useBannersStore = create((set, get) => ({
  banners: sortBanners(mockBanners),
  hasLoadedCloud: false,
  isLoadingCloud: false,
  cloudError: null,
  loadBanners: async () => {
    if (!isFirebaseConfigured) return
    set({ isLoadingCloud: true, cloudError: null })
    try {
      let items = await readBannersFromFirestore()
      if (!items.length) {
        await seedBannersInFirestore()
        items = await readBannersFromFirestore()
      }
      set({ banners: sortBanners(items), hasLoadedCloud: true, isLoadingCloud: false })
    } catch (error) {
      set({ cloudError: error?.message || 'Failed to load banners', isLoadingCloud: false })
    }
  },
  reorderBanners: async (newOrder) => {
    const ordered = newOrder.map((item, index) => ({ ...item, position: index + 1 }))
    set({ banners: ordered })
    if (!isFirebaseConfigured) return
    const batch = writeBatch(db)
    ordered.forEach((item) => {
      batch.update(doc(db, COLLECTION, item.id), { position: item.position, updatedAt: serverTimestamp() })
    })
    await batch.commit()
  },
  addBanner: async (payload) => {
    const state = get()
    const id = `BAN${Date.now()}`
    const position = payload.position || nextPosition(state.banners)
    const { imageFile, ...bannerData } = payload
    let imageUrl = bannerData.imageUrl || null

    if (imageFile) {
      imageUrl = await uploadBannerImage(imageFile, id)
    }

    const next = {
      ...bannerData,
      id,
      imageUrl,
      position,
      status: payload.status || 'active',
      createdAt: new Date().toISOString(),
    }

    set((current) => ({ banners: sortBanners([next, ...current.banners]) }))
    if (!isFirebaseConfigured) return next
    await setDoc(doc(db, COLLECTION, id), { ...next, updatedAt: serverTimestamp() })
    return next
  },
  updateBanner: async (id, updates) => {
    const current = get().banners.find((item) => item.id === id)
    const { imageFile, ...bannerUpdates } = updates
    let imageUrl = bannerUpdates.imageUrl ?? current?.imageUrl ?? null

    if (imageFile) {
      imageUrl = await uploadBannerImage(imageFile, id)
    }

    const nextUpdates = {
      ...bannerUpdates,
      imageUrl,
    }

    set((state) => ({
      banners: sortBanners(
        state.banners.map((item) => (item.id === id ? { ...item, ...nextUpdates } : item)),
      ),
    }))
    if (!isFirebaseConfigured) return
    await updateDoc(doc(db, COLLECTION, id), { ...nextUpdates, updatedAt: serverTimestamp() })
  },
  deleteBanner: async (id) => {
    set((state) => ({ banners: state.banners.filter((item) => item.id !== id) }))
    if (!isFirebaseConfigured) return
    await deleteDoc(doc(db, COLLECTION, id))
  },
}))
