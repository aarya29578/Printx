import { useMemo, useState } from 'react'
import { createColumnHelper } from '@tanstack/react-table'
import { Eye, FileDown } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import toast from 'react-hot-toast'
import DataTable from '../../components/data/DataTable'
import PageHeader from '../../components/ui/PageHeader'
import StatusBadge from '../../components/ui/Badge'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import Button from '../../components/ui/Button'
import Tabs from '../../components/ui/Tabs'
import { useOrdersStore } from '../../store/ordersStore'
import { formatINR } from '../../core/utils/formatCurrency'
import { formatDateTime } from '../../core/utils/formatDate'
import { generateInvoicePDF } from '../../core/utils/generatePDF'

const columnHelper = createColumnHelper()

export default function OrdersPage() {
  const navigate = useNavigate()
  const { orders, updateStatus } = useOrdersStore()
  const [query, setQuery] = useState('')
  const [payment, setPayment] = useState('all')
  const [statusTab, setStatusTab] = useState('all')

  const tabs = [
    { label: `All (${orders.length})`, value: 'all' },
    { label: `Pending (${orders.filter((o) => o.status === 'pending').length})`, value: 'pending' },
    { label: `Design Review (${orders.filter((o) => o.status === 'design_review').length})`, value: 'design_review' },
    { label: `Printing (${orders.filter((o) => o.status === 'printing').length})`, value: 'printing' },
    { label: `Shipped (${orders.filter((o) => o.status === 'shipped').length})`, value: 'shipped' },
    { label: `Delivered (${orders.filter((o) => o.status === 'delivered').length})`, value: 'delivered' },
    { label: `Cancelled (${orders.filter((o) => o.status === 'cancelled').length})`, value: 'cancelled' },
  ]

  const filtered = useMemo(() => orders.filter((item) => {
    const q = query.toLowerCase()
    const matchesQuery = item.id.toLowerCase().includes(q) || item.customer.name.toLowerCase().includes(q)
    const matchesPayment = payment === 'all' || item.payment === payment
    const matchesStatus = statusTab === 'all' || item.status === statusTab
    return matchesQuery && matchesPayment && matchesStatus
  }), [orders, query, payment, statusTab])

  const columns = [
    columnHelper.accessor('id', {
      header: 'Order ID',
      cell: ({ row }) => <span className="font-mono font-medium text-primary-600">{row.original.id}</span>,
    }),
    columnHelper.display({
      id: 'customer',
      header: 'Customer',
      cell: ({ row }) => (
        <div>
          <p className="font-medium">{row.original.customer.name}</p>
          <p className="text-xs text-gray-500">{row.original.customer.phone}</p>
        </div>
      ),
    }),
    columnHelper.accessor((row) => row.product.name, {
      id: 'product',
      header: 'Product',
      cell: (info) => info.getValue(),
    }),
    columnHelper.accessor('qty', { header: 'Qty' }),
    columnHelper.accessor('amount', {
      header: 'Amount',
      cell: (info) => <span className="font-semibold">{formatINR(info.getValue())}</span>,
    }),
    columnHelper.accessor('payment', {
      header: 'Payment',
      cell: (info) => <span className="rounded-full bg-gray-100 px-2 py-1 text-xs">{info.getValue()}</span>,
    }),
    columnHelper.accessor('status', {
      header: 'Status',
      cell: (info) => <StatusBadge status={info.getValue()} />,
    }),
    columnHelper.accessor('date', {
      header: 'Date',
      cell: (info) => <span className="text-sm">{formatDateTime(info.getValue())}</span>,
    }),
    columnHelper.display({
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <div className="flex items-center gap-1">
          <button type="button" className="rounded p-1 hover:bg-gray-100" title="View" onClick={() => navigate(`/orders/${row.original.id}`)}><Eye className="h-4 w-4" /></button>
          <button type="button" className="rounded p-1 hover:bg-gray-100" title="Invoice" onClick={() => generateInvoicePDF(row.original)}><FileDown className="h-4 w-4" /></button>
          <Select className="h-8 w-32 text-xs" value={row.original.status} onChange={(e) => { updateStatus(row.original.id, e.target.value); toast.success('Order status updated') }}>
            <option value="pending">Pending</option>
            <option value="design_review">Design Review</option>
            <option value="printing">Printing</option>
            <option value="shipped">Shipped</option>
            <option value="delivered">Delivered</option>
            <option value="cancelled">Cancelled</option>
          </Select>
        </div>
      ),
    }),
  ]

  return (
    <div className="space-y-4">
      <PageHeader title="Orders" subtitle={`${orders.length} total orders`} actions={(
        <>
          <Button variant="secondary">Export CSV</Button>
          <Button variant="secondary">Export PDF</Button>
        </>
      )} />

      <div className="grid gap-3 md:grid-cols-5">
        {[
          ['New Today', 24, 'bg-indigo-100 text-indigo-700'],
          ['Printing', 89, 'bg-purple-100 text-purple-700'],
          ['Shipped', 134, 'bg-blue-100 text-blue-700'],
          ['Delivered', 892, 'bg-green-100 text-green-700'],
          ['Cancelled', 12, 'bg-red-100 text-red-700'],
        ].map((item) => (
          <div key={item[0]} className="rounded-xl border border-gray-100 bg-white p-3">
            <p className="text-xs text-gray-500">{item[0]}</p>
            <p className={`mt-1 inline-flex rounded-full px-2 py-0.5 text-sm font-semibold ${item[2]}`}>{item[1]}</p>
          </div>
        ))}
      </div>

      <Tabs tabs={tabs} active={statusTab} onChange={setStatusTab} />

      <div className="flex flex-wrap gap-3">
        <Input className="w-72" placeholder="Search order ID or customer" value={query} onChange={(e) => setQuery(e.target.value)} />
        <Select className="w-52" value={payment} onChange={(e) => setPayment(e.target.value)}>
          <option value="all">All payments</option>
          <option value="UPI">UPI</option>
          <option value="Card">Card</option>
          <option value="COD">COD</option>
          <option value="NetBanking">NetBanking</option>
        </Select>
      </div>

      <DataTable data={filtered} columns={columns} pageSize={10} />
    </div>
  )
}
