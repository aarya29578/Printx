import { useMemo, useState } from 'react'
import { createColumnHelper } from '@tanstack/react-table'
import { Eye, Trash2 } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import DataTable from '../../components/data/DataTable'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import StatusBadge from '../../components/ui/Badge'
import ConfirmDialog from '../../components/ui/ConfirmDialog'
import { useCustomersStore } from '../../store/customersStore'
import { formatINR } from '../../core/utils/formatCurrency'

const columnHelper = createColumnHelper()

export default function CustomersPage() {
  const navigate = useNavigate()
  const { customers, toggleStatus, deleteCustomer } = useCustomersStore()
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState('all')
  const [city, setCity] = useState('all')
  const [deleteId, setDeleteId] = useState(null)

  const cities = [...new Set(customers.map((item) => item.city))]
  const filtered = useMemo(() => customers.filter((item) => {
    const q = query.toLowerCase()
    const byQuery = item.name.toLowerCase().includes(q) || item.email.toLowerCase().includes(q)
    const byStatus = status === 'all' || item.status === status
    const byCity = city === 'all' || item.city === city
    return byQuery && byStatus && byCity
  }), [customers, query, status, city])

  const columns = [
    columnHelper.accessor('name', {
      header: 'Customer',
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.name}</p>
          <p className="text-xs text-gray-500">Joined {row.original.joinedAt}</p>
        </div>
      ),
    }),
    columnHelper.accessor('email', { header: 'Email' }),
    columnHelper.accessor('phone', { header: 'Phone' }),
    columnHelper.accessor('city', { header: 'City' }),
    columnHelper.accessor('orders', { header: 'Orders' }),
    columnHelper.accessor('totalSpend', { header: 'Spend', cell: (info) => formatINR(info.getValue()) }),
    columnHelper.accessor('joinedAt', { header: 'Joined' }),
    columnHelper.accessor('status', { header: 'Status', cell: (info) => <StatusBadge status={info.getValue()} /> }),
    columnHelper.display({
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <button type="button" title="View" className="rounded p-1 hover:bg-gray-100" onClick={() => navigate(`/customers/${row.original.id}`)}><Eye className="h-4 w-4" /></button>
          <Button size="sm" variant="secondary" onClick={() => { toggleStatus(row.original.id); toast.success('Customer status updated') }}>
            {row.original.status === 'active' ? 'Block' : 'Unblock'}
          </Button>
          <button type="button" title="Delete" className="rounded p-1 text-red-600 hover:bg-red-50" onClick={() => setDeleteId(row.original.id)}><Trash2 className="h-4 w-4" /></button>
        </div>
      ),
    }),
  ]

  return (
    <div className="space-y-4">
      <PageHeader title="Customers" subtitle={`${customers.length} customers`} actions={<Button variant="secondary">Export CSV</Button>} />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {[
          ['Total', customers.length],
          ['New This Month', customers.filter((c) => c.joinedAt.startsWith('2024-05')).length],
          ['Active', customers.filter((c) => c.status === 'active').length],
          ['Blocked', customers.filter((c) => c.status === 'blocked').length],
        ].map((item) => (
          <div key={item[0]} className="rounded-xl border border-gray-100 bg-white p-4">
            <p className="text-sm text-gray-500">{item[0]}</p>
            <p className="text-xl font-semibold">{item[1]}</p>
          </div>
        ))}
      </div>

      <div className="flex flex-wrap gap-3">
        <Input className="w-72" placeholder="Search customers" value={query} onChange={(e) => setQuery(e.target.value)} />
        <Select className="w-44" value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="all">All status</option>
          <option value="active">Active</option>
          <option value="blocked">Blocked</option>
        </Select>
        <Select className="w-44" value={city} onChange={(e) => setCity(e.target.value)}>
          <option value="all">All cities</option>
          {cities.map((item) => <option key={item} value={item}>{item}</option>)}
        </Select>
      </div>

      <DataTable data={filtered} columns={columns} />

      <ConfirmDialog
        isOpen={Boolean(deleteId)}
        onClose={() => setDeleteId(null)}
        onConfirm={() => {
          deleteCustomer(deleteId)
          toast.success('Customer removed')
        }}
        title="Delete Customer"
        description="This will remove customer from admin records."
      />
    </div>
  )
}
