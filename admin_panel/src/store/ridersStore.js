import { create } from 'zustand'
import {
  collection, onSnapshot, query, where,
  updateDoc, deleteDoc, doc, getDocs,
} from 'firebase/firestore'
import { db, isFirebaseConfigured, serverTimestamp } from '../services/firebase'

let _unsubscribeRiders = null

export const useRidersStore = create((set, get) => ({
  riders: [],
  hasLoaded: false,
  isLoading: false,
  error: null,

  loadRiders: () => {
    if (!isFirebaseConfigured) return
    if (_unsubscribeRiders) { _unsubscribeRiders(); _unsubscribeRiders = null }
    set({ isLoading: true, error: null })
    const q = query(collection(db, 'users'), where('role', '==', 'rider'))
    _unsubscribeRiders = onSnapshot(
      q,
      (snapshot) => {
        const riders = snapshot.docs.map((d) => ({ id: d.id, ...d.data() }))
        set({ riders, hasLoaded: true, isLoading: false })
      },
      (error) => {
        set({ error: error?.message || 'Failed to load riders', isLoading: false })
      },
    )
  },

  /** Returns only riders that are currently online */
  getOnlineRiders: () => get().riders.filter((r) => r.online === true),

  /** Enable or disable a rider account */
  setRiderStatus: async (riderId, status) => {
    set((state) => ({
      riders: state.riders.map((r) => r.id === riderId ? { ...r, status } : r),
    }))
    if (!isFirebaseConfigured) return
    await updateDoc(doc(db, 'users', riderId), { status, updatedAt: serverTimestamp() })
  },

  /** Update vehicle info */
  updateRider: async (riderId, data) => {
    set((state) => ({
      riders: state.riders.map((r) => r.id === riderId ? { ...r, ...data } : r),
    }))
    if (!isFirebaseConfigured) return
    await updateDoc(doc(db, 'users', riderId), { ...data, updatedAt: serverTimestamp() })
  },

  /** Delete a rider document (Auth account remains but login will be blocked by role check) */
  deleteRider: async (riderId) => {
    set((state) => ({ riders: state.riders.filter((r) => r.id !== riderId) }))
    if (!isFirebaseConfigured) return
    await deleteDoc(doc(db, 'users', riderId))
  },

  /** Count delivered orders for a given rider from the orders collection */
  fetchDeliveryCount: async (riderId) => {
    if (!isFirebaseConfigured) return 0
    const snap = await getDocs(
      query(collection(db, 'orders'),
        where('assignedRiderId', '==', riderId),
        where('status', '==', 'delivered'),
      )
    )
    return snap.size
  },
}))
