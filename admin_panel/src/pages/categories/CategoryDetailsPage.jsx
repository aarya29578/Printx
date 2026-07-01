import { useEffect, useState, useMemo } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { collection, getDocs, query, where, deleteDoc, doc, updateDoc } from 'firebase/firestore'
import { Plus, Edit, Trash2, Eye, Copy, Search, Filter } from 'lucide-react'
import toast from 'react-hot-toast'
import { db, isFirebaseConfigured } from '../../services/firebase'
import { useCategoriesStore } from '../../store/categoriesStore'
import { useProductsStore } from '../../store/productsStore'
import PageHeader from '../../components/ui/PageHeader'
import Card from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import ConfirmDialog from '../../components/ui/ConfirmDialog'
import StatusBadge from '../../components/ui/Badge'
import { formatINR } from '../../core/utils/formatCurrency'
import { safeFormatDate } from '../../core/utils/safeFormatDate'

export default function CategoryDetailsPage() {
  const { categoryId } = useParams()
  const navigate = useNavigate()
  const { categories } = useCategoriesStore()
  const { products, deleteProduct } = useProductsStore()

  const [category, setCategory] = useState(null)
  const [categoryProducts, setCategoryProducts] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const [deleteId, setDeleteId] = useState(null)
  const [searchQuery, setSearchQuery] = useState('')
  const [sortBy, setSortBy] = useState('newest')
  const [filterStatus, setFilterStatus] = useState('all')

  // Load category details
  useEffect(() => {
    const cat = categories.find((c) => c.id === categoryId)
    if (!cat) {
      toast.error('Category not found')
      navigate('/categories')
      return
    }
    setCategory(cat)
  }, [categoryId, categories, navigate])

  // Load category products
  useEffect(() => {
    const loadProducts = async () => {
      setIsLoading(true)
      try {
        if (isFirebaseConfigured) {
          const q = query(collection(db, 'products'), where('category', '==', categoryId))
          const snapshot = await getDocs(q)
          const items = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }))
          setCategoryProducts(items)
        } else {
          // Fallback to store products
          const filtered = products.filter((p) => p.category === categoryId)
          setCategoryProducts(filtered)
        }
      } catch (error) {
        console.error('Failed to load products:', error)
        toast.error('Failed to load products')
      } finally {
        setIsLoading(false)
      }
    }
    loadProducts()
  }, [categoryId])

  // Filter and sort products
  const filtered = useMemo(() => {
    let items = [...categoryProducts]

    // Search filter
    if (searchQuery) {
      const q = searchQuery.toLowerCase()
      items = items.filter(
        (p) =>
          (p.name || '').toLowerCase().includes(q) ||
          (p.sku || '').toLowerCase().includes(q) ||
          (p.description || '').toLowerCase().includes(q),
      )
    }

    // Status filter
    if (filterStatus !== 'all') {
      items = items.filter((p) => p.status === filterStatus)
    }

    // Sorting
    if (sortBy === 'newest') {
      items.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0))
    } else if (sortBy === 'oldest') {
      items.sort((a, b) => new Date(a.createdAt || 0) - new Date(b.createdAt || 0))
    } else if (sortBy === 'price-low') {
      items.sort((a, b) => (a.basePrice || 0) - (b.basePrice || 0))
    } else if (sortBy === 'price-high') {
      items.sort((a, b) => (b.basePrice || 0) - (a.basePrice || 0))
    } else if (sortBy === 'name-asc') {
      items.sort((a, b) => (a.name || '').localeCompare(b.name || ''))
    }

    return items
  }, [categoryProducts, searchQuery, sortBy, filterStatus])

  const handleDeleteProduct = async () => {
    if (!deleteId) return

    try {
      await deleteProduct(deleteId)
      setCategoryProducts((prev) => prev.filter((p) => p.id !== deleteId))
      toast.success('Product deleted successfully')
      setDeleteId(null)
    } catch (error) {
      console.error('Failed to delete product:', error)
      toast.error('Failed to delete product')
    }
  }

  const handleDuplicateProduct = async (product) => {
    try {
      const newProduct = {
        ...product,
        name: `${product.name} (Copy)`,
        sku: `${product.sku}-COPY-${Date.now()}`,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      }
      delete newProduct.id

      if (isFirebaseConfigured) {
        const docId = `PRD${Date.now()}`
        await setDoc(doc(db, 'products', docId), newProduct)
        newProduct.id = docId
      }

      setCategoryProducts((prev) => [...prev, newProduct])
      toast.success('Product duplicated successfully')
    } catch (error) {
      console.error('Failed to duplicate product:', error)
      toast.error('Failed to duplicate product')
    }
  }

  if (isLoading && categoryProducts.length === 0) {
    return (
      <div className="space-y-4">
        <PageHeader title="Loading..." />
        <Card>
          <div className="py-12 text-center text-gray-500">Loading products...</div>
        </Card>
      </div>
    )
  }

  if (!category) {
    return (
      <div className="space-y-4">
        <PageHeader title="Category not found" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <PageHeader
            title={category.name}
            subtitle={`${filtered.length} products in this category`}
          />
        </div>
        <Button
          icon={Plus}
          onClick={() => navigate(`/products/add?category=${encodeURIComponent(categoryId)}`)}
        >
          Add Product
        </Button>
      </div>

      {/* Category Overview */}
      <div className="grid gap-5 md:grid-cols-3">
        <Card>
          <p className="text-sm text-gray-500">Total Products</p>
          <p className="text-3xl font-bold">{categoryProducts.length}</p>
        </Card>
        <Card>
          <p className="text-sm text-gray-500">Active Products</p>
          <p className="text-3xl font-bold">
            {categoryProducts.filter((p) => p.status === 'active').length}
          </p>
        </Card>
        <Card>
          <p className="text-sm text-gray-500">Status</p>
          <StatusBadge status={category.status} />
        </Card>
      </div>

      {/* Search, Sort, Filter */}
      <Card>
        <div className="grid gap-3 md:grid-cols-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <Input
              placeholder="Search by name, SKU, or description..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">Sort By</label>
            <Select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
              <option value="newest">Newest</option>
              <option value="oldest">Oldest</option>
              <option value="name-asc">Alphabetical</option>
              <option value="price-low">Price: Low → High</option>
              <option value="price-high">Price: High → Low</option>
            </Select>
          </div>
          <div>
            <label className="mb-1 block text-xs font-medium text-gray-600">Filter Status</label>
            <Select value={filterStatus} onChange={(e) => setFilterStatus(e.target.value)}>
              <option value="all">All</option>
              <option value="active">Active</option>
              <option value="draft">Draft</option>
              <option value="inactive">Inactive</option>
            </Select>
          </div>
          <div className="flex items-end gap-2">
            <Button
              variant="secondary"
              onClick={() => {
                setSearchQuery('')
                setSortBy('newest')
                setFilterStatus('all')
              }}
            >
              Reset Filters
            </Button>
          </div>
        </div>
      </Card>

      {/* Products Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead>
              <tr className="border-b text-left text-xs uppercase tracking-wider text-gray-500">
                <th className="py-3 px-4">Product</th>
                <th className="py-3 px-4">SKU</th>
                <th className="py-3 px-4">Price</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4">Created</th>
                <th className="py-3 px-4">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.length === 0 && (
                <tr>
                  <td className="py-6 px-4 text-center text-sm text-gray-500" colSpan={6}>
                    No products found
                  </td>
                </tr>
              )}
              {filtered.map((product) => (
                <tr key={product.id} className="border-b border-gray-100 text-sm hover:bg-gray-50 dark:hover:bg-gray-700">
                  <td className="py-3 px-4">
                    <div>
                      <p className="font-medium">{product.name}</p>
                      <p className="text-xs text-gray-500">{product.description || 'No description'}</p>
                    </div>
                  </td>
                  <td className="py-3 px-4 font-mono text-xs">{product.sku || '—'}</td>
                  <td className="py-3 px-4 font-semibold">{formatINR(product.basePrice || 0)}</td>
                  <td className="py-3 px-4">
                    <StatusBadge status={product.status} />
                  </td>
                  <td className="py-3 px-4 text-xs">{safeFormatDate(product.createdAt)}</td>
                  <td className="py-3 px-4">
                    <div className="flex gap-1">
                      <button
                        type="button"
                        title="View"
                        className="rounded p-2 hover:bg-gray-100 dark:hover:bg-gray-600"
                        onClick={() => navigate(`/products/${product.id}/edit`)}
                      >
                        <Eye className="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        title="Edit"
                        className="rounded p-2 hover:bg-gray-100 dark:hover:bg-gray-600"
                        onClick={() => navigate(`/products/${product.id}/edit`)}
                      >
                        <Edit className="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        title="Duplicate"
                        className="rounded p-2 hover:bg-blue-50 text-blue-600 dark:hover:bg-blue-900/20"
                        onClick={() => handleDuplicateProduct(product)}
                      >
                        <Copy className="h-4 w-4" />
                      </button>
                      <button
                        type="button"
                        title="Delete"
                        className="rounded p-2 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20"
                        onClick={() => setDeleteId(product.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <ConfirmDialog
        isOpen={Boolean(deleteId)}
        onClose={() => setDeleteId(null)}
        onConfirm={handleDeleteProduct}
        title="Delete Product"
        description="This action cannot be undone. The product will be permanently deleted from this category."
      />
    </div>
  )
}
