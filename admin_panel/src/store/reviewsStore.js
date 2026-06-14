import { create } from 'zustand'
import { mockReviews } from '../data/mockData'

export const useReviewsStore = create((set) => ({
  reviews: mockReviews,
  approve: (id) =>
    set((state) => ({ reviews: state.reviews.map((r) => (r.id === id ? { ...r, status: 'approved' } : r)) })),
  reject: (id) =>
    set((state) => ({ reviews: state.reviews.map((r) => (r.id === id ? { ...r, status: 'rejected' } : r)) })),
  flag: (id) =>
    set((state) => ({ reviews: state.reviews.map((r) => (r.id === id ? { ...r, status: 'flagged' } : r)) })),
  remove: (id) => set((state) => ({ reviews: state.reviews.filter((r) => r.id !== id) })),
}))
