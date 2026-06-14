import { Inbox } from 'lucide-react'

export default function EmptyState({ title = 'No data found', description = 'Try changing filters or creating a new record.' }) {
  return (
    <div className="grid place-items-center gap-2 rounded-xl border border-dashed border-gray-300 py-10 text-center">
      <Inbox className="h-10 w-10 text-gray-400" />
      <p className="font-medium text-gray-700">{title}</p>
      <p className="text-sm text-gray-500">{description}</p>
    </div>
  )
}
