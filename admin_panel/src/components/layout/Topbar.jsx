import { useEffect, useMemo, useRef, useState } from 'react'
import { Bell, Menu, Moon, Search, Sun } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { formatDistanceToNow } from 'date-fns'
import Breadcrumb from './Breadcrumb'
import Modal from '../ui/Modal'
import { useAuthStore } from '../../store/authStore'
import { useNotificationsStore } from '../../store/notificationsStore'
import { useSettingsStore } from '../../store/settingsStore'
import { useUiStore } from '../../store/uiStore'
import { useProductsStore } from '../../store/productsStore'
import { useOrdersStore } from '../../store/ordersStore'
import { useCustomersStore } from '../../store/customersStore'

export default function Topbar({ onMenuClick }) {
  const navigate = useNavigate()
  const admin = useAuthStore((state) => state.admin)
  const logout = useAuthStore((state) => state.logout)
  const notifications = useNotificationsStore((state) => state.notifications)
  const markAllRead = useNotificationsStore((state) => state.markAllRead)
  const settings = useSettingsStore((state) => state.settings)
  const updateSettings = useSettingsStore((state) => state.updateSettings)
  const searchOpen = useUiStore((state) => state.searchOpen)
  const setSearchOpen = useUiStore((state) => state.setSearchOpen)
  const products = useProductsStore((state) => state.products)
  const orders = useOrdersStore((state) => state.orders)
  const customers = useCustomersStore((state) => state.customers)

  const [showNotifications, setShowNotifications] = useState(false)
  const [showProfile, setShowProfile] = useState(false)
  const [query, setQuery] = useState('')
  const [activeIndex, setActiveIndex] = useState(0)
  const inputRef = useRef(null)

  useEffect(() => {
    document.documentElement.classList.toggle('dark', settings.darkMode)
    localStorage.setItem('printx-theme', settings.darkMode ? 'dark' : 'light')
  }, [settings.darkMode])

  useEffect(() => {
    if (searchOpen) {
      setTimeout(() => inputRef.current?.focus(), 10)
    }
  }, [searchOpen])

  const unreadCount = notifications.filter((n) => !n.read).length
  const recentNotifications = notifications.slice(0, 5)

  const results = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return []

    const productResults = products
      .filter((p) => p.name.toLowerCase().includes(q))
      .slice(0, 5)
      .map((p) => ({ id: p.id, group: 'Products', label: p.name, path: `/products/${p.id}/edit` }))

    const orderResults = orders
      .filter((o) => o.id.toLowerCase().includes(q))
      .slice(0, 5)
      .map((o) => ({ id: o.id, group: 'Orders', label: o.id, path: `/orders/${o.id}` }))

    const customerResults = customers
      .filter((c) => c.name.toLowerCase().includes(q))
      .slice(0, 5)
      .map((c) => ({ id: c.id, group: 'Customers', label: c.name, path: `/customers/${c.id}` }))

    return [...productResults, ...orderResults, ...customerResults]
  }, [query, products, orders, customers])

  const grouped = useMemo(() => {
    return ['Products', 'Orders', 'Customers'].map((group) => ({
      group,
      items: results.filter((item) => item.group === group),
    })).filter((group) => group.items.length)
  }, [results])

  const flatResults = results

  const handleSelect = (item) => {
    setSearchOpen(false)
    setQuery('')
    setActiveIndex(0)
    navigate(item.path)
  }

  return (
    <>
      <header className="relative z-20 flex h-16 items-center gap-4 border-b border-gray-200 bg-white px-6 dark:border-gray-700 dark:bg-gray-800">
        <button type="button" onClick={onMenuClick} className="rounded-lg p-2 hover:bg-gray-100 dark:hover:bg-gray-700" title="Toggle menu">
          <Menu className="h-5 w-5" />
        </button>
        <Breadcrumb />

        <div className="ml-auto flex items-center gap-3">
          <button
            type="button"
            onClick={() => updateSettings({ darkMode: !settings.darkMode })}
            className="rounded-full p-2 hover:bg-gray-100 dark:hover:bg-gray-700"
            title="Toggle dark mode"
          >
            {settings.darkMode ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
          </button>

          <button
            type="button"
            onClick={() => setSearchOpen(true)}
            className="hidden items-center gap-2 rounded-full bg-gray-100 px-3 py-2 text-sm text-gray-500 md:flex dark:bg-gray-700 dark:text-gray-300"
          >
            <Search className="h-4 w-4" />
            Search... (Ctrl+K)
          </button>

          <div className="relative">
            <button type="button" onClick={() => setShowNotifications((v) => !v)} className="rounded-full p-2 hover:bg-gray-100 dark:hover:bg-gray-700" title="Notifications">
              <Bell className="h-5 w-5" />
              {unreadCount > 0 && <span className="absolute -right-1 -top-1 rounded-full bg-red-500 px-1.5 text-[10px] text-white">{unreadCount}</span>}
            </button>
            {showNotifications && (
              <div className="absolute right-0 mt-2 w-80 rounded-xl border border-gray-200 bg-white p-2 shadow-card dark:border-gray-700 dark:bg-gray-800">
                <div className="mb-1 flex items-center justify-between px-2 py-1">
                  <p className="text-sm font-semibold">Recent</p>
                  <button type="button" className="text-xs text-primary-600" onClick={markAllRead}>Mark all read</button>
                </div>
                {recentNotifications.map((note) => (
                  <div key={note.id} className="rounded-lg p-2 text-sm hover:bg-gray-50 dark:hover:bg-gray-700">
                    <p className="font-medium text-gray-800 dark:text-gray-100">{note.title}</p>
                    <p className="line-clamp-1 text-xs text-gray-500 dark:text-gray-400">{note.message}</p>
                    <p className="text-[11px] text-gray-400">{formatDistanceToNow(new Date(note.sentAt), { addSuffix: true })}</p>
                  </div>
                ))}
                <button type="button" className="mt-1 w-full rounded-lg py-2 text-sm text-primary-600 hover:bg-primary-50" onClick={() => { navigate('/notifications'); setShowNotifications(false) }}>
                  View all
                </button>
              </div>
            )}
          </div>

          <span className="rounded-full bg-gray-100 px-3 py-1 text-xs font-semibold dark:bg-gray-700">EN</span>

          <div className="relative">
            <button
              type="button"
              onClick={() => setShowProfile((v) => !v)}
              className="grid h-9 w-9 place-items-center rounded-full bg-primary-600 text-white"
              title="Profile"
            >
              {(admin?.name || 'A').split(' ').map((n) => n[0]).join('').slice(0, 2)}
            </button>
            {showProfile && (
              <div className="absolute right-0 mt-2 w-64 rounded-xl border border-gray-200 bg-white p-2 shadow-card dark:border-gray-700 dark:bg-gray-800">
                <div className="border-b border-gray-100 p-2 text-sm dark:border-gray-700">
                  <p className="font-medium">{admin?.name}</p>
                  <p className="text-xs text-gray-500">{admin?.email}</p>
                </div>
                <button type="button" className="mt-1 block w-full rounded-lg px-3 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-gray-700">Profile Settings</button>
                <button
                  type="button"
                  className="block w-full rounded-lg px-3 py-2 text-left text-sm text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
                  onClick={() => {
                    logout()
                    navigate('/login')
                  }}
                >
                  Sign Out
                </button>
              </div>
            )}
          </div>
        </div>
      </header>

      <Modal isOpen={searchOpen} onClose={() => setSearchOpen(false)} title="Command Palette" size="max-w-2xl">
        <input
          ref={inputRef}
          value={query}
          onChange={(e) => {
            setQuery(e.target.value)
            setActiveIndex(0)
          }}
          onKeyDown={(e) => {
            if (e.key === 'ArrowDown') {
              e.preventDefault()
              setActiveIndex((idx) => Math.min(flatResults.length - 1, idx + 1))
            }
            if (e.key === 'ArrowUp') {
              e.preventDefault()
              setActiveIndex((idx) => Math.max(0, idx - 1))
            }
            if (e.key === 'Enter' && flatResults[activeIndex]) {
              e.preventDefault()
              handleSelect(flatResults[activeIndex])
            }
            if (e.key === 'Escape') setSearchOpen(false)
          }}
          className="mb-3 h-11 w-full rounded-xl border border-gray-200 px-3 text-sm outline-none focus:border-primary-500"
          placeholder="Search products, orders, customers..."
        />

        <div className="space-y-3">
          {grouped.length === 0 && <p className="text-sm text-gray-500">Start typing to search.</p>}
          {grouped.map((group) => (
            <div key={group.group}>
              <p className="mb-1 text-xs font-semibold uppercase text-gray-400">{group.group} ({group.items.length})</p>
              <div className="space-y-1">
                {group.items.map((item) => {
                  const idx = flatResults.findIndex((r) => r.id === item.id && r.group === item.group)
                  return (
                    <button
                      key={`${item.group}-${item.id}`}
                      type="button"
                      onClick={() => handleSelect(item)}
                      className={`block w-full rounded-lg px-3 py-2 text-left text-sm ${idx === activeIndex ? 'bg-primary-50 text-primary-700' : 'hover:bg-gray-50 dark:hover:bg-gray-700'}`}
                    >
                      {item.label}
                    </button>
                  )
                })}
              </div>
            </div>
          ))}
        </div>
      </Modal>
    </>
  )
}
