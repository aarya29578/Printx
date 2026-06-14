import { create } from 'zustand'
import { collection, doc, getDocs, updateDoc, writeBatch } from 'firebase/firestore'
import { mockOrders } from '../data/mockData'
import { db, isFirebaseConfigured, serverTimestamp } from '../services/firebase'

const COLLECTION = 'orders'

const readOrdersFromFirestore = async () => {
  const snapshot = await getDocs(collection(db, COLLECTION))
  return snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
}

const seedOrdersInFirestore = async () => {
  const batch = writeBatch(db)
  mockOrders.forEach((item) => {
    batch.set(doc(db, COLLECTION, item.id), {
      ...item,
      updatedAt: serverTimestamp(),
    })
  })
  await batch.commit()
}

export const useOrdersStore = create((set) => ({
  orders: mockOrders,
  hasLoadedCloud: false,
  isLoadingCloud: false,
  cloudError: null,
  filters: { query: '', status: 'all', payment: 'all' },
  loadOrders: async () => {
    if (!isFirebaseConfigured) return
    set({ isLoadingCloud: true, cloudError: null })
    try {
      let items = await readOrdersFromFirestore()
      if (!items.length) {
        await seedOrdersInFirestore()
        items = await readOrdersFromFirestore()
      }
      set({ orders: items, hasLoadedCloud: true, isLoadingCloud: false })
    } catch (error) {
      set({ cloudError: error?.message || 'Failed to load orders', isLoadingCloud: false })
    }
  },
  setFilters: (partial) => set((state) => ({ filters: { ...state.filters, ...partial } })),
  updateStatus: async (id, status) => {
    let updatedOrder = null
    set((state) => ({
      orders: state.orders.map((order) => {
        if (order.id !== id) return order
        updatedOrder = {
          ...order,
          status,
          timeline: order.timeline.map((step) => {
            const target = step.step.toLowerCase()
            if (status === 'printing' && target === 'printing') return { ...step, done: true, time: step.time || new Date().toISOString() }
            if (status === 'shipped' && target === 'dispatched') return { ...step, done: true, time: step.time || new Date().toISOString() }
            if (status === 'delivered' && target === 'delivered') return { ...step, done: true, time: step.time || new Date().toISOString() }
            if (status === 'cancelled' && target === 'delivered') return { ...step, done: false, time: null }
            return step
          }),
        }
        return updatedOrder
      }),
    }))
    if (!isFirebaseConfigured || !updatedOrder) return
    await updateDoc(doc(db, COLLECTION, id), {
      status: updatedOrder.status,
      timeline: updatedOrder.timeline,
      updatedAt: serverTimestamp(),
    })
  },
  addAdminNote: async (id, note, adminName = 'Admin') => {
    let updatedNotes = []
    set((state) => ({
      orders: state.orders.map((order) => {
        if (order.id !== id) return order
        updatedNotes = [{ text: note, by: adminName, createdAt: new Date().toISOString() }, ...(order.adminNotes || [])]
        return { ...order, adminNotes: updatedNotes }
      }),
    }))
    if (!isFirebaseConfigured) return
    await updateDoc(doc(db, COLLECTION, id), { adminNotes: updatedNotes, updatedAt: serverTimestamp() })
  },
  markTimelineStepComplete: async (orderId, stepName, payload) => {
    let updatedTimeline = []
    set((state) => ({
      orders: state.orders.map((order) => {
        if (order.id !== orderId) return order
        updatedTimeline = order.timeline.map((step) =>
          step.step === stepName
            ? { ...step, done: true, time: payload.time || new Date().toISOString(), note: payload.note || '' }
            : step,
        )
        return { ...order, timeline: updatedTimeline }
      }),
    }))
    if (!isFirebaseConfigured) return
    await updateDoc(doc(db, COLLECTION, orderId), { timeline: updatedTimeline, updatedAt: serverTimestamp() })
  },
  updateTrackingNumber: async (orderId, trackingNumber) => {
    set((state) => ({
      orders: state.orders.map((order) => (order.id === orderId ? { ...order, trackingNumber } : order)),
    }))
    if (!isFirebaseConfigured) return
    await updateDoc(doc(db, COLLECTION, orderId), { trackingNumber, updatedAt: serverTimestamp() })
  },
}))
