import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { DndContext, closestCenter } from '@dnd-kit/core'
import { SortableContext, arrayMove, useSortable, verticalListSortingStrategy } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import {
  Briefcase,
  BookOpen,
  Coffee,
  CreditCard,
  Edit,
  Gift,
  GripVertical,
  Image,
  Mail,
  Package,
  Shirt,
  Stamp,
  Tag,
  FileText,
  Plus,
  Trash2,
} from 'lucide-react'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Card from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import StatusBadge from '../../components/ui/Badge'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import ConfirmDialog from '../../components/ui/ConfirmDialog'
import { useCategoriesStore } from '../../store/categoriesStore'

const iconOptions = [
  { value: 'credit-card', label: 'Credit Card', Icon: CreditCard },
  { value: 'shirt', label: 'Shirt', Icon: Shirt },
  { value: 'image', label: 'Image', Icon: Image },
  { value: 'coffee', label: 'Coffee', Icon: Coffee },
  { value: 'file', label: 'File', Icon: FileText },
  { value: 'book-open', label: 'Book', Icon: BookOpen },
  { value: 'stamp', label: 'Stamp', Icon: Stamp },
  { value: 'tag', label: 'Tag', Icon: Tag },
  { value: 'mail', label: 'Mail', Icon: Mail },
  { value: 'briefcase', label: 'Briefcase', Icon: Briefcase },
  { value: 'gift', label: 'Gift', Icon: Gift },
  { value: 'package', label: 'Package', Icon: Package },
]

const iconByName = Object.fromEntries(iconOptions.map((item) => [item.value, item.Icon]))

function SortableCategory({ item, onEdit, onDelete, onAddProduct, onViewProducts }) {
  const { attributes, listeners, setNodeRef, transform, transition } = useSortable({ id: item.id })
  const style = { transform: CSS.Transform.toString(transform), transition }
  const Icon = iconByName[item.icon] || Tag

  return (
    <div ref={setNodeRef} style={style} className="rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800">
      <button
        type="button"
        className="relative grid h-20 place-items-center rounded-t-xl text-white w-full text-left"
        style={{ background: item.color }}
        onClick={() => onViewProducts(item.id)}
      >
        <span
          className="absolute left-2 top-2 rounded bg-white/20 p-1 text-white"
          {...attributes}
          {...listeners}
        >
          <GripVertical className="h-4 w-4" />
        </span>
        <Icon className="h-7 w-7" />
      </button>

      <div className="p-4">
        <p className="font-medium dark:text-white">{item.name}</p>
        <p className="text-sm text-gray-500">{item.productCount} products</p>
        <div className="mt-3 flex items-center justify-between">
          <StatusBadge status={item.status} />
          <div className="flex gap-2">
            <button
              type="button"
              title="Add product"
              className="rounded p-1 text-primary-600 hover:bg-primary-50"
              onClick={() => onAddProduct(item)}
            >
              <Plus className="h-4 w-4" />
            </button>
            <button
              type="button"
              title="Edit"
              className="rounded p-1 hover:bg-gray-100 dark:hover:bg-gray-700"
              onClick={() => onEdit(item)}
            >
              <Edit className="h-4 w-4" />
            </button>
            <button
              type="button"
              title="Delete"
              className="rounded p-1 text-red-600 hover:bg-red-50"
              onClick={() => onDelete(item.id)}
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default function CategoriesPage() {
  const navigate = useNavigate()
  const { categories, reorderCategories, addCategory, updateCategory, deleteCategory } = useCategoriesStore()
  const [items, setItems] = useState(categories)
  const [open, setOpen] = useState(false)
  const [deleteId, setDeleteId] = useState(null)
  const [editing, setEditing] = useState(null)
  const [form, setForm] = useState({ name: '', color: '#4F46E5', status: 'active', productCount: 0, icon: 'credit-card' })

  useEffect(() => {
    setItems(categories)
  }, [categories])

  const openCreate = () => {
    setEditing(null)
    setForm({ name: '', color: '#4F46E5', status: 'active', productCount: 0, icon: 'credit-card' })
    setOpen(true)
  }

  const openEdit = (item) => {
    setEditing(item)
    setForm({
      name: item.name,
      color: item.color,
      status: item.status,
      productCount: item.productCount,
      icon: item.icon || 'credit-card',
    })
    setOpen(true)
  }

  const onSubmit = () => {
    if (!form.name.trim()) {
      toast.error('Category name is required')
      return
    }

    if (editing) {
      updateCategory(editing.id, { ...form, productCount: Number(form.productCount) || 0 })
      toast.success('Category updated')
    } else {
      addCategory({
        id: `cat-${Date.now()}`,
        ...form,
        productCount: Number(form.productCount) || 0,
      })
      toast.success('Category created')
    }

    setOpen(false)
  }

  return (
    <div className="space-y-4">
      <PageHeader title="Categories" actions={<Button onClick={openCreate}>Add Category</Button>} />
      <div className="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
        Drag cards to reorder how categories appear in the app.
      </div>

      <DndContext
        collisionDetection={closestCenter}
        onDragEnd={(event) => {
          const { active, over } = event
          if (!over || active.id === over.id) return
          const oldIndex = items.findIndex((item) => item.id === active.id)
          const newIndex = items.findIndex((item) => item.id === over.id)
          const next = arrayMove(items, oldIndex, newIndex)
          setItems(next)
          reorderCategories(next)
          toast.success('Category order updated')
        }}
      >
        <SortableContext items={items.map((item) => item.id)} strategy={verticalListSortingStrategy}>
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {items.map((item) => (
<SortableCategory
                key={item.id}
                item={item}
                onEdit={openEdit}
                onDelete={setDeleteId}
                onAddProduct={(category) => navigate(`/products/add?category=${encodeURIComponent(category.id)}`)}
                onViewProducts={(categoryId) => navigate(`/products?category=${encodeURIComponent(categoryId)}`)}
              />
            ))}
          </div>
        </SortableContext>
      </DndContext>

      <Card>
        <h3 className="mb-2 font-semibold dark:text-white">Tips</h3>
        <ul className="space-y-1 text-sm text-gray-600 dark:text-gray-300">
          <li>Use distinct colors for easier visual grouping in app navigation.</li>
          <li>Archive a category by setting status to inactive instead of deleting.</li>
        </ul>
      </Card>

      <Modal
        isOpen={open}
        onClose={() => setOpen(false)}
        title={editing ? 'Edit Category' : 'Create Category'}
        footer={(
          <div className="flex justify-end gap-2">
            <Button variant="secondary" onClick={() => setOpen(false)}>Cancel</Button>
            <Button onClick={onSubmit}>{editing ? 'Save Changes' : 'Create Category'}</Button>
          </div>
        )}
      >
        <div className="grid gap-3">
          <div>
            <label className="mb-1 block text-sm font-medium">Category Name</label>
            <Input value={form.name} onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))} />
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            <div>
              <label className="mb-1 block text-sm font-medium">Color</label>
              <Input type="color" value={form.color} onChange={(e) => setForm((p) => ({ ...p, color: e.target.value }))} className="h-11" />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium">Status</label>
              <Select value={form.status} onChange={(e) => setForm((p) => ({ ...p, status: e.target.value }))}>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </Select>
            </div>
          </div>
          <div>
            <label className="mb-2 block text-sm font-medium">Icon</label>
            <div className="grid grid-cols-3 gap-2 sm:grid-cols-4">
              {iconOptions.map(({ value, label, Icon }) => {
                const selected = form.icon === value
                return (
                  <button
                    key={value}
                    type="button"
                    onClick={() => setForm((p) => ({ ...p, icon: value }))}
                    className={`flex flex-col items-center gap-2 rounded-xl border p-3 text-xs transition ${selected ? 'border-primary-500 bg-primary-50 text-primary-700' : 'border-gray-200 hover:bg-gray-50 dark:border-gray-700 dark:hover:bg-gray-800'}`}
                  >
                    <Icon className="h-5 w-5" />
                    <span>{label}</span>
                  </button>
                )
              })}
            </div>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium">Product Count</label>
            <Input type="number" value={form.productCount} onChange={(e) => setForm((p) => ({ ...p, productCount: e.target.value }))} />
          </div>
        </div>
      </Modal>

      <ConfirmDialog
        isOpen={Boolean(deleteId)}
        onClose={() => setDeleteId(null)}
        onConfirm={() => {
          deleteCategory(deleteId)
          toast.success('Category deleted')
        }}
        title="Delete Category"
        description="This will remove the category from product organization."
      />
    </div>
  )
}
