import { create } from 'zustand'
import { collection, doc, getDocs, updateDoc } from 'firebase/firestore'
import { db, isFirebaseConfigured, serverTimestamp } from '../services/firebase'

const COLLECTION = 'orders'

const readOrdersFromFirestore = async () => {
  console.log('ORDERS FETCH START (readOrdersFromFirestore)')
  console.log('ORDERS COLLECTION PATH', `collection(db, ${COLLECTION})`)
  const snapshot = await getDocs(collection(db, COLLECTION))
  const items = snapshot.docs.map((item) => ({ id: item.id, ...item.data() }))
  console.log('ORDERS COUNT', items.length)
  console.log('ORDER IDS', items.map((i) => i.id))
  console.log('ORDER RAW DATA', items)
  return items
}



export const useOrdersStore = create((set) => ({
  orders: [],

  hasLoadedCloud: false,
  isLoadingCloud: false,
  cloudError: null,
  filters: { query: '', status: 'all', payment: 'all' },
  loadOrders: async () => {
    console.log('ORDERS FETCH START')
    if (!isFirebaseConfigured) {
      console.log('ORDERS FETCH ABORT: firebase not configured')
      return
    }

    console.log('ORDERS COLLECTION PATH', `collection(db, ${COLLECTION})`)
    set({ isLoadingCloud: true, cloudError: null })

    try {
      let items = await readOrdersFromFirestore()
      console.log('ORDERS COUNT', items.length)
      console.log('ORDER IDS', items.map((i) => i.id))
      console.log('ORDER RAW DATA', items)

      set({ orders: items, hasLoadedCloud: true, isLoadingCloud: false })
    } catch (error) {
      console.log('ORDERS FETCH ERROR', error)
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
