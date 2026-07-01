import { create } from 'zustand'
import {
  readCustomersFromFirestore,
  getCustomerOrders,
  updateCustomerStatus,
  deleteCustomerFromFirestore,
  subscribeToCustomerUpdates,
} from '../services/customersService'
import { isFirebaseConfigured } from '../services/firebase'

export const useCustomersStore = create((set) => ({
  customers: [],
  hasLoadedCloud: false,
  isLoadingCloud: false,
  cloudError: null,

  loadCustomers: async () => {
    set({ isLoadingCloud: true, cloudError: null })
    try {
      const items = await readCustomersFromFirestore()
      set({ customers: items, hasLoadedCloud: true, isLoadingCloud: false })
    } catch (error) {
      console.error('Failed to load customers:', error)
      set({ cloudError: error?.message || 'Failed to load customers', isLoadingCloud: false })
    }
  },

  subscribeToUpdates: () => {
    if (!isFirebaseConfigured) return () => {}

    return subscribeToCustomerUpdates((customers) => {
      set({ customers })
    })
  },

  getCustomerOrders: (userId) => getCustomerOrders(userId),

  toggleStatus: async (id) => {
    const customer = null
    set((state) => {
      const cust = state.customers.find((item) => item.id === id)
      if (cust) {
        const newStatus = cust.status === 'active' ? 'blocked' : 'active'
        updateCustomerStatus(id, newStatus)
        return {
          customers: state.customers.map((item) =>
            item.id === id ? { ...item, status: newStatus } : item,
          ),
        }
      }
      return state
    })
  },

  deleteCustomer: async (id) => {
    const success = await deleteCustomerFromFirestore(id)
    if (success) {
      set((state) => ({ customers: state.customers.filter((item) => item.id !== id) }))
    }
    return success
  },
}))
