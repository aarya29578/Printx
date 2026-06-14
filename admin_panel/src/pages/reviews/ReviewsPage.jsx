import { useMemo, useState } from 'react'
import { createColumnHelper } from '@tanstack/react-table'
import { CheckCircle2, Flag, Trash2, XCircle } from 'lucide-react'
import toast from 'react-hot-toast'
import DataTable from '../../components/data/DataTable'
import PageHeader from '../../components/ui/PageHeader'
import Tabs from '../../components/ui/Tabs'
import StatusBadge from '../../components/ui/Badge'
import { useReviewsStore } from '../../store/reviewsStore'

const columnHelper = createColumnHelper()

export default function ReviewsPage() {
  const { reviews, approve, reject, flag, remove } = useReviewsStore()
  const [tab, setTab] = useState('all')

  const tabs = [
    { label: `All (${reviews.length})`, value: 'all' },
    { label: `Pending (${reviews.filter((r) => r.status === 'pending').length})`, value: 'pending' },
    { label: 'Approved', value: 'approved' },
    { label: 'Rejected', value: 'rejected' },
    { label: 'Flagged', value: 'flagged' },
  ]

  const data = useMemo(() => reviews.filter((item) => tab === 'all' || item.status === tab), [reviews, tab])

  const columns = [
    columnHelper.accessor((row) => row.customer.name, { id: 'customer', header: 'Customer' }),
    columnHelper.accessor((row) => row.product.name, { id: 'product', header: 'Product' }),
    columnHelper.accessor('rating', { header: 'Rating', cell: (info) => `★ ${info.getValue()}` }),
    columnHelper.accessor('text', { header: 'Review', cell: (info) => `${String(info.getValue()).slice(0, 80)}...` }),
    columnHelper.accessor('date', { header: 'Date' }),
    columnHelper.accessor('status', { header: 'Status', cell: (info) => <StatusBadge status={info.getValue()} /> }),
    columnHelper.display({
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <div className="flex items-center gap-1">
          <button type="button" title="Approve" onClick={() => { approve(row.original.id); toast.success('Review approved') }}><CheckCircle2 className="h-4 w-4 text-green-600" /></button>
          <button type="button" title="Reject" onClick={() => { reject(row.original.id); toast.success('Review rejected') }}><XCircle className="h-4 w-4 text-red-600" /></button>
          <button type="button" title="Flag" onClick={() => { flag(row.original.id); toast.success('Review flagged') }}><Flag className="h-4 w-4 text-amber-600" /></button>
          <button type="button" title="Delete" onClick={() => { remove(row.original.id); toast.success('Review deleted') }}><Trash2 className="h-4 w-4 text-red-600" /></button>
        </div>
      ),
    }),
  ]

  return (
    <div className="space-y-4">
      <PageHeader title="Reviews & Ratings" subtitle="Average Rating: 4.7 ★" />
      <Tabs tabs={tabs} active={tab} onChange={setTab} />
      <DataTable data={data} columns={columns} />
    </div>
  )
}
