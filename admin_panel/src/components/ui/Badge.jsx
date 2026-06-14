import { cn } from '../../core/utils/cn'

const statusMap = {
  active: 'bg-green-100 text-green-700',
  delivered: 'bg-green-100 text-green-700',
  approved: 'bg-green-100 text-green-700',
  in_stock: 'bg-green-100 text-green-700',
  printing: 'bg-indigo-100 text-indigo-700',
  pending: 'bg-indigo-100 text-indigo-700',
  scheduled: 'bg-indigo-100 text-indigo-700',
  shipped: 'bg-blue-100 text-blue-700',
  draft: 'bg-gray-100 text-gray-600',
  inactive: 'bg-gray-100 text-gray-600',
  paused: 'bg-gray-100 text-gray-600',
  cancelled: 'bg-red-100 text-red-600',
  rejected: 'bg-red-100 text-red-600',
  out_of_stock: 'bg-red-100 text-red-600',
  warning: 'bg-amber-100 text-amber-700',
  low_stock: 'bg-amber-100 text-amber-700',
  flagged: 'bg-amber-100 text-amber-700',
}

export default function StatusBadge({ status }) {
  return (
    <span className={cn('rounded-full px-2.5 py-0.5 text-xs font-medium capitalize', statusMap[status] || 'bg-gray-100 text-gray-600')}>
      {String(status).replaceAll('_', ' ')}
    </span>
  )
}
