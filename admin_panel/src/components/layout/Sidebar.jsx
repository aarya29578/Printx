import { motion } from 'framer-motion'
import {
  Bell, Calculator, Grid3x3, Image, LayoutDashboard, LogOut, Package,
  Palette, Settings, ShieldCheck, ShoppingBag, Star, Tag, Truck, Users,
} from 'lucide-react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { routeItems } from '../../core/constants/routes'
import { APP_VERSION } from '../../core/constants/appConstants'
import { cn } from '../../core/utils/cn'
import { useAuthStore } from '../../store/authStore'
import { useOrdersStore } from '../../store/ordersStore'
import { useReviewsStore } from '../../store/reviewsStore'

const iconMap = {
  LayoutDashboard,
  Package,
  Grid3x3,
  Image,
  Palette,
  ShoppingBag,
  Users,
  Tag,
  Star,
  Bell,
  Truck,
  Calculator,
  ShieldCheck,
  Settings,
}

export default function Sidebar({ open }) {
  const location = useLocation()
  const navigate = useNavigate()
  const logout = useAuthStore((state) => state.logout)
  const admin = useAuthStore((state) => state.admin)
  const pendingOrders = useOrdersStore((state) => state.orders.filter((o) => ['pending', 'design_review'].includes(o.status)).length)
  const pendingReviews = useReviewsStore((state) => state.reviews.filter((r) => r.status === 'pending').length)

  const badges = { pendingOrders, pendingReviews }

  return (
    <motion.aside
      animate={{ width: open ? 260 : 72 }}
      className="h-full overflow-hidden bg-sidebar text-gray-200"
      transition={{ duration: 0.3 }}
    >
      <div className="flex h-full flex-col">
        <div className="border-b border-white/10 px-3 py-4">
          <div className="flex items-center gap-3 px-2">
            <img src="/printx-logo.svg" alt="PrintX" className="h-9 w-9 rounded-xl bg-white" />
            {open && (
              <div>
                <p className="font-display text-sm font-semibold">Admin Panel</p>
                <span className="mt-1 inline-flex rounded-full bg-primary-600/20 px-2 py-0.5 text-xs text-primary-100">{APP_VERSION}</span>
              </div>
            )}
          </div>
          {open && admin && (
            <div className="mt-4 rounded-xl bg-white/5 p-3">
              <div className="flex items-center gap-2">
                <div className="grid h-9 w-9 place-items-center rounded-full bg-primary-600 font-semibold">
                  {admin.name.split(' ').map((n) => n[0]).join('').slice(0, 2)}
                </div>
                <div>
                  <p className="text-sm font-medium">{admin.name}</p>
                  <span className="rounded-full bg-amber-500/20 px-2 py-0.5 text-xs text-amber-200">Super Admin</span>
                </div>
              </div>
            </div>
          )}
        </div>

        <div className="flex-1 overflow-y-auto py-4">
          {routeItems.map((group) => (
            <div key={group.group} className="mb-4">
              {open && <p className="px-4 pb-2 text-xs font-semibold uppercase tracking-wider text-gray-400">{group.group}</p>}
              {group.items.map((item) => {
                const Icon = iconMap[item.icon]
                const active = location.pathname === item.path || location.pathname.startsWith(`${item.path}/`)
                return (
                  <Link
                    key={item.path}
                    to={item.path}
                    title={!open ? item.label : undefined}
                    className={cn(
                      'mx-2 my-1 flex items-center rounded-lg px-3 py-2.5 transition',
                      active
                        ? 'bg-gradient-to-r from-primary-600 to-primary-700 text-white shadow-lg'
                        : 'text-gray-400 hover:bg-sidebar-hover hover:text-white',
                      !open && 'justify-center px-2',
                    )}
                  >
                    <Icon className="h-5 w-5 shrink-0" />
                    {open && <span className="ml-3 text-sm font-medium">{item.label}</span>}
                    {open && item.badge && badges[item.badge] > 0 && (
                      <span className={cn(
                        'ml-auto rounded-full px-2 py-0.5 text-xs',
                        item.badge === 'pendingOrders' ? 'bg-red-500/20 text-red-200' : 'bg-amber-500/20 text-amber-200',
                      )}
                      >
                        {badges[item.badge]}
                      </span>
                    )}
                  </Link>
                )
              })}
            </div>
          ))}
        </div>

        <div className="border-t border-white/10 p-3">
          <button
            type="button"
            onClick={() => {
              logout()
              navigate('/login')
            }}
            className="flex w-full items-center rounded-lg px-3 py-2 text-red-300 transition hover:bg-red-500/10 hover:text-red-200"
            title={!open ? 'Sign Out' : undefined}
          >
            <LogOut className="h-4 w-4" />
            {open && <span className="ml-2 text-sm font-medium">Sign Out</span>}
          </button>
        </div>
      </div>
    </motion.aside>
  )
}
