import {
  collection, getDocs, query, where, deleteDoc, doc, updateDoc, onSnapshot,
} from 'firebase/firestore'
import { db, isFirebaseConfigured } from './firebase'
import { safeConvertToDate, safeFormatDate } from '../core/utils/safeFormatDate'

/**
 * Customers Service
 * Provides real data from Firestore for customer management
 */

/**
 * Calculate order count and total spend for a user
 */
const calculateUserStats = async (userId) => {
  try {
    const ordersSnapshot = await getDocs(collection(db, 'orders'))
    let orderCount = 0
    let totalSpend = 0

    ordersSnapshot.forEach((doc) => {
      const order = doc.data()
      // Match by userId or uid field in order
      if (order.userId === userId || order.uid === userId || order.customer?.uid === userId) {
        orderCount += 1
        // Only count paid/delivered orders for total spend
        if (order.status === 'delivered' || order.paymentStatus === 'paid' || order.paymentStatus === 'completed') {
          const amount = order.totalAmount || order.amount || 0
          totalSpend += typeof amount === 'number' ? amount : 0
        }
      }
    })

    return { orderCount, totalSpend }
  } catch (error) {
    console.error('Error calculating user stats:', error)
    return { orderCount: 0, totalSpend: 0 }
  }
}

/**
 * Load all customers from Firestore 'users' collection
 */
export const readCustomersFromFirestore = async () => {
  if (!isFirebaseConfigured) return []

  try {
    const snapshot = await getDocs(collection(db, 'users'))
    const customers = []

    // Load all users first
    for (const userDoc of snapshot.docs) {
      const data = userDoc.data()
      const { orderCount, totalSpend } = await calculateUserStats(userDoc.id)

      customers.push({
        id: userDoc.id,
        uid: userDoc.id,
        name: data.fullName || data.name || 'Unknown',
        email: data.email || '',
        phone: data.phoneNumber || data.phone || '',
        address: data.address || '',
        city: data.city || 'Unknown',
        profileImage: data.profileImage || data.avatar || null,
        status: data.status || 'active',
        orders: orderCount,
        totalSpend,
        createdAt: data.createdAt || null,
        joinedAt: safeFormatDate(data.createdAt),
        ...data,
      })
    }

    return customers
  } catch (error) {
    console.error('Failed to load customers from Firestore:', error)
    return []
  }
}

/**
 * Get customer orders from Firestore
 */
export const getCustomerOrders = async (userId) => {
  if (!isFirebaseConfigured) return []

  try {
    const ordersSnapshot = await getDocs(collection(db, 'orders'))
    const customerOrders = []

    ordersSnapshot.forEach((doc) => {
      const order = doc.data()
      if (order.userId === userId || order.uid === userId || order.customer?.uid === userId) {
        customerOrders.push({
          id: doc.id,
          ...order,
        })
      }
    })

    return customerOrders
  } catch (error) {
    console.error('Error fetching customer orders:', error)
    return []
  }
}

/**
 * Update customer status in Firestore
 */
export const updateCustomerStatus = async (userId, newStatus) => {
  if (!isFirebaseConfigured) return false

  try {
    const userRef = doc(db, 'users', userId)
    await updateDoc(userRef, { status: newStatus })
    return true
  } catch (error) {
    console.error('Error updating customer status:', error)
    return false
  }
}

/**
 * Delete customer from Firestore
 */
export const deleteCustomerFromFirestore = async (userId) => {
  if (!isFirebaseConfigured) return false

  try {
    await deleteDoc(doc(db, 'users', userId))
    return true
  } catch (error) {
    console.error('Error deleting customer:', error)
    return false
  }
}

/**
 * Subscribe to real-time customer updates
 */
export const subscribeToCustomerUpdates = (callback) => {
  if (!isFirebaseConfigured) return () => {}

  const unsubscribe = onSnapshot(collection(db, 'users'), async (snapshot) => {
    const customers = []

    for (const userDoc of snapshot.docs) {
      const data = userDoc.data()
      const { orderCount, totalSpend } = await calculateUserStats(userDoc.id)

      customers.push({
        id: userDoc.id,
        uid: userDoc.id,
        name: data.fullName || data.name || 'Unknown',
        email: data.email || '',
        phone: data.phoneNumber || data.phone || '',
        address: data.address || '',
        city: data.city || 'Unknown',
        profileImage: data.profileImage || data.avatar || null,
        status: data.status || 'active',
        orders: orderCount,
        totalSpend,
        createdAt: data.createdAt || null,
        joinedAt: safeFormatDate(data.createdAt),
        ...data,
      })
    }

    callback(customers)
  }, (error) => {
    console.error('Error in customer updates subscription:', error)
  })

  return unsubscribe
}

/**
 * Get all cities from customers
 */
export const getCitiesFromCustomers = (customers) => {
  const cities = new Set(customers.map((c) => c.city).filter(Boolean))
  return Array.from(cities)
}
