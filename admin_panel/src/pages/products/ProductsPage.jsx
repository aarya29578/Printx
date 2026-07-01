import { useMemo, useState } from 'react'
import { createColumnHelper } from '@tanstack/react-table'
import { Eye, Pencil, Plus, Trash2 } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
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
  const { products, deleteProduct, toggleStatus, deleteBulk, setStatusBulk } = useProductsStore()
  const { categories: categoryItems, refreshCategory } = useCategoriesStore()
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('all')
  const [status, setStatus] = useState('all')
  const [deletingId, setDeletingId] = useState(null)
  const [selectedRows, setSelectedRows] = useState([])
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false)

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
        // stopPropagation prevents clicks on any action button from
        // bubbling up to the <tr> onRowClick (which would navigate to edit)
        <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
          <button type="button" title="View" className="rounded p-1 hover:bg-gray-100"><Eye className="h-4 w-4" /></button>
          <button type="button" title="Edit" className="rounded p-1 hover:bg-gray-100" onClick={() => navigate(`/products/${row.original.id}/edit`)}><Pencil className="h-4 w-4" /></button>
          <button type="button" title="Toggle" className="rounded p-1 hover:bg-gray-100" onClick={() => { toggleStatus(row.original.id); toast.success('Product status updated') }}><StatusBadge status={row.original.status === 'active' ? 'active' : 'draft'} /></button>
          <button type="button" title="Delete" className="rounded p-1 text-red-600 hover:bg-red-50" onClick={() => { console.log('[DELETE] Button clicked for id:', row.original.id); setDeletingId(row.original.id) }}><Trash2 className="h-4 w-4" /></button>
        </div>
      ),
    }),
  ]

  return (
    <div>
      <PageHeader
        title="Products"
        subtitle={`${products.length} products`}
        actions={(
          <>
            <Button variant="secondary" onClick={() => toast.success('CSV exported from table action')}>Export CSV</Button>
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
        requireTyped={false}
        onConfirm={async () => {
          console.log('[DELETE] onConfirm fired, deletingId:', deletingId)
          try {
            const deletingProduct = products.find((p) => p.id === deletingId)
            const categoryToRefresh = deletingProduct?.category
            console.log('[DELETE] calling deleteProduct with id:', deletingId)
            await deleteProduct(deletingId)
            console.log('[DELETE] deleteProduct resolved, refreshing category:', categoryToRefresh)
            if (categoryToRefresh) await refreshCategory(categoryToRefresh)
            setDeletingId(null)
            toast.success('Product deleted')
          } catch (err) {
            console.error('[DELETE] onConfirm caught error:', err)
            toast.error(err?.message || 'Failed to delete product')
          }
        }}
        title="Delete Product"
        description="This will permanently delete the selected product. This action cannot be undone."
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
    </div>
  )
}
