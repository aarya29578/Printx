import { useMemo, useState } from 'react'
import { createColumnHelper } from '@tanstack/react-table'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import DataTable from '../../components/data/DataTable'
import Button from '../../components/ui/Button'
import StatusBadge from '../../components/ui/Badge'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import { useCouponsStore } from '../../store/couponsStore'
import { formatDate } from '../../core/utils/formatDate'

const columnHelper = createColumnHelper()

export default function CouponsPage() {
  const { coupons, toggle, deleteCoupon } = useCouponsStore()
  const [query, setQuery] = useState('')
  const [type, setType] = useState('all')

  const filtered = useMemo(() => coupons.filter((item) => {
    const q = query.toLowerCase()
    const byQ = item.code.toLowerCase().includes(q)
    const byT = type === 'all' || item.type === type
    return byQ && byT
  }), [coupons, query, type])

  const columns = [
    columnHelper.accessor('code', { header: 'Code', cell: (info) => <span className="rounded bg-gray-100 px-2 py-1 font-mono text-sm">{info.getValue()}</span> }),
    columnHelper.accessor('type', { header: 'Type' }),
    columnHelper.accessor('value', { header: 'Value' }),
    columnHelper.accessor('minOrder', { header: 'Min Order' }),
    columnHelper.display({ id: 'used', header: 'Used/Limit', cell: ({ row }) => `${row.original.usedCount} / ${row.original.usageLimit}` }),
    columnHelper.accessor('expiresAt', { header: 'Expiry', cell: (info) => formatDate(info.getValue()) }),
    columnHelper.accessor('status', { header: 'Status', cell: (info) => <StatusBadge status={info.getValue()} /> }),
    columnHelper.display({
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <Button size="sm" variant="secondary" onClick={() => { toggle(row.original.id); toast.success('Coupon status updated') }}>Toggle</Button>
          <Button size="sm" variant="danger" onClick={() => { deleteCoupon(row.original.id); toast.success('Coupon deleted') }}>Delete</Button>
        </div>
      ),
    }),
  ]

  return (
    <div className="space-y-4">
      <PageHeader title="Coupons & Offers" actions={<Button>Create Coupon</Button>} />
      <div className="flex flex-wrap gap-3">
        <Input className="w-72" placeholder="Search coupon code" value={query} onChange={(e) => setQuery(e.target.value)} />
        <Select className="w-44" value={type} onChange={(e) => setType(e.target.value)}>
          <option value="all">All types</option>
          <option value="flat">Flat</option>
          <option value="percentage">Percentage</option>
          <option value="free_shipping">Free Shipping</option>
        </Select>
      </div>
      <DataTable data={filtered} columns={columns} />
    </div>
  )
}
