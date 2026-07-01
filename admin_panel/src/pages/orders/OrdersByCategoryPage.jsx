import { useMemo, useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { ChevronRight, Package, TrendingUp } from 'lucide-react'
import PageHeader from '../../components/ui/PageHeader'
import StatusBadge from '../../components/ui/Badge'
import Input from '../../components/ui/Input'
import { useOrdersStore } from '../../store/ordersStore'
import { useProductsStore } from '../../store/productsStore'
import { useCategoriesStore } from '../../store/categoriesStore'
import { formatINR } from '../../core/utils/formatCurrency'

export default function OrdersByCategoryPage() {
  const { categoryId } = useParams()
  const navigate = useNavigate()
  const { orders } = useOrdersStore()
  const { products } = useProductsStore()
  const { categories } = useCategoriesStore()
  const [query, setQuery] = useState('')

  const category = categories.find((c) => c.id === categoryId)
  const categoryProducts = useMemo(
    () => products.filter((p) => p.category === categoryId),
    [products, categoryId],
  )

  // Per-product order statistics
  const productStats = useMemo(() => {
    const stats = {}
    categoryProducts.forEach((p) => {
      const po = orders.filter((o) => o.items?.some((i) => i.productId === p.id))
      stats[p.id] = {
        total:     po.length,
        pending:   po.filter((o) => ['pending', 'design_review'].includes(o.status)).length,
        printing:  po.filter((o) => o.status === 'printing').length,
        delivered: po.filter((o) => o.status === 'delivered').length,
        revenue:   po.reduce((s, o) => s + (Number(o.totalAmount) || 0), 0),
      }
    })
    return stats
  }, [orders, categoryProducts])

  const totalOrders  = Object.values(productStats).reduce((s, v) => s + v.total, 0)
  const totalRevenue = Object.values(productStats).reduce((s, v) => s + v.revenue, 0)

  const displayProducts = query
    ? categoryProducts.filter((p) => p.name?.toLowerCase().includes(query.toLowerCase()))
    : categoryProducts

  if (!category) {
    return (
      <div className="p-10 text-center text-gray-500">
        Category not found.{' '}
        <Link to="/orders" className="text-primary-600 hover:underline">Back to Orders</Link>
      </div>
    )
  }

  return (
    <div className="space-y-5">
      {/* Breadcrumb */}
      <nav className="flex items-center gap-1.5 text-sm text-gray-500">
        <Link to="/orders" className="hover:text-primary-600">Orders</Link>
        <ChevronRight className="h-3.5 w-3.5 flex-shrink-0" />
        <span className="font-medium text-gray-800 dark:text-gray-200">{category.name}</span>
      </nav>

      {/* Category header strip */}
      {category.imageUrl && (
        <div className="relative h-32 overflow-hidden rounded-2xl">
          <img src={category.imageUrl} alt={category.name} className="h-full w-full object-cover" />
          <div className="absolute inset-0 bg-gradient-to-r from-black/60 to-transparent" />
          <p className="absolute bottom-4 left-5 text-xl font-bold text-white">{category.name}</p>
        </div>
      )}

      <PageHeader
        title={category.imageUrl ? '' : category.name}
        subtitle={`${categoryProducts.length} product${categoryProducts.length !== 1 ? 's' : ''} · ${totalOrders} order${totalOrders !== 1 ? 's' : ''}`}
      />

      {/* Summary cards */}
      <div className="grid gap-3 sm:grid-cols-3">
        {[
          ['Total Orders',   totalOrders,                   'text-gray-800',   'bg-gray-50'],
          ['Total Revenue',  formatINR(totalRevenue),        'text-green-700',  'bg-green-50'],
          ['Active Products',categoryProducts.filter(p => p.status !== 'draft').length, 'text-primary-700', 'bg-primary-50'],
        ].map(([label, val, cls, bg]) => (
          <div key={label} className={`flex items-center gap-3 rounded-xl border border-gray-100 p-4 shadow-sm dark:border-gray-700 dark:bg-gray-800 ${bg}`}>
            <TrendingUp className="h-5 w-5 text-gray-400 dark:text-gray-500" />
            <div>
              <p className="text-xs text-gray-500">{label}</p>
              <p className={`text-xl font-bold ${cls}`}>{val}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Search */}
      <Input
        className="w-72"
        placeholder="Search products…"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />

      {displayProducts.length === 0 && (
        <div className="rounded-xl border border-dashed border-gray-200 bg-gray-50 p-12 text-center text-sm text-gray-400 dark:border-gray-700 dark:bg-gray-800/50">
          No products found in this category.
        </div>
      )}

      {/* Product cards grid */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {displayProducts.map((product) => {
          const s = productStats[product.id] || { total: 0, pending: 0, printing: 0, delivered: 0, revenue: 0 }
          return (
            <button
              key={product.id}
              type="button"
              onClick={() => navigate(`/orders/category/${categoryId}/product/${product.id}`)}
              className="group rounded-xl border border-gray-200 bg-white text-left shadow-sm transition hover:border-primary-300 hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
            >
              {/* Product image */}
              <div className="h-36 overflow-hidden rounded-t-xl bg-gray-100 dark:bg-gray-700">
                {product.imageUrl ? (
                  <img
                    src={product.imageUrl}
                    alt={product.name}
                    className="h-full w-full object-cover transition group-hover:scale-105"
                    onError={(e) => { e.currentTarget.style.display = 'none' }}
                  />
                ) : (
                  <div className="flex h-full items-center justify-center">
                    <Package className="h-10 w-10 text-gray-300" />
                  </div>
                )}
              </div>

              <div className="p-4">
                <div className="flex items-start justify-between gap-2">
                  <p className="font-semibold leading-tight text-gray-800 dark:text-white">{product.name}</p>
                  <StatusBadge status={product.status || 'active'} />
                </div>

                {product.price !== undefined && (
                  <p className="mt-1 text-sm text-gray-500">
                    {typeof product.price === 'number' ? formatINR(product.price) : 'Variable pricing'}
                  </p>
                )}

                {/* Order status breakdown */}
                <div className="mt-3 grid grid-cols-3 gap-1.5">
                  {[
                    ['Pending',  s.pending,   'bg-amber-50  text-amber-700  dark:bg-amber-900/30  dark:text-amber-400'],
                    ['Printing', s.printing,  'bg-purple-50 text-purple-700 dark:bg-purple-900/30 dark:text-purple-400'],
                    ['Done',     s.delivered, 'bg-green-50  text-green-700  dark:bg-green-900/30  dark:text-green-400'],
                  ].map(([label, val, cls]) => (
                    <div key={label} className={`rounded-lg p-2 text-center ${cls}`}>
                      <p className="text-base font-bold">{val}</p>
                      <p className="text-[11px]">{label}</p>
                    </div>
                  ))}
                </div>

                <div className="mt-3 flex items-center justify-between border-t border-gray-100 pt-3 dark:border-gray-700">
                  <span className="text-xs text-gray-500">
                    {s.total} order{s.total !== 1 ? 's' : ''}
                  </span>
                  <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                    {formatINR(s.revenue)}
                  </span>
                </div>
              </div>
            </button>
          )
        })}
      </div>
    </div>
  )
}
