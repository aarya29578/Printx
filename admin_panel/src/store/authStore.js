import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { mockAdminUsers } from '../data/mockData'

export const useAuthStore = create(
  persist(
    (set) => ({
      admin: mockAdminUsers[0],
      isAuthenticated: true,
      login: () => {
        set({ admin: mockAdminUsers[0], isAuthenticated: true })
        return true
      },
      logout: () => set({ admin: null, isAuthenticated: false }),
    }),
    { name: 'printx-admin-auth' },
  ),
)
