import { create } from 'zustand'
import { mockCoupons } from '../data/mockData'

export const useCouponsStore = create((set) => ({
  coupons: mockCoupons,
  addCoupon: (payload) => set((state) => ({ coupons: [payload, ...state.coupons] })),
  updateCoupon: (id, updates) =>
    set((state) => ({
      coupons: state.coupons.map((item) => (item.id === id ? { ...item, ...updates } : item)),
    })),
  toggle: (id) =>
    set((state) => ({
      coupons: state.coupons.map((item) =>
        item.id === id ? { ...item, status: item.status === 'active' ? 'paused' : 'active' } : item,
      ),
    })),
  deleteCoupon: (id) =>
    set((state) => ({ coupons: state.coupons.filter((item) => item.id !== id) })),
}))
