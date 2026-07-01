import { useMemo, useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { createColumnHelper } from '@tanstack/react-table'
import { ChevronRight, Eye, FileDown, Package } from 'lucide-react'
import toast from 'react-hot-toast'
import DataTable from '../../components/data/DataTable'
import StatusBadge from '../../components/ui/Badge'
import Select from '../../components/ui/Select'
import Input from '../../components/ui/Input'
import Tabs from '../../components/ui/Tabs'
import { useOrdersStore } from '../../store/ordersStore'
import { useProductsStore } from '../../store/productsStore'
import { useCategoriesStore } from '../../store/categoriesStore'
import { formatINR } from '../../core/utils/formatCurrency'
import { generateInvoicePDF } from '../../core/utils/generatePDF'
import { safeFormatOrderDate } from '../../core/utils/formatOrderDate'

const columnHelper = createColumnHelper()

export default function OrdersByProductPage() {
  const { categoryId, productId } = useParams()
  const navigate = useNavigate()
  const { orders, updateStatus } = useOrdersStore()
  const { products } = useProductsStore()
  const { categories } = useCategoriesStore()
  const [query, setQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const category = categories.find((c) => c.id === categoryId)
  const product   = products.find((p) => p.id === productId)

  // Orders that contain this product
  const productOrders = useMemo(
    () => orders.filter((o) => o.items?.some((i) => i.productId === productId)),
    [orders, productId],
  )

  const filtered = useMemo(() => productOrders.filter((o) => {
    const q = query.toLowerCase()
    const matchQ = String(o.id ?? '').toLowerCase().includes(q) ||
                   String(o.userName ?? '').toLowerCase().includes(q) ||
                   String(o.userEmail ?? '').toLowerCase().includes(q)
    const matchS = statusFilter === 'all' || o.status === statusFilter
    return matchQ && matchS
  }), [productOrders, query, statusFilter])

  const tabs = [
    { label: `All (${productOrders.length})`,                                              value: 'all' },
    { label: `Pending (${productOrders.filter((o) => o.status === 'pending').length})`,    value: 'pending' },
    { label: `Review (${productOrders.filter((o) => o.status === 'design_review').length})`, value: 'design_review' },
    { label: `Printing (${productOrders.filter((o) => o.status === 'printing').length})`,  value: 'printing' },
    { label: `Shipped (${productOrders.filter((o) => o.status === 'shipped').length})`,    value: 'shipped' },
    { label: `Delivered (${productOrders.filter((o) => o.status === 'delivered').length})`,value: 'delivered' },
  ]

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
          <p className="font-medium">{row.original.userName || '—'}</p>
          {row.original.userEmail && <p className="text-xs text-gray-500">{row.original.userEmail}</p>}
          {row.original.userPhone && <p className="text-xs text-gray-500">{row.original.userPhone}</p>}
        </div>
      ),
    }),
    columnHelper.display({
      id: 'variant',
      header: 'Variant / Specs',
      cell: ({ row }) => {
        const item = row.original.items?.find((i) => i.productId === productId)
        if (!item) return <span className="text-xs text-gray-400">—</span>
        return (
          <div className="space-y-0.5 text-sm">
            {item.size     && <p>Size: <strong>{item.size}</strong></p>}
            {item.finish   && <p>Finish: <strong>{item.finish}</strong></p>}
            {item.quantity && <p>Qty: <strong>{item.quantity}</strong></p>}
          </div>
        )
      },
    }),
    columnHelper.accessor('totalAmount', {
      header: 'Amount',
      cell: (info) => <span className="font-semibold">{formatINR(info.getValue())}</span>,
    }),
    columnHelper.display({
      id: 'design',
      header: 'Design',
      cell: ({ row }) => {
        const item = row.original.items?.find((i) => i.productId === productId)
        if (!item?.customDesignUrl) return <span className="text-xs text-gray-400">—</span>
        return (
          <a
            href={item.customDesignUrl}
            target="_blank"
            rel="noreferrer"
            className="text-xs font-medium text-primary-600 hover:underline"
            onClick={(e) => e.stopPropagation()}
          >
            View design
          </a>
        )
      },
    }),
    columnHelper.accessor('status', {
      header: 'Status',
      cell: (info) => <StatusBadge status={info.getValue()} />,
    }),
    columnHelper.accessor('createdAt', {
      header: 'Date',
      cell: (info) => (
        <span className="text-sm">{safeFormatOrderDate(info.getValue() ?? info.row.original?.date)}</span>
      ),
    }),
    columnHelper.display({
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <div className="flex items-center gap-1">
          <button
            type="button"
            className="rounded p-1 hover:bg-gray-100"
            title="View details"
            onClick={() => navigate(`/orders/${row.original.id}`)}
          >
            <Eye className="h-4 w-4" />
          </button>
          <button
            type="button"
            className="rounded p-1 hover:bg-gray-100"
            title="Download invoice"
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

  if (!product) {
    return (
      <div className="p-10 text-center text-gray-500">
        Product not found.{' '}
        <Link to={`/orders/category/${categoryId}`} className="text-primary-600 hover:underline">
          Back to {category?.name ?? 'Category'}
        </Link>
      </div>
    )
  }

  const totalRevenue = productOrders.reduce((s, o) => s + (Number(o.totalAmount) || 0), 0)

  return (
    <div className="space-y-5">
      {/* Breadcrumb */}
      <nav className="flex items-center gap-1.5 flex-wrap text-sm text-gray-500">
        <Link to="/orders" className="hover:text-primary-600">Orders</Link>
        <ChevronRight className="h-3.5 w-3.5 flex-shrink-0" />
        <Link to={`/orders/category/${categoryId}`} className="hover:text-primary-600">
          {category?.name ?? 'Category'}
        </Link>
        <ChevronRight className="h-3.5 w-3.5 flex-shrink-0" />
        <span className="font-medium text-gray-800 dark:text-gray-200">{product.name}</span>
      </nav>

      {/* Product identity */}
      <div className="flex items-center gap-4">
        {product.imageUrl ? (
          <div className="h-16 w-16 flex-shrink-0 overflow-hidden rounded-xl border border-gray-200">
            <img src={product.imageUrl} alt={product.name} className="h-full w-full object-cover" />
          </div>
        ) : (
          <div className="flex h-16 w-16 flex-shrink-0 items-center justify-center rounded-xl bg-gray-100 dark:bg-gray-700">
            <Package className="h-7 w-7 text-gray-400" />
          </div>
        )}
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">{product.name}</h1>
          <p className="text-sm text-gray-500">
            {productOrders.length} order{productOrders.length !== 1 ? 's' : ''}
            {product.price !== undefined && typeof product.price === 'number' && ` · ${formatINR(product.price)}`}
          </p>
        </div>
      </div>

      {/* Quick stats */}
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {[
          ['Total',     productOrders.length,                                                              'text-gray-800'],
          ['Pending',   productOrders.filter((o) => ['pending','design_review'].includes(o.status)).length,'text-amber-600'],
          ['Printing',  productOrders.filter((o) => o.status === 'printing').length,                       'text-purple-600'],
          ['Delivered', productOrders.filter((o) => o.status === 'delivered').length,                      'text-green-600'],
        ].map(([label, val, cls]) => (
          <div key={label} className="rounded-xl border border-gray-100 bg-white p-4 shadow-sm dark:border-gray-700 dark:bg-gray-800">
            <p className="text-xs text-gray-500">{label}</p>
            <p className={`mt-1 text-2xl font-bold ${cls}`}>{val}</p>
          </div>
        ))}
      </div>

      {/* Revenue banner */}
      <div className="flex items-center justify-between rounded-xl border border-green-100 bg-green-50 px-5 py-3 dark:border-green-800/40 dark:bg-green-900/20">
        <span className="text-sm font-medium text-green-700 dark:text-green-400">Total Revenue from this product</span>
        <span className="text-lg font-bold text-green-700 dark:text-green-400">{formatINR(totalRevenue)}</span>
      </div>

      {/* Filters */}
      <Tabs tabs={tabs} active={statusFilter} onChange={setStatusFilter} />

      <div className="flex flex-wrap gap-3">
        <Input
          className="w-72"
          placeholder="Search order ID, customer name or email"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>

      <DataTable data={filtered} columns={columns} pageSize={15} />
    </div>
  )
}
