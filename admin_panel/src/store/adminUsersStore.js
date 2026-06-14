import { create } from 'zustand'
import { mockAdminUsers } from '../data/mockData'

export const useAdminUsersStore = create((set) => ({
  adminUsers: mockAdminUsers,
  addAdmin: (admin) => set((state) => ({ adminUsers: [admin, ...state.adminUsers] })),
  updateAdmin: (id, updates) =>
    set((state) => ({
      adminUsers: state.adminUsers.map((item) => (item.id === id ? { ...item, ...updates } : item)),
    })),
  deactivateAdmin: (id) =>
    set((state) => ({
      adminUsers: state.adminUsers.map((item) => (item.id === id ? { ...item, status: 'inactive' } : item)),
    })),
  deleteAdmin: (id) =>
    set((state) => ({ adminUsers: state.adminUsers.filter((item) => item.id !== id) })),
}))
