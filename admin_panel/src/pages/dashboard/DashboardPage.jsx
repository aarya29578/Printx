import { BarChart2, Download, Package, ShoppingBag, Users } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import toast from 'react-hot-toast'
import { Link } from 'react-router-dom'
import PageHeader from '../../components/ui/PageHeader'
import Button from '../../components/ui/Button'
import Card from '../../components/ui/Card'
import StatCard from '../../components/data/StatCard'
import RevenueLineChart from '../../components/charts/RevenueLineChart'
import OrderDonutChart from '../../components/charts/OrderDonutChart'
import CategoryBarChart from '../../components/charts/CategoryBarChart'
import { getDashboardStats, getRevenueByPeriod, subscribeToDashboardUpdates } from '../../services/dashboardService'
import { formatINR } from '../../core/utils/formatCurrency'
import { safeFormatDate } from '../../core/utils/safeFormatDate'
import StatusBadge from '../../components/ui/Badge'

export default function DashboardPage() {
  const [period, setPeriod] = useState('month')
  const [isLoading, setIsLoading] = useState(true)
  const [stats, setStats] = useState({
    revenue: 0,
    ordersCount: 0,
    productsCount: 0,
    customersCount: 0,
    ordersByStatus: [],
    latestOrders: [],
    topProducts: [],
    categoryBreakdown: [],
    revenueByPeriod: [],
  })

  // Load initial stats
  useEffect(() => {
    const loadStats = async () => {
      setIsLoading(true)
      const data = await getDashboardStats(period)
      setStats(data)
      setIsLoading(false)
    }
    loadStats()
  }, [period])

  // Subscribe to realtime updates
  useEffect(() => {
    const unsubscribe = subscribeToDashboardUpdates((updates) => {
      setStats((prev) => ({ ...prev, ...updates }))
    })

    return () => unsubscribe()
  }, [])

  const recentOrders = stats.latestOrders || []
  const topCustomers = []

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        subtitle="Good morning, Rahul 👋"
        actions={(
          <>
            <span className="text-sm text-gray-500">{safeFormatDate(new Date())}</span>
            <Button icon={Download} onClick={() => toast.success('Dashboard report downloaded')}>Download Report</Button>
          </>
        )}
      />

      <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
        <StatCard
          index={0}
          title="Revenue"
          value={isLoading ? '—' : formatINR(stats.revenue)}
          growth={isLoading ? 0 : undefined}
          icon={BarChart2}
          iconBg="bg-primary-600"
        />
        <StatCard
          index={1}
          title="Orders"
          value={isLoading ? '—' : stats.ordersCount.toLocaleString('en-IN')}
          growth={isLoading ? 0 : undefined}
          icon={ShoppingBag}
          iconBg="bg-cyan-500"
        />
        <StatCard
          index={2}
          title="Products"
          value={isLoading ? '—' : stats.productsCount.toLocaleString('en-IN')}
          growth={isLoading ? 0 : undefined}
          icon={Package}
          iconBg="bg-amber-500"
        />
        <StatCard
          index={3}
          title="Customers"
          value={isLoading ? '—' : stats.customersCount.toLocaleString('en-IN')}
          growth={isLoading ? 0 : undefined}
          icon={Users}
          iconBg="bg-green-500"
        />
      </div>

      <div className="grid gap-5 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <div className="mb-4 flex items-center justify-between">
            <h3 className="font-semibold">Revenue Overview</h3>
            <select
              value={period}
              onChange={(e) => setPeriod(e.target.value)}
              className="rounded-lg border border-gray-200 px-2 py-1 text-sm dark:border-gray-700 dark:bg-gray-800"
            >
              <option value="day">Today</option>
              <option value="week">This Week</option>
              <option value="month">This Month</option>
              <option value="year">This Year</option>
            </select>
          </div>
          {isLoading ? (
            <div className="h-64 flex items-center justify-center text-gray-400">Loading revenue data...</div>
          ) : stats.revenueByPeriod && stats.revenueByPeriod.length > 0 ? (
            <RevenueLineChart data={stats.revenueByPeriod.map((item) => ({
              ...item,
              thisYear: item.revenue,
            }))} />
          ) : (
            <div className="h-64 flex items-center justify-center text-gray-400">No revenue data available</div>
          )}
        </Card>

        <Card>
          <h3 className="mb-4 font-semibold">Orders by Status</h3>
          {isLoading ? (
            <div className="h-64 flex items-center justify-center text-gray-400">Loading...</div>
          ) : stats.ordersByStatus && stats.ordersByStatus.length > 0 ? (
            <OrderDonutChart data={stats.ordersByStatus} />
          ) : (
            <div className="h-64 flex items-center justify-center text-gray-400">No data available</div>
          )}
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
                    <td className="py-6 text-center text-sm text-gray-500" colSpan={6}>
                      No orders found.
                    </td>
                  </tr>
                )}
                {recentOrders.map((order) => {
                  const customerName = order.userName || order.customer?.name || 'N/A'
                  const productName = order.items?.[0]?.productName || order.product?.name || 'N/A'
                  const amount = order.totalAmount || order.amount || 0
                  const orderDate = safeFormatDate(order.createdAt)

                  return (
                    <tr key={order.id} className="border-b border-gray-100 text-sm">
                      <td className="py-2 font-mono text-primary-600">{order.id}</td>
                      <td className="py-2">{customerName}</td>
                      <td className="py-2">{productName}</td>
                      <td className="py-2 font-semibold">{formatINR(amount)}</td>
                      <td className="py-2">
                        <StatusBadge status={order.status} />
                      </td>
                      <td className="py-2">{orderDate}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </Card>

        <Card>
          <h3 className="mb-4 font-semibold">Top Selling</h3>
          <div className="space-y-4">
            {stats.topProducts && stats.topProducts.length > 0 ? (
              stats.topProducts.map((item, idx) => {
                const max = stats.topProducts[0]?.revenue || 1
                const percent = ((item.revenue || 0) / max) * 100
                return (
                  <div key={item.id || idx}>
                    <div className="mb-1 flex items-center gap-2">
                      <span className="grid h-6 w-6 place-items-center rounded-full bg-primary-600 text-xs text-white">
                        {idx + 1}
                      </span>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-medium">{item.name}</p>
                        <p className="text-xs text-gray-500">{item.orders} orders</p>
                      </div>
                      <p className="text-sm font-semibold">{formatINR(item.revenue || 0)}</p>
                    </div>
                    <div className="h-1.5 rounded-full bg-gray-100">
                      <div className="h-full rounded-full bg-primary-600" style={{ width: `${percent}%` }} />
                    </div>
                  </div>
                )
              })
            ) : (
              <div className="py-4 text-center text-sm text-gray-500">No sales data available</div>
            )}
          </div>
        </Card>
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <Card>
          <h3 className="mb-4 font-semibold">Orders by Category</h3>
          {stats.categoryBreakdown && stats.categoryBreakdown.length > 0 ? (
            <CategoryBarChart data={stats.categoryBreakdown} />
          ) : (
            <div className="h-64 flex items-center justify-center text-gray-400">No category data available</div>
          )}
        </Card>

        <Card>
          <div className="mb-4 flex items-center justify-between">
            <h3 className="font-semibold">Dashboard Summary</h3>
            <Link to="/customers" className="text-sm text-primary-600">View all →</Link>
          </div>
          <div className="space-y-3 text-sm">
            <div className="flex justify-between rounded-lg bg-primary-50 p-3 dark:bg-primary-900/20">
              <span>Total Revenue</span>
              <span className="font-semibold">{formatINR(stats.revenue || 0)}</span>
            </div>
            <div className="flex justify-between rounded-lg bg-cyan-50 p-3 dark:bg-cyan-900/20">
              <span>Total Orders</span>
              <span className="font-semibold">{(stats.ordersCount || 0).toLocaleString('en-IN')}</span>
            </div>
            <div className="flex justify-between rounded-lg bg-amber-50 p-3 dark:bg-amber-900/20">
              <span>Total Products</span>
              <span className="font-semibold">{(stats.productsCount || 0).toLocaleString('en-IN')}</span>
            </div>
            <div className="flex justify-between rounded-lg bg-green-50 p-3 dark:bg-green-900/20">
              <span>Total Customers</span>
              <span className="font-semibold">{(stats.customersCount || 0).toLocaleString('en-IN')}</span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  )
}
