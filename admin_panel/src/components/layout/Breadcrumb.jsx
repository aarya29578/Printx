import { ChevronRight } from 'lucide-react'
import { Link, useLocation } from 'react-router-dom'
import { cn } from '../../core/utils/cn'

const breadcrumbMap = {
  '/dashboard': ['Dashboard'],
  '/products': ['Products'],
  '/products/add': ['Products', 'Add Product'],
  '/products/:id/edit': ['Products', 'Edit Product'],
  '/categories': ['Categories'],
  '/banners': ['Banners'],
  '/orders': ['Orders'],
  '/orders/category/:categoryId': ['Orders', 'Category'],
  '/orders/category/:categoryId/product/:productId': ['Orders', 'Category', 'Product'],
  '/orders/:id': ['Orders', 'Order Detail'],
  '/customers': ['Customers'],
  '/customers/:id': ['Customers', 'Customer Detail'],
  '/coupons': ['Coupons'],
  '/templates': ['Templates'],
  '/reviews': ['Reviews'],
  '/notifications': ['Notifications'],
  '/delivery': ['Delivery'],
  '/pricing': ['Pricing Rules'],
  '/admin-users': ['Admin Users'],
  '/settings': ['Settings'],
}

function resolveBreadcrumb(pathname) {
  const dynamicPath = pathname
    .replace(/\/products\/[^/]+\/edit$/, '/products/:id/edit')
    .replace(/\/orders\/category\/[^/]+\/product\/[^/]+$/, '/orders/category/:categoryId/product/:productId')
    .replace(/\/orders\/category\/[^/]+$/, '/orders/category/:categoryId')
    .replace(/\/orders\/[^/]+$/, '/orders/:id')
    .replace(/\/customers\/[^/]+$/, '/customers/:id')

  const labels = breadcrumbMap[dynamicPath] || ['Dashboard']
  const links = []

  labels.forEach((label, index) => {
    if (index === 0) {
      const firstPath = dynamicPath.split('/').filter(Boolean)[0]
      links.push({ label, path: `/${firstPath}` })
      return
    }
    links.push({ label, path: null })
  })

  return links
}

export default function Breadcrumb() {
  const location = useLocation()
  const crumbs = resolveBreadcrumb(location.pathname)

  return (
    <nav className="hidden items-center gap-1 text-sm text-gray-500 md:flex">
      <Link to="/dashboard" className="hover:text-primary-600">Home</Link>
      {crumbs.map((crumb, index) => (
        <span key={`${crumb.label}-${index}`} className="flex items-center gap-1">
          <ChevronRight className="h-3.5 w-3.5" />
          {crumb.path && index < crumbs.length - 1 ? (
            <Link to={crumb.path} className="hover:text-primary-600">{crumb.label}</Link>
          ) : (
            <span className={cn('font-medium', index === crumbs.length - 1 ? 'text-primary-600' : 'text-gray-700 dark:text-gray-200')}>
              {crumb.label}
            </span>
          )}
        </span>
      ))}
    </nav>
  )
}
