import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { DndContext, closestCenter } from '@dnd-kit/core'
import { SortableContext, arrayMove, useSortable, verticalListSortingStrategy } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { GripVertical, Pencil, Trash2, Plus } from 'lucide-react'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Card from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Toggle from '../../components/ui/Toggle'
import { useBannersStore } from '../../store/bannersStore'

function BannerRow({ item, onToggle, onEdit, onDelete }) {
  const { attributes, listeners, setNodeRef, transform, transition } = useSortable({ id: item.id })
  const style = { transform: CSS.Transform.toString(transform), transition }

  return (
    <div ref={setNodeRef} style={style} className="flex flex-wrap items-center gap-3 rounded-xl border border-gray-200 bg-white p-3">
      <button type="button" {...attributes} {...listeners} className="rounded p-1 hover:bg-gray-100" title="Drag"><GripVertical className="h-4 w-4" /></button>
      <div className="h-20 w-36 overflow-hidden rounded-xl bg-gray-100 text-white">
        {item.imageUrl ? (
          <img src={item.imageUrl} alt={item.title} className="h-full w-full object-cover" />
        ) : (
          <div className="flex h-full w-full items-end p-3" style={{ background: `linear-gradient(90deg, ${item.gradientFrom}, ${item.gradientTo})` }}>
            <p className="text-xs font-medium">{item.title}</p>
          </div>
        )}
      </div>
      <div className="min-w-0 flex-1">
        <p className="font-medium">{item.title}</p>
        <p className="text-sm text-gray-500">{item.subtitle}</p>
        <p className="text-xs text-gray-400">Links to: {item.linkTarget}</p>
      </div>
      <span className="rounded-full bg-primary-100 px-2 py-1 text-xs text-primary-700"># {item.position}</span>
      <Toggle checked={item.status === 'active'} onChange={onToggle} />
      <button type="button" title="Edit" onClick={onEdit} className="rounded p-1 hover:bg-gray-100"><Pencil className="h-4 w-4" /></button>
      <button type="button" title="Delete" onClick={onDelete} className="rounded p-1 text-red-600 hover:bg-red-50"><Trash2 className="h-4 w-4" /></button>
    </div>
  )
}

export default function BannersPage() {
  const navigate = useNavigate()
  const { banners, loadBanners, reorderBanners, updateBanner, deleteBanner } = useBannersStore()
  const [items, setItems] = useState(banners)

  useEffect(() => {
    loadBanners()
  }, [loadBanners])

  useEffect(() => {
    setItems(banners)
  }, [banners])

  return (
    <div className="space-y-4">
      <PageHeader
        title="Hero Banners"
        actions={
          <Button icon={Plus} onClick={() => navigate('/banners/add')}>
            Add Banner
          </Button>
        }
      />

      <Card>
        <h3 className="mb-2 font-semibold">Live App Preview</h3>
        <p className="mb-3 text-sm text-gray-500">This is how banners appear in the app</p>
        <div className="rounded-2xl bg-gray-900 p-4">
          <div className="relative h-40 overflow-hidden rounded-2xl text-white">
            {items[0]?.imageUrl ? (
              <img src={items[0].imageUrl} alt={items[0].title} className="h-full w-full object-cover" />
            ) : (
              <div className="h-full w-full" style={{ background: `linear-gradient(90deg, ${items[0]?.gradientFrom || '#4F46E5'}, ${items[0]?.gradientTo || '#7C3AED'})` }} />
            )}
            <div className="absolute inset-0 bg-black/40" />
            <div className="absolute inset-x-0 bottom-0 p-4">
              <p className="text-lg font-semibold">{items[0]?.title || 'Banner title'}</p>
              <p className="text-sm text-white/80">{items[0]?.subtitle || 'Banner subtitle'}</p>
            </div>
          </div>
        </div>
      </Card>

      <DndContext
        collisionDetection={closestCenter}
        onDragEnd={(event) => {
          const { active, over } = event
          if (!over || active.id === over.id) return
          const oldIndex = items.findIndex((item) => item.id === active.id)
          const newIndex = items.findIndex((item) => item.id === over.id)
          const next = arrayMove(items, oldIndex, newIndex).map((item, idx) => ({ ...item, position: idx + 1 }))
          setItems(next)
          reorderBanners(next)
          toast.success('Banner order updated')
        }}
      >
        <SortableContext items={items.map((item) => item.id)} strategy={verticalListSortingStrategy}>
          <div className="space-y-3">
            {items.map((item) => (
              <BannerRow
                key={item.id}
                item={item}
                onToggle={(checked) => {
                  const status = checked ? 'active' : 'inactive'
                  updateBanner(item.id, { status })
                  setItems((prev) => prev.map((b) => (b.id === item.id ? { ...b, status } : b)))
                }}
                onEdit={() => navigate(`/banners/${item.id}/edit`)}
                onDelete={() => {
                  deleteBanner(item.id)
                  toast.success('Banner deleted')
                }}
              />
            ))}
          </div>
        </SortableContext>
      </DndContext>
    </div>
  )
}
