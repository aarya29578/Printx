import { Eye, Trash2 } from 'lucide-react'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Button from '../../components/ui/Button'
import Card from '../../components/ui/Card'
import StatusBadge from '../../components/ui/Badge'
import { useTemplatesStore } from '../../store/templatesStore'

export default function TemplatesPage() {
  const { templates, deleteTemplate } = useTemplatesStore()

  return (
    <div className="space-y-4">
      <PageHeader title="Design Templates" actions={<Button>Upload Template</Button>} />
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {templates.map((item) => (
          <Card key={item.id} className="p-0 overflow-hidden">
            <div className="group relative">
              <img src={item.thumbnail} alt={item.name} className="h-44 w-full object-cover" />
              <div className="absolute inset-0 flex items-center justify-center gap-2 bg-black/50 opacity-0 transition group-hover:opacity-100">
                <Button size="sm" variant="outline">Edit</Button>
                <Button size="sm" variant="outline" icon={Eye}>Preview</Button>
                <Button size="sm" variant="danger" icon={Trash2} onClick={() => { deleteTemplate(item.id); toast.success('Template deleted') }}>Delete</Button>
              </div>
            </div>
            <div className="p-3">
              <div className="flex items-center justify-between">
                <p className="text-sm font-medium">{item.name}</p>
                <StatusBadge status={item.status} />
              </div>
              <p className="mt-1 text-xs text-gray-500">Used {item.usageCount} times</p>
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}
