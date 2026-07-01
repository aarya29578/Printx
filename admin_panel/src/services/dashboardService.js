import { collection, getDocs, query, where, onSnapshot } from 'firebase/firestore'
import { db, isFirebaseConfigured } from './firebase'
import { formatINR } from '../core/utils/formatCurrency'
import { safeConvertToDate } from '../core/utils/safeFormatDate'

/**
 * Dashboard Statistics Service
 * Provides real data from Firestore for dashboard metrics
 */

/**
 * Calculate revenue from completed/paid orders only
 * Filter orders with status: delivered or paid
 */
export const calculateRevenue = async () => {
  if (!isFirebaseConfigured) return 0

  try {
    const snapshot = await getDocs(collection(db, 'orders'))
    let total = 0

    snapshot.forEach((doc) => {
      const order = doc.data()
      // Include only successful/completed orders
      if (order.status === 'delivered' || order.paymentStatus === 'paid' || order.paymentStatus === 'completed') {
        const amount = order.totalAmount || order.amount || 0
        total += typeof amount === 'number' ? amount : 0
      }
    })

    return total
  } catch (error) {
    console.error('Failed to calculate revenue:', error)
    return 0
  }
}

/**
 * Get total count of orders from Firestore
 */
export const getOrdersCount = async () => {
  if (!isFirebaseConfigured) return 0

  try {
    const snapshot = await getDocs(collection(db, 'orders'))
    return snapshot.size
  } catch (error) {
    console.error('Failed to get orders count:', error)
    return 0
  }
}

/**
 * Get total count of products
 */
export const getProductsCount = async () => {
  if (!isFirebaseConfigured) return 0

  try {
    const snapshot = await getDocs(collection(db, 'products'))
    return snapshot.size
  } catch (error) {
    console.error('Failed to get products count:', error)
    return 0
  }
}

/**
 * Get total count of registered customers/users
 */
export const getCustomersCount = async () => {
  if (!isFirebaseConfigured) return 0

  try {
    const snapshot = await getDocs(collection(db, 'users'))
    return snapshot.size
  } catch (error) {
    console.error('Failed to get customers count:', error)
    return 0
  }
}

/**
 * Get orders count by status
 */
export const getOrdersByStatus = async () => {
  if (!isFirebaseConfigured) return []

  try {
    const snapshot = await getDocs(collection(db, 'orders'))
    const statusMap = {}

    snapshot.forEach((doc) => {
      const order = doc.data()
      const status = order.status || 'pending'
      statusMap[status] = (statusMap[status] || 0) + 1
    })

    // Map to chart data format with consistent naming
    const statusLabels = {
      pending: 'Pending',
      design_review: 'Design Review',
      printing: 'Printing',
      shipped: 'Shipped',
      delivered: 'Delivered',
      cancelled: 'Cancelled',
    }

    const statusColors = {
      pending: '#F59E0B',
      design_review: '#3B82F6',
      printing: '#8B5CF6',
      shipped: '#10B981',
      delivered: '#34D399',
      cancelled: '#EF4444',
    }

    return Object.entries(statusMap).map(([status, count]) => ({
      name: statusLabels[status] || status,
      value: count,
      color: statusColors[status] || '#6B7280',
    }))
  } catch (error) {
    console.error('Failed to get orders by status:', error)
    return []
  }
}

/**
 * Get revenue grouped by time period
 * Supports: day, week, month, year
 */
export const getRevenueByPeriod = async (period = 'month') => {
  if (!isFirebaseConfigured) return []

  try {
    const snapshot = await getDocs(collection(db, 'orders'))
    const revenueMap = {}

    snapshot.forEach((doc) => {
      const order = doc.data()
      // Only count successful orders
      if (order.status !== 'delivered' && order.paymentStatus !== 'paid') {
        return
      }

      const amount = order.totalAmount || order.amount || 0
      if (typeof amount !== 'number') return

      let key = ''
      const dateValue = safeConvertToDate(order.createdAt)
      const date = dateValue || new Date()

      if (period === 'day') {
        key = date.toISOString().split('T')[0] // YYYY-MM-DD
      } else if (period === 'week') {
        const weekStart = new Date(date)
        weekStart.setDate(date.getDate() - date.getDay())
        key = `Week of ${weekStart.toLocaleDateString('en-IN')}`
      } else if (period === 'month') {
        key = date.toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })
      } else if (period === 'year') {
        key = date.getFullYear().toString()
      }

      revenueMap[key] = (revenueMap[key] || 0) + amount
    })

    // Return as array of objects for chart
    return Object.entries(revenueMap).map(([period, revenue]) => ({
      period,
      revenue,
    }))
  } catch (error) {
    console.error('Failed to get revenue by period:', error)
    return []
  }
}

/**
 * Get latest orders from Firestore
 */
export const getLatestOrders = async (limit = 6) => {
  if (!isFirebaseConfigured) return []

  try {
    const snapshot = await getDocs(collection(db, 'orders'))
    const orders = []

    snapshot.forEach((doc) => {
      orders.push({ id: doc.id, ...doc.data() })
    })

    // Sort by createdAt descending and take the limit
    return orders
      .sort((a, b) => {
        const dateA = safeConvertToDate(a.createdAt) || new Date(0)
        const dateB = safeConvertToDate(b.createdAt) || new Date(0)
        return dateB.getTime() - dateA.getTime()
      })
      .slice(0, limit)
  } catch (error) {
    console.error('Failed to get latest orders:', error)
    return []
  }
}

/**
 * Get top selling products
 */
export const getTopSellingProducts = async (limit = 5) => {
  if (!isFirebaseConfigured) return []

  try {
    const snapshot = await getDocs(collection(db, 'orders'))
    const productMap = {}

    snapshot.forEach((doc) => {
      const order = doc.data()
      if (!order.items || !Array.isArray(order.items)) return

      order.items.forEach((item) => {
        const productId = item.productId || item.productName
        if (!productId) return

        if (!productMap[productId]) {
          productMap[productId] = {
            id: productId,
            name: item.productName || item.name || productId,
            orders: 0,
            revenue: 0,
          }
        }

        productMap[productId].orders += 1
        productMap[productId].revenue += (item.price || item.basePrice || 0) * (item.quantity || 1)
      })
    })

    return Object.values(productMap)
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, limit)
  } catch (error) {
    console.error('Failed to get top selling products:', error)
    return []
  }
}

/**
 * Get orders by category (for the category bar chart)
 */
export const getOrdersByCategory = async () => {
  if (!isFirebaseConfigured) return []

  try {
    const ordersSnapshot = await getDocs(collection(db, 'orders'))
    const categoriesSnapshot = await getDocs(collection(db, 'categories'))

    // Build category name map
    const categoryMap = {}
    categoriesSnapshot.forEach((doc) => {
      const cat = doc.data()
      categoryMap[doc.id] = cat.name
    })

    // Count orders by category
    const ordersByCategory = {}

    ordersSnapshot.forEach((doc) => {
      const order = doc.data()
      if (!order.items || !Array.isArray(order.items)) return

      order.items.forEach((item) => {
        const categoryId = item.category
        if (!categoryId) return

        const categoryName = categoryMap[categoryId] || 'Unknown'
        ordersByCategory[categoryName] = (ordersByCategory[categoryName] || 0) + 1
      })
    })

    return Object.entries(ordersByCategory).map(([category, orders]) => ({
      category,
      orders,
    }))
  } catch (error) {
    console.error('Failed to get orders by category:', error)
    return []
  }
}

/**
 * Subscribe to realtime dashboard updates
 * Calls callback whenever data changes
 */
export const subscribeToDashboardUpdates = (onUpdate) => {
  if (!isFirebaseConfigured) return () => {}

  const unsubscribers = []

  try {
    // Listen to orders collection
    unsubscribers.push(
      onSnapshot(collection(db, 'orders'), async (snapshot) => {
        const ordersCount = snapshot.size
        const revenue = await calculateRevenue()
        const ordersByStatus = await getOrdersByStatus()
        const latestOrders = await getLatestOrders()

        onUpdate({
          ordersCount,
          revenue,
          ordersByStatus,
          latestOrders,
        })
      }),
    )

    // Listen to products collection
    unsubscribers.push(
      onSnapshot(collection(db, 'products'), async (snapshot) => {
        const productsCount = snapshot.size
        onUpdate({ productsCount })
      }),
    )

    // Listen to users collection
    unsubscribers.push(
      onSnapshot(collection(db, 'users'), async (snapshot) => {
        const customersCount = snapshot.size
        onUpdate({ customersCount })
      }),
    )
  } catch (error) {
    console.error('Failed to setup realtime listeners:', error)
  }

  // Return unsubscribe function
  return () => {
    unsubscribers.forEach((unsub) => unsub())
  }
}

/**
 * Get all dashboard data at once (used for initial load)
 */
export const getDashboardStats = async (period = 'month') => {
  if (!isFirebaseConfigured) {
    return {
      revenue: 0,
      ordersCount: 0,
      productsCount: 0,
      customersCount: 0,
      ordersByStatus: [],
      latestOrders: [],
      topProducts: [],
      categoryBreakdown: [],
      revenueByPeriod: [],
    }
  }

  try {
    const [revenue, ordersCount, productsCount, customersCount, ordersByStatus, latestOrders, topProducts, categoryBreakdown, revenueByPeriod] = await Promise.all([
      calculateRevenue(),
      getOrdersCount(),
      getProductsCount(),
      getCustomersCount(),
      getOrdersByStatus(),
      getLatestOrders(6),
      getTopSellingProducts(5),
      getOrdersByCategory(),
      getRevenueByPeriod(period),
    ])

    return {
      revenue,
      ordersCount,
      productsCount,
      customersCount,
      ordersByStatus,
      latestOrders,
      topProducts,
      categoryBreakdown,
      revenueByPeriod,
    }
  } catch (error) {
    console.error('Failed to get dashboard stats:', error)
    return {
      revenue: 0,
      ordersCount: 0,
      productsCount: 0,
      customersCount: 0,
      ordersByStatus: [],
      latestOrders: [],
      topProducts: [],
      categoryBreakdown: [],
      revenueByPeriod: [],
    }
  }
}
