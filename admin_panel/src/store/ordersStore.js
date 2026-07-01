import { create } from 'zustand'
import { collection, onSnapshot, updateDoc, doc } from 'firebase/firestore'
import { db, isFirebaseConfigured, serverTimestamp } from '../services/firebase'
import { normalizeOrderDate } from '../core/utils/formatOrderDate'

const COLLECTION = 'orders'

// module-level ref so re-calling loadOrders() cancels the previous listener
let _unsubscribeOrders = null

const sortNewestFirst = (items) =>
  [...items].sort((a, b) => {
    const dateA = normalizeOrderDate(a.createdAt) ?? new Date(0)
    const dateB = normalizeOrderDate(b.createdAt) ?? new Date(0)
    return dateB - dateA
  })

export const useOrdersStore = create((set) => ({
  orders: [],
  hasLoadedCloud: false,
  isLoadingCloud: false,
  cloudError: null,
  filters: { query: '', status: 'all', payment: 'all' },
  loadOrders: () => {
    if (!isFirebaseConfigured) return
    if (_unsubscribeOrders) { _unsubscribeOrders(); _unsubscribeOrders = null }
    set({ isLoadingCloud: true, cloudError: null })
    _unsubscribeOrders = onSnapshot(
      collection(db, COLLECTION),
      (snapshot) => {
        const raw = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }))
        set({ orders: sortNewestFirst(raw), hasLoadedCloud: true, isLoadingCloud: false })
      },
      (error) => {
        set({ cloudError: error?.message || 'Failed to load orders', isLoadingCloud: false })
      },
    )
  },
  setFilters: (partial) => set((state) => ({ filters: { ...state.filters, ...partial } })),
  updateStatus: async (id, status) => {
    let updatedOrder = null
    set((state) => ({
      orders: state.orders.map((order) => {
        if (order.id !== id) return order
        const existingTimeline = Array.isArray(order.timeline) ? order.timeline : []
        updatedOrder = {
          ...order,
          status,
          timeline: existingTimeline.map((step) => {
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
    const firestoreUpdate = { status: updatedOrder.status, updatedAt: serverTimestamp() }
    if (updatedOrder.timeline.length > 0) firestoreUpdate.timeline = updatedOrder.timeline
    await updateDoc(doc(db, COLLECTION, id), firestoreUpdate)
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
