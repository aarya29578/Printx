import { create } from 'zustand'

export const useSettingsStore = create((set) => ({
  settings: {
    appName: 'PrintX',
    supportEmail: 'support@printx.in',
    supportPhone: '+91 98765 43210',
    businessAddress: 'Andheri West, Mumbai',
    defaultLanguage: 'en',
    currency: 'INR',
    maintenanceMode: false,
    maintenanceMessage: 'We are doing scheduled maintenance. Please check back soon.',
    branding: {
      primary: '#4F46E5',
      secondary: '#06B6D4',
      accent: '#F59E0B',
    },
    darkMode: false,
    payment: {
      razorpayKeyId: '',
      razorpaySecret: '',
      methods: {
        upi: true,
        cards: true,
        netBanking: true,
        emi: false,
        wallets: false,
        cod: true,
      },
    },
    invoice: {
      companyName: 'PrintX Pvt. Ltd.',
      gstin: '27ABCDE1234F1Z5',
      footerText: 'Thank you for choosing PrintX.',
    },
    delivery: {
      zones: [],
      pricing: [
        { id: 'std', type: 'Standard', basePrice: 0, freeAbove: 999, days: '4-6 days', status: 'active' },
        { id: 'exp', type: 'Express', basePrice: 99, freeAbove: 0, days: '1-2 days', status: 'active' },
        { id: 'same', type: 'Same Day', basePrice: 199, freeAbove: 0, days: 'Same day', status: 'active' },
      ],
      etaByCategory: [
        { id: 'eta1', category: 'Visiting Cards', minDays: 2, maxDays: 4 },
        { id: 'eta2', category: 'T-Shirts & Apparel', minDays: 3, maxDays: 6 },
      ],
      holidays: [],
    },
    pricingRules: {
      bulkEnabled: true,
      bulkThreshold: 5000,
      bulkDiscount: 10,
      gstDefault: 18,
      flashSales: [],
    },
  },
  updateSettings: (partial) =>
    set((state) => ({ settings: { ...state.settings, ...partial } })),
  updateNestedSettings: (section, partial) =>
    set((state) => ({
      settings: {
        ...state.settings,
        [section]: {
          ...state.settings[section],
          ...partial,
        },
      },
    })),
}))
