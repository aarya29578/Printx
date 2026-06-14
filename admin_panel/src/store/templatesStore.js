import { create } from 'zustand'
import { mockTemplates } from '../data/mockData'

export const useTemplatesStore = create((set) => ({
  templates: mockTemplates,
  addTemplate: (payload) => set((state) => ({ templates: [payload, ...state.templates] })),
  updateTemplate: (id, updates) =>
    set((state) => ({ templates: state.templates.map((item) => (item.id === id ? { ...item, ...updates } : item)) })),
  deleteTemplate: (id) => set((state) => ({ templates: state.templates.filter((item) => item.id !== id) })),
}))
