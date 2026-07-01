import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { createColumnHelper } from '@tanstack/react-table'
import { Eye, FileDown, Grid3X3, List, ShoppingBag } from 'lucide-react'
import toast from 'react-hot-toast'
import DataTable from '../../components/data/DataTable'
import PageHeader from '../../components/ui/PageHeader'
import StatusBadge from '../../components/ui/Badge'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import Button from '../../components/ui/Button'
import Tabs from '../../components/ui/Tabs'
import { useOrdersStore } from '../../store/ordersStore'
import { useProductsStore } from '../../store/productsStore'
import { useCategoriesStore } from '../../store/categoriesStore'
import { formatINR } from '../../core/utils/formatCurrency'
import { generateInvoicePDF } from '../../core/utils/generatePDF'
import { safeFormatOrderDate } from '../../core/utils/formatOrderDate'

const columnHelper = createColumnHelper()

export default function OrdersPage() {
  const navigate = useNavigate()
  const { orders, updateStatus } = useOrdersStore()
  const { products } = useProductsStore()
  const { categories } = useCategoriesStore()

  const [view, setView] = useState('categories')
  const [query, setQuery] = useState('')
  const [payment, setPayment] = useState('all')
  const [statusTab, setStatusTab] = useState('all')

  // ── Stats ──────────────────────────────────────────────────────────────────
  const todayKey = new Date().toISOString().slice(0, 10)
  const countByStatus = (s) => orders.filter((o) => o?.status === s).length
  const countNewToday = orders.filter((o) => {
    const ca = o?.createdAt
    if (!ca) return false
    const iso = typeof ca === 'string' ? ca : null
    return iso ? iso.slice(0, 10) === todayKey : false
  }).length

  // ── Order counts per category (computed) ──────────────────────────────────
  const categoryOrderCounts = useMemo(() => {
    const pidToCategory = {}
    products.forEach((p) => { if (p.id && p.category) pidToCategory[p.id] = p.category })

    const counts = {}
    orders.forEach((order) => {
      const seenCats = new Set()
      ;(order.items || []).forEach((item) => {
        const catId = pidToCategory[item.productId]
        if (catId && !seenCats.has(catId)) {
          counts[catId] = (counts[catId] || 0) + 1
          seenCats.add(catId)
        }
      })
    })
    return counts
  }, [orders, products])

  // ── Flat table (All Orders view) ───────────────────────────────────────────
  const statusTabs = [
    { label: `All (${orders.length})`, value: 'all' },
    { label: `Pending (${countByStatus('pending')})`, value: 'pending' },
    { label: `Design Review (${countByStatus('design_review')})`, value: 'design_review' },
    { label: `Printing (${countByStatus('printing')})`, value: 'printing' },
    { label: `Shipped (${countByStatus('shipped')})`, value: 'shipped' },
    { label: `Delivered (${countByStatus('delivered')})`, value: 'delivered' },
    { label: `Cancelled (${countByStatus('cancelled')})`, value: 'cancelled' },
  ]

  const filtered = useMemo(() => orders.filter((item) => {
    const q = query.toLowerCase()
    const matchesQuery =
      String(item?.id ?? '').toLowerCase().includes(q) ||
      String(item?.userName ?? '').toLowerCase().includes(q)
    const matchesPayment = payment === 'all' || item?.payment === payment
    const matchesStatus = statusTab === 'all' || item?.status === statusTab
    return matchesQuery && matchesPayment && matchesStatus
  }), [orders, query, payment, statusTab])

  const columns = [
    columnHelper.accessor('id', {
      header: 'Order ID',
      cell: ({ row }) => (
        <span className="font-mono text-xs font-medium text-primary-600">{row.original.id}</span>
      ),
    }),
    columnHelper.display({
      id: 'customer',
      header: 'Customer',
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original?.userName}</p>
          {row.original?.userPhone && <p className="text-xs text-gray-500">{row.original.userPhone}</p>}
          {row.original?.userEmail && <p className="text-xs text-gray-500">{row.original.userEmail}</p>}
        </div>
      ),
    }),
    columnHelper.display({
      id: 'products',
      header: 'Product(s)',
      cell: ({ row }) => (
        <div className="space-y-0.5">
          {(row.original?.items || []).map((it, idx) => (
            <p key={idx} className="text-sm">{it.productName}</p>
          ))}
        </div>
      ),
    }),
    columnHelper.accessor('totalAmount', {
      header: 'Amount',
      cell: (info) => <span className="font-semibold">{formatINR(info.getValue())}</span>,
    }),
    columnHelper.accessor('payment', {
      header: 'Payment',
      cell: (info) => (
        <span className="rounded-full bg-gray-100 px-2 py-0.5 text-xs">{info.getValue() || '—'}</span>
      ),
    }),
    columnHelper.accessor('status', {
      header: 'Status',
      cell: (info) => <StatusBadge status={info.getValue()} />,
    }),
    columnHelper.accessor('createdAt', {
      header: 'Date',
      cell: (info) => <span className="text-sm">{safeFormatOrderDate(info.getValue() ?? info.row.original?.date)}</span>,
    }),
    columnHelper.display({
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <div className="flex items-center gap-1">
          <button
            type="button"
            className="rounded p-1 hover:bg-gray-100"
            title="View"
            onClick={() => navigate(`/orders/${row.original.id}`)}
          >
            <Eye className="h-4 w-4" />
          </button>
          <button
            type="button"
            className="rounded p-1 hover:bg-gray-100"
            title="Invoice"
            onClick={() => generateInvoicePDF(row.original)}
          >
            <FileDown className="h-4 w-4" />
          </button>
          <Select
            className="h-8 w-32 text-xs"
            value={row.original.status}
            onChange={(e) => {
              updateStatus(row.original.id, e.target.value)
              toast.success('Status updated')
            }}
          >
            <option value="pending">Pending</option>
            <option value="design_review">Design Review</option>
            <option value="printing">Printing</option>
            <option value="shipped">Shipped</option>
            <option value="delivered">Delivered</option>
            <option value="cancelled">Cancelled</option>
          </Select>
        </div>
      ),
    }),
  ]

  return (
    <div className="space-y-5">
      {/* Header */}
      <PageHeader
        title="Orders"
        subtitle={`${orders.length} total orders`}
        actions={(
          <div className="flex items-center gap-2">
            {/* View toggle */}
            <div className="flex overflow-hidden rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-800">
              <button
                type="button"
                onClick={() => setView('categories')}
                className={`flex items-center gap-1.5 px-3 py-2 text-sm transition ${
                  view === 'categories'
                    ? 'bg-primary-600 text-white'
                    : 'text-gray-600 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-700'
                }`}
              >
                <Grid3X3 className="h-3.5 w-3.5" />
                By Category
              </button>
              <button
                type="button"
                onClick={() => setView('all')}
                className={`flex items-center gap-1.5 px-3 py-2 text-sm transition ${
                  view === 'all'
                    ? 'bg-primary-600 text-white'
                    : 'text-gray-600 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-gray-700'
                }`}
              >
                <List className="h-3.5 w-3.5" />
                All Orders
              </button>
            </div>
            <Button variant="secondary" size="sm">Export CSV</Button>
          </div>
        )}
      />

      {/* Stats row */}
      <div className="grid gap-3 sm:grid-cols-2 md:grid-cols-5">
        {[
          ['New Today',  countNewToday,          'bg-indigo-50 text-indigo-700'],
          ['Printing',   countByStatus('printing'),  'bg-purple-50 text-purple-700'],
          ['Shipped',    countByStatus('shipped'),   'bg-blue-50 text-blue-700'],
          ['Delivered',  countByStatus('delivered'), 'bg-green-50 text-green-700'],
          ['Cancelled',  countByStatus('cancelled'), 'bg-red-50 text-red-700'],
        ].map(([label, val, cls]) => (
          <div key={label} className="rounded-xl border border-gray-100 bg-white p-4 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <p className="text-xs text-gray-500 dark:text-gray-400">{label}</p>
            <p className={`mt-1 inline-flex rounded-full px-2.5 py-0.5 text-sm font-semibold ${cls}`}>{val}</p>
          </div>
        ))}
      </div>

      {/* ── Category browse view ──────────────────────────────────────────── */}
      {view === 'categories' && (
        <div>
          <p className="mb-4 text-sm text-gray-500 dark:text-gray-400">
            Click a category to browse its products and orders
          </p>
          {categories.length === 0 && (
            <div className="rounded-xl border border-dashed border-gray-200 bg-gray-50 p-12 text-center text-sm text-gray-400 dark:border-gray-700 dark:bg-gray-800/50">
              No categories found.
            </div>
          )}
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {categories.map((cat) => {
              const orderCount = categoryOrderCounts[cat.id] || 0
              return (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => navigate(`/orders/category/${cat.id}`)}
                  className="group rounded-xl border border-gray-200 bg-white text-left shadow-sm transition hover:border-primary-300 hover:shadow-md dark:border-gray-700 dark:bg-gray-800"
                >
                  {/* Image / colour strip */}
                  <div
                    className="relative h-28 overflow-hidden rounded-t-xl"
                    style={{ background: cat.imageUrl ? undefined : (cat.color || '#4F46E5') }}
                  >
                    {cat.imageUrl ? (
                      <img
                        src={cat.imageUrl}
                        alt={cat.name}
                        className="h-full w-full object-cover transition group-hover:scale-105"
                        onError={(e) => {
                          e.currentTarget.style.display = 'none'
                          e.currentTarget.parentElement.style.background = cat.color || '#4F46E5'
                        }}
                      />
                    ) : (
                      <ShoppingBag className="absolute inset-0 m-auto h-10 w-10 text-white/70" />
                    )}
                    {/* Order count badge */}
                    <span className="absolute right-2 top-2 rounded-full bg-white/90 px-2 py-0.5 text-xs font-semibold text-gray-700 shadow">
                      {orderCount} order{orderCount !== 1 ? 's' : ''}
                    </span>
                  </div>

                  <div className="p-4">
                    <p className="font-semibold text-gray-800 dark:text-white">{cat.name}</p>
                    <div className="mt-1.5 flex items-center justify-between text-xs text-gray-500">
                      <span>{cat.productCount ?? 0} product{(cat.productCount ?? 0) !== 1 ? 's' : ''}</span>
                      <StatusBadge status={cat.status || 'active'} />
                    </div>
                  </div>
                </button>
              )
            })}
          </div>
        </div>
      )}

      {/* ── All Orders flat table ─────────────────────────────────────────── */}
      {view === 'all' && (
        <div className="space-y-4">
          <Tabs tabs={statusTabs} active={statusTab} onChange={setStatusTab} />
          <div className="flex flex-wrap gap-3">
            <Input
              className="w-72"
              placeholder="Search order ID or customer"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
            <Select
              className="w-48"
              value={payment}
              onChange={(e) => setPayment(e.target.value)}
            >
              <option value="all">All payments</option>
              <option value="UPI">UPI</option>
              <option value="Card">Card</option>
              <option value="COD">COD</option>
              <option value="NetBanking">NetBanking</option>
            </Select>
          </div>
          <DataTable data={filtered} columns={columns} pageSize={15} />
        </div>
      )}
    </div>
  )
}
