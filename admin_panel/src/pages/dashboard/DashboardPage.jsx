import { BarChart2, Download, Package, ShoppingBag, Users } from 'lucide-react'
import { useMemo, useState } from 'react'
import toast from 'react-hot-toast'
import { Link } from 'react-router-dom'
import PageHeader from '../../components/ui/PageHeader'
import Button from '../../components/ui/Button'
import Card from '../../components/ui/Card'
import StatCard from '../../components/data/StatCard'
import RevenueLineChart from '../../components/charts/RevenueLineChart'
import OrderDonutChart from '../../components/charts/OrderDonutChart'
import CategoryBarChart from '../../components/charts/CategoryBarChart'
import { mockDashboardStats, mockOrders, mockCustomers } from '../../data/mockData'
import { formatINR } from '../../core/utils/formatCurrency'
import { formatDate } from '../../core/utils/formatDate'
import StatusBadge from '../../components/ui/Badge'

export default function DashboardPage() {
  const [period, setPeriod] = useState('year')
  const stats = mockDashboardStats
  const recentOrders = useMemo(() => {
    if (period === 'month') return mockOrders.slice(0, 4)
    if (period === 'quarter') return mockOrders.slice(0, 5)
    return mockOrders.slice(0, 6)
  }, [period])
  const topCustomers = mockCustomers.slice(0, 5)

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        subtitle="Good morning, Rahul 👋"
        actions={(
          <>
            <span className="text-sm text-gray-500">{formatDate(new Date())}</span>
            <Button icon={Download} onClick={() => toast.success('Dashboard report downloaded')}>Download Report</Button>
          </>
        )}
      />

      <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        <StatCard index={0} title="Revenue" value={formatINR(stats.revenue.value)} growth={stats.revenue.growth} icon={BarChart2} iconBg="bg-primary-600" />
        <StatCard index={1} title="Orders" value={stats.orders.value.toLocaleString('en-IN')} growth={stats.orders.growth} icon={ShoppingBag} iconBg="bg-cyan-500" />
        <StatCard index={2} title="Products" value={stats.products.value.toLocaleString('en-IN')} growth={stats.products.growth} icon={Package} iconBg="bg-amber-500" />
        <StatCard index={3} title="Customers" value={stats.customers.value.toLocaleString('en-IN')} growth={stats.customers.growth} icon={Users} iconBg="bg-green-500" />
      </div>

      <div className="grid gap-5 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="font-semibold">Revenue Overview</h3>
            <select value={period} onChange={(e) => setPeriod(e.target.value)} className="rounded-lg border border-gray-200 px-2 py-1 text-sm dark:border-gray-700 dark:bg-gray-800">
              <option value="year">This Year</option>
              <option value="quarter">This Quarter</option>
              <option value="month">This Month</option>
            </select>
          </div>
          <RevenueLineChart data={stats.revenueChart} />
        </Card>

        <Card>
          <h3 className="mb-4 font-semibold">Orders by Status</h3>
          <OrderDonutChart data={stats.ordersByStatus} />
        </Card>
      </div>

      <div className="grid gap-5 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="font-semibold">Recent Orders</h3>
            <Link to="/orders" className="text-sm text-primary-600">View all →</Link>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr className="border-b text-left text-xs uppercase tracking-wider text-gray-500">
                  <th className="py-2">Order ID</th>
                  <th className="py-2">Customer</th>
                  <th className="py-2">Product</th>
                  <th className="py-2">Amount</th>
                  <th className="py-2">Status</th>
                  <th className="py-2">Date</th>
                </tr>
              </thead>
              <tbody>
                {recentOrders.length === 0 && (
                  <tr>
                    <td className="py-6 text-center text-sm text-gray-500" colSpan={6}>No orders found for selected period.</td>
                  </tr>
                )}
                {recentOrders.map((order) => (
                  <tr key={order.id} className="border-b border-gray-100 text-sm">
                    <td className="py-2 font-mono text-primary-600">{order.id}</td>
                    <td className="py-2">{order.customer.name}</td>
                    <td className="py-2">{order.product.name}</td>
                    <td className="py-2 font-semibold">{formatINR(order.amount)}</td>
                    <td className="py-2"><StatusBadge status={order.status} /></td>
                    <td className="py-2">{formatDate(order.date)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        <Card>
          <h3 className="mb-4 font-semibold">Top Selling</h3>
          <div className="space-y-4">
            {stats.topProducts.map((item, idx) => {
              const max = stats.topProducts[0].revenue
              const percent = (item.revenue / max) * 100
              return (
                <div key={item.name}>
                  <div className="mb-1 flex items-center gap-2">
                    <span className="grid h-6 w-6 place-items-center rounded-full bg-primary-600 text-xs text-white">{idx + 1}</span>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium">{item.name}</p>
                      <p className="text-xs text-gray-500">{item.orders} orders</p>
                    </div>
                    <p className="text-sm font-semibold">{formatINR(item.revenue)}</p>
                  </div>
                  <div className="h-1.5 rounded-full bg-gray-100">
                    <div className="h-full rounded-full bg-primary-600" style={{ width: `${percent}%` }} />
                  </div>
                </div>
              )
            })}
          </div>
        </Card>
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card>
          <h3 className="mb-4 font-semibold">Orders by Category</h3>
          <CategoryBarChart data={stats.categoryBreakdown} />
        </Card>

        <Card>
          <div className="mb-4 flex items-center justify-between">
            <h3 className="font-semibold">New Customers</h3>
            <Link to="/customers" className="text-sm text-primary-600">View all →</Link>
          </div>
          <div className="space-y-3">
            {topCustomers.map((customer) => (
              <div key={customer.id} className="flex items-center gap-3 rounded-xl border border-gray-100 p-3">
                <div className="grid h-9 w-9 place-items-center rounded-full bg-primary-600 text-xs font-semibold text-white">
                  {customer.name.split(' ').map((n) => n[0]).join('').slice(0, 2)}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">{customer.name}</p>
                  <p className="truncate text-xs text-gray-500">{customer.email}</p>
                </div>
                <span className="rounded-full bg-gray-100 px-2 py-1 text-xs">{customer.orders} orders</span>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  )
}
