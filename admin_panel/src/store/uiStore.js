import { create } from 'zustand'

export const useUiStore = create((set) => ({
  searchOpen: false,
  setSearchOpen: (value) => set({ searchOpen: value }),
}))
