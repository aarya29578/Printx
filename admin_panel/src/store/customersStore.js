import { create } from 'zustand'
import { mockCustomers, mockOrders } from '../data/mockData'

export const useCustomersStore = create((set) => ({
  customers: mockCustomers,
  getCustomerOrders: (customerName) =>
    mockOrders.filter((order) => order.customer.name === customerName),
  toggleStatus: (id) =>
    set((state) => ({
      customers: state.customers.map((item) =>
        item.id === id
          ? { ...item, status: item.status === 'active' ? 'blocked' : 'active' }
          : item,
      ),
    })),
  deleteCustomer: (id) =>
    set((state) => ({ customers: state.customers.filter((item) => item.id !== id) })),
}))
