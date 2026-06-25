import { useMemo, useState, useEffect } from 'react'
import { createColumnHelper } from '@tanstack/react-table'
import { Eye, Pencil, Plus, Trash2 } from 'lucide-react'
import { useLocation, useNavigate } from 'react-router-dom'

import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Button from '../../components/ui/Button'
import DataTable from '../../components/data/DataTable'
import StatusBadge from '../../components/ui/Badge'
import Select from '../../components/ui/Select'
import Input from '../../components/ui/Input'
import ConfirmDialog from '../../components/ui/ConfirmDialog'
import { useProductsStore } from '../../store/productsStore'
import { useCategoriesStore } from '../../store/categoriesStore'
import { formatINR } from '../../core/utils/formatCurrency'

const columnHelper = createColumnHelper()

export default function ProductsPage() {
  const navigate = useNavigate()
  const location = useLocation()
  const { products, deleteProduct, toggleStatus, deleteBulk, setStatusBulk, clearAllProducts } = useProductsStore()
  const { categories: categoryItems, refreshCategory } = useCategoriesStore()
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('all')
  const [status, setStatus] = useState('all')

  useEffect(() => {
    const params = new URLSearchParams(location.search)
    const categoryParam = params.get('category')
    if (categoryParam) setCategory(categoryParam)
  }, [location.search])
  const [deletingId, setDeletingId] = useState(null)
  const [selectedRows, setSelectedRows] = useState([])
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false)
  const [clearAllOpen, setClearAllOpen] = useState(false)

  const filtered = useMemo(() => products.filter((item) => {
    const name = (item.name ?? '').toString()
    const sku = (item.sku ?? '').toString()
    const matchesQuery = name.toLowerCase().includes(query.toLowerCase()) || sku.toLowerCase().includes(query.toLowerCase())
    const matchesCategory = category === 'all' || (item.category ?? '') === category
    const matchesStatus = status === 'all' || (item.status ?? '') === status
    return matchesQuery && matchesCategory && matchesStatus
  }), [products, query, category, status])

  const categoryMap = new Map(categoryItems.map((item) => [item.id, item.name]))
  const categories = [...new Set(products.map((item) => item.category).filter(Boolean))]

  const columns = [
    columnHelper.accessor('name', {
      header: 'Product',
      cell: ({ row }) => (
        <div className="flex items-center gap-3">
          <img src={row.original.imageUrl || 'https://picsum.photos/seed/product/80/80'} alt={row.original.name || 'Product'} className="h-12 w-12 rounded-xl object-cover" />
          <div>
            <p className="font-medium">{row.original.name || 'Unnamed product'}</p>
            <p className="text-xs text-gray-500">{row.original.sku || 'SKU'}</p>
          </div>
        </div>
      ),
    }),
    columnHelper.accessor('category', {
      header: 'Category',
      cell: (info) => categoryMap.get(info.getValue()) || info.getValue() || 'Unassigned',
    }),
    columnHelper.accessor('basePrice', {
      header: 'Pricing',
      cell: ({ row }) => (
        <div>
          <p className="font-semibold">{formatINR(row.original.basePrice)}</p>
          <p className="text-xs text-gray-500">for 100 qty</p>
        </div>
      ),
    }),
    columnHelper.accessor('stock', {
      header: 'Stock',
      cell: (info) => <StatusBadge status={info.getValue()} />,
    }),
    columnHelper.accessor('status', {
      header: 'Status',
      cell: (info) => <StatusBadge status={info.getValue()} />,
    }),
    columnHelper.display({
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <button type="button" title="View" className="rounded p-1 hover:bg-gray-100"><Eye className="h-4 w-4" /></button>
          <button type="button" title="Edit" className="rounded p-1 hover:bg-gray-100" onClick={() => navigate(`/products/${row.original.id}/edit`)}><Pencil className="h-4 w-4" /></button>
          <button type="button" title="Toggle" className="rounded p-1 hover:bg-gray-100" onClick={() => { toggleStatus(row.original.id); toast.success('Product status updated') }}><StatusBadge status={row.original.status === 'active' ? 'active' : 'draft'} /></button>
          <button type="button" title="Delete" className="rounded p-1 text-red-600 hover:bg-red-50" onClick={() => setDeletingId(row.original.id)}><Trash2 className="h-4 w-4" /></button>
        </div>
      ),
    }),
  ]

  const renderedIds = filtered.map((p) => p.id)
  console.log('[UI RENDER] state.products.length=', products.length)
  console.log('[UI RENDER] renderedProductIds=', renderedIds)
  console.log('[UI RENDER] renderedProductNames=', filtered.map((p) => p.name))
  console.log('[UI RENDER] activeFilters=', { query, category, status })

  // Targeted predicate evidence for PRD1782024592071
  const targetId = 'PRD1782024592071'
  const target = products.find((p) => p.id === targetId)
  const targetInFiltered = filtered.some((p) => p.id === targetId)
  if (target) {
    const name = (target.name ?? '').toString()
    const sku = (target.sku ?? '').toString()
    const matchesQuery = name.toLowerCase().includes(query.toLowerCase()) || sku.toLowerCase().includes(query.toLowerCase())
    const matchesCategory = category === 'all' || (target.category ?? '') === category
    const matchesStatus = status === 'all' || (target.status ?? '') === status
    console.log('[UI RENDER][TARGET] target=', {
      id: target.id,
      name: target.name,
      sku: target.sku,
      category: target.category,
      status: target.status,
      query,
      categoryFilter: category,
      statusFilter: status,
      membershipInStateProducts: Boolean(target),
      membershipInFiltered: targetInFiltered,
      predicateResults: {
        matchesQuery,
        matchesCategory,
        matchesStatus,
      },
      predicateReturnsFalse: {
        matchesQuery: !matchesQuery,
        matchesCategory: !matchesCategory,
        matchesStatus: !matchesStatus,
      },
    })
  } else {
    console.log('[UI RENDER][TARGET] target missing from state.products', { id: targetId })
  }


  return (
    <div>
      <PageHeader
        title="Products"
        subtitle={`${products.length} products`}

        actions={(
          <>
            <Button variant="secondary" onClick={() => toast.success('CSV exported from table action')}>Export CSV</Button>
            {products.length > 0 && (
              <Button variant="danger" onClick={() => setClearAllOpen(true)}>Clear All ({products.length})</Button>
            )}
            <Button icon={Plus} onClick={() => navigate('/products/add')}>Add Product</Button>
          </>
        )}
      />

      <div className="mb-5 flex flex-wrap gap-3">
        <Input className="w-72" placeholder="Search products" value={query} onChange={(e) => setQuery(e.target.value)} />
        <Select value={category} onChange={(e) => setCategory(e.target.value)} className="w-52">
          <option value="all">All Categories</option>
          {categories.map((item) => <option key={item} value={item}>{item}</option>)}
        </Select>
        <Select value={status} onChange={(e) => setStatus(e.target.value)} className="w-52">
          <option value="all">All Status</option>
          <option value="active">Active</option>
          <option value="draft">Draft</option>
          <option value="out_of_stock">Out of Stock</option>
        </Select>
        {selectedRows.length > 0 && (
          <>
            <Button variant="secondary" onClick={() => { setStatusBulk(selectedRows.map((item) => item.id), 'active'); toast.success(`${selectedRows.length} products activated`); setSelectedRows([]) }}>
              Activate Selected
            </Button>
            <Button variant="danger" onClick={() => setBulkDeleteOpen(true)}>
              Delete Selected ({selectedRows.length})
            </Button>
          </>
        )}
      </div>

      <DataTable
        data={filtered}
        columns={columns}
        pageSize={10}
        selectable
        onSelectionChange={setSelectedRows}
        onRowClick={(row) => navigate(`/products/${row.id}/edit`)}
        emptyTitle="No products found"
        emptySubtitle="Try changing filters or add a new product."
      />

      <ConfirmDialog
        isOpen={Boolean(deletingId)}
        onClose={() => setDeletingId(null)}
        onConfirm={async () => {
          const deletingProduct = products.find((p) => p.id === deletingId)
          const categoryToRefresh = deletingProduct?.category
          await deleteProduct(deletingId)
          if (categoryToRefresh) await refreshCategory(categoryToRefresh)
          toast.success('Product deleted')
        }}
        title="Delete Product"
        description="This will permanently delete the selected product."
      />

      <ConfirmDialog
        isOpen={bulkDeleteOpen}
        onClose={() => setBulkDeleteOpen(false)}
        onConfirm={async () => {
          const categoriesToRefresh = new Set()
          selectedRows.forEach((row) => {
            if (row.category) categoriesToRefresh.add(row.category)
          })
          await deleteBulk(selectedRows.map((item) => item.id))
          for (const catId of categoriesToRefresh) {
            await refreshCategory(catId)
          }
          setSelectedRows([])
          toast.success('Selected products deleted')
        }}
        title="Delete Selected Products"
        description="This permanently deletes all selected products. Type DELETE to continue."
        requireTyped
        typedValue="DELETE"
      />

      <ConfirmDialog
        isOpen={clearAllOpen}
        onClose={() => setClearAllOpen(false)}
        onConfirm={async () => {
          await clearAllProducts()
          toast.success('All products cleared!')
        }}
        title="Clear ALL Products"
        description={`This will PERMANENTLY delete ALL ${products.length} products from the database. Type CLEAR ALL to continue.`}
        requireTyped
        typedValue="CLEAR ALL"
      />
    </div>
  )
}
