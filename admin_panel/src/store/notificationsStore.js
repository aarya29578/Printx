import { create } from 'zustand'
import { mockNotifications } from '../data/mockData'

export const useNotificationsStore = create((set) => ({
  notifications: mockNotifications.map((item) => ({ ...item, read: false })),
  sendNotification: (data) =>
    set((state) => ({
      notifications: [
        {
          id: `NOT${Date.now()}`,
          sentAt: new Date().toISOString(),
          delivered: data.delivered ?? 0,
          opened: data.opened ?? 0,
          sentTo: data.sentTo ?? 0,
          read: false,
          ...data,
        },
        ...state.notifications,
      ],
    })),
  markAllRead: () =>
    set((state) => ({
      notifications: state.notifications.map((item) => ({ ...item, read: true })),
    })),
}))
