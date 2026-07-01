import { useEffect, useMemo, useState } from 'react'
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
import Avatar from '../../components/ui/Avatar'
import { useCustomersStore } from '../../store/customersStore'
import { formatINR } from '../../core/utils/formatCurrency'
import { safeFormatDate } from '../../core/utils/safeFormatDate'

const columnHelper = createColumnHelper()

export default function CustomersPage() {
  const navigate = useNavigate()
  const { customers, loadCustomers, subscribeToUpdates, toggleStatus, deleteCustomer } = useCustomersStore()
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState('all')
  const [city, setCity] = useState('all')
  const [deleteId, setDeleteId] = useState(null)
  const [isDeleting, setIsDeleting] = useState(false)

  // Load initial customers and subscribe to updates
  useEffect(() => {
    loadCustomers()
    const unsubscribe = subscribeToUpdates()
    return () => unsubscribe?.()
  }, [loadCustomers, subscribeToUpdates])

  const cities = useMemo(() => [...new Set(customers.map((item) => item.city).filter(Boolean))], [customers])

  const filtered = useMemo(() => customers.filter((item) => {
    const q = query.toLowerCase()
    const byQuery = (
      (item.name || '').toLowerCase().includes(q) ||
      (item.email || '').toLowerCase().includes(q) ||
      (item.phone || '').toLowerCase().includes(q)
    )
    const byStatus = status === 'all' || item.status === status
    const byCity = city === 'all' || item.city === city
    return byQuery && byStatus && byCity
  }), [customers, query, status, city])

  const stats = useMemo(() => {
    const active = customers.filter((c) => c.status === 'active').length
    const blocked = customers.filter((c) => c.status === 'blocked').length
    return { total: customers.length, active, blocked }
  }, [customers])

  const handleDelete = async () => {
    if (!deleteId) return
    setIsDeleting(true)
    try {
      const success = await deleteCustomer(deleteId)
      if (success) {
        toast.success('Customer deleted successfully')
        setDeleteId(null)
      } else {
        toast.error('Failed to delete customer')
      }
    } catch (error) {
      toast.error('Error deleting customer')
      console.error(error)
    } finally {
      setIsDeleting(false)
    }
  }

  const handleExportCSV = () => {
    if (filtered.length === 0) {
      toast.error('No customers to export')
      return
    }

    const headers = ['Name', 'Email', 'Phone', 'City', 'Orders', 'Total Spend', 'Status', 'Joined']
    const rows = filtered.map((c) => [
      c.name,
      c.email,
      c.phone,
      c.city,
      c.orders,
      c.totalSpend,
      c.status,
      c.joinedAt,
    ])

    const csv = [headers, ...rows].map((row) => row.map((cell) => `"${cell}"`).join(',')).join('\n')
    const blob = new Blob([csv], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `customers-${new Date().toISOString().split('T')[0]}.csv`
    document.body.appendChild(a)
    a.click()
    window.URL.revokeObjectURL(url)
    document.body.removeChild(a)
    toast.success('CSV exported successfully')
  }

  const columns = [
    columnHelper.accessor('name', {
      header: 'Customer',
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <Avatar name={row.original.name} src={row.original.profileImage} size="sm" />
          <div>
            <p className="font-medium">{row.original.name}</p>
            <p className="text-xs text-gray-500">Joined {row.original.joinedAt}</p>
          </div>
        </div>
      ),
    }),
    columnHelper.accessor('email', { header: 'Email' }),
    columnHelper.accessor('phone', { header: 'Phone' }),
    columnHelper.accessor('city', { header: 'City' }),
    columnHelper.accessor('orders', { header: 'Orders' }),
    columnHelper.accessor('totalSpend', { header: 'Spend', cell: (info) => formatINR(info.getValue()) }),
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
      <PageHeader title="Customers" subtitle={`${stats.total} customers`} actions={<Button variant="secondary" onClick={handleExportCSV}>Export CSV</Button>} />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {[
          ['Total', stats.total],
          ['Active', stats.active],
          ['Blocked', stats.blocked],
          ['Total Spend', formatINR(customers.reduce((sum, c) => sum + (c.totalSpend || 0), 0))],
        ].map((item) => (
          <div key={item[0]} className="rounded-xl border border-gray-100 bg-white p-4">
            <p className="text-sm text-gray-500">{item[0]}</p>
            <p className="text-xl font-semibold">{item[1]}</p>
          </div>
        ))}
      </div>

      <div className="flex flex-wrap gap-3">
        <Input className="w-72" placeholder="Search name, email, phone..." value={query} onChange={(e) => setQuery(e.target.value)} />
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
        isOpen={!!deleteId}
        title="Delete Customer"
        message="Are you sure you want to delete this customer? This action cannot be undone."
        onConfirm={handleDelete}
        onCancel={() => setDeleteId(null)}
        isLoading={isDeleting}
      />
    </div>
  )
}
