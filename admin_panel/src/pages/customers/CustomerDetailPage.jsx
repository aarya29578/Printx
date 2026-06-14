import { useParams } from 'react-router-dom'
import PageHeader from '../../components/ui/PageHeader'
import Card from '../../components/ui/Card'
import Tabs from '../../components/ui/Tabs'
import Avatar from '../../components/ui/Avatar'
import { useCustomersStore } from '../../store/customersStore'
import { formatINR } from '../../core/utils/formatCurrency'
import { useMemo, useState } from 'react'
import DataTable from '../../components/data/DataTable'
import { createColumnHelper } from '@tanstack/react-table'
import { formatDate } from '../../core/utils/formatDate'

const columnHelper = createColumnHelper()

export default function CustomerDetailPage() {
  const { id } = useParams()
  const [tab, setTab] = useState('overview')
  const customer = useCustomersStore((state) => state.customers.find((item) => item.id === id) || state.customers[0])
  const orders = useCustomersStore((state) => state.getCustomerOrders(customer?.name || ''))
  const designs = useMemo(() => [
    { id: 1, name: 'Business Card Front', updatedAt: '2024-05-18', preview: 'https://picsum.photos/seed/design-a/400/300' },
    { id: 2, name: 'Letterhead Corporate', updatedAt: '2024-05-10', preview: 'https://picsum.photos/seed/design-b/400/300' },
    { id: 3, name: 'Wedding Invite v2', updatedAt: '2024-04-29', preview: 'https://picsum.photos/seed/design-c/400/300' },
  ], [])

  const addresses = useMemo(() => [
    {
      id: 'addr-1',
      type: 'Home',
      person: customer?.name,
      line1: 'A-1204, Orchid Heights',
      line2: 'Andheri West',
      city: customer?.city,
      pincode: '400053',
      isDefault: true,
    },
    {
      id: 'addr-2',
      type: 'Office',
      person: `${customer?.name} (Office)`,
      line1: 'Unit 210, Trade Center',
      line2: 'Lower Parel',
      city: 'Mumbai',
      pincode: '400013',
      isDefault: false,
    },
  ], [customer?.city, customer?.name])

  const activity = useMemo(() => [
    { id: 1, action: 'Logged in from mobile app', at: '2024-05-26T10:30:00Z' },
    { id: 2, action: 'Placed order #ORD-10021', at: '2024-05-24T14:10:00Z' },
    { id: 3, action: 'Uploaded new print design', at: '2024-05-24T12:40:00Z' },
    { id: 4, action: 'Address updated', at: '2024-05-20T08:15:00Z' },
  ], [])

  const tabs = [
    { label: 'Overview', value: 'overview' },
    { label: 'Orders', value: 'orders' },
    { label: 'Designs', value: 'designs' },
    { label: 'Addresses', value: 'addresses' },
    { label: 'Activity', value: 'activity' },
  ]

  const columns = [
    columnHelper.accessor('id', { header: 'Order ID' }),
    columnHelper.accessor((row) => row.product.name, { id: 'product', header: 'Product' }),
    columnHelper.accessor('amount', { header: 'Amount', cell: (info) => formatINR(info.getValue()) }),
    columnHelper.accessor('status', { header: 'Status' }),
  ]

  return (
    <div className="space-y-6">
      <PageHeader title="Customer Detail" subtitle={customer?.name} />
      <div className="rounded-2xl bg-gradient-to-r from-primary-600 to-cyan-500 p-6 text-white">
        <div className="flex flex-wrap items-center gap-4">
          <Avatar name={customer?.name} size="lg" />
          <div>
            <h2 className="text-2xl font-bold">{customer?.name}</h2>
            <p className="text-white/80">{customer?.email}</p>
          </div>
          <span className="ml-auto rounded-full bg-white/20 px-3 py-1 text-sm">{customer?.status}</span>
        </div>
        <div className="mt-4 grid gap-3 sm:grid-cols-4">
          <div><p className="text-xs text-white/70">Orders</p><p className="text-xl font-semibold">{customer?.orders}</p></div>
          <div><p className="text-xs text-white/70">Total Spend</p><p className="text-xl font-semibold">{formatINR(customer?.totalSpend)}</p></div>
          <div><p className="text-xs text-white/70">Avg Order</p><p className="text-xl font-semibold">{formatINR((customer?.totalSpend || 0) / Math.max(1, customer?.orders || 1))}</p></div>
          <div><p className="text-xs text-white/70">Member Since</p><p className="text-xl font-semibold">{customer?.joinedAt}</p></div>
        </div>
      </div>

      <Tabs tabs={tabs} active={tab} onChange={setTab} />

      {tab === 'overview' && (
        <Card>
          <h3 className="mb-3 font-semibold">Overview</h3>
          <p className="text-sm text-gray-600">Customer has {customer?.addresses} saved addresses and recently placed {customer?.orders} orders.</p>
        </Card>
      )}
      {tab === 'orders' && <DataTable data={orders} columns={columns} emptyTitle="No orders yet" emptySubtitle="Orders placed by this customer will appear here." />}
      {tab === 'designs' && (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {designs.map((design) => (
            <Card key={design.id} className="overflow-hidden p-0">
              <img src={design.preview} alt={design.name} className="h-36 w-full object-cover" />
              <div className="p-3">
                <p className="font-medium dark:text-white">{design.name}</p>
                <p className="text-xs text-gray-500">Updated {formatDate(design.updatedAt)}</p>
              </div>
            </Card>
          ))}
        </div>
      )}
      {tab === 'addresses' && (
        <div className="grid gap-4 md:grid-cols-2">
          {addresses.map((address) => (
            <Card key={address.id}>
              <div className="flex items-center justify-between">
                <h3 className="font-semibold dark:text-white">{address.type}</h3>
                {address.isDefault && <span className="rounded-full bg-green-100 px-2 py-1 text-xs text-green-700">Default</span>}
              </div>
              <p className="mt-2 text-sm text-gray-700 dark:text-gray-200">{address.person}</p>
              <p className="text-sm text-gray-500">{address.line1}</p>
              <p className="text-sm text-gray-500">{address.line2}</p>
              <p className="text-sm text-gray-500">{address.city} - {address.pincode}</p>
            </Card>
          ))}
        </div>
      )}
      {tab === 'activity' && (
        <Card>
          <div className="space-y-4">
            {activity.map((event) => (
              <div key={event.id} className="flex gap-3">
                <span className="mt-1 h-2.5 w-2.5 rounded-full bg-primary-600" />
                <div>
                  <p className="text-sm font-medium dark:text-white">{event.action}</p>
                  <p className="text-xs text-gray-500">{new Date(event.at).toLocaleString()}</p>
                </div>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  )
}
