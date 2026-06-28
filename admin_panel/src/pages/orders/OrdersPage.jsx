import { useEffect, useMemo, useState } from 'react'
import { Eye } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { collection, getDocs } from 'firebase/firestore'
import PageHeader from '../../components/ui/PageHeader'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import Button from '../../components/ui/Button'
import StatusBadge from '../../components/ui/Badge'
import { db, isFirebaseConfigured } from '../../services/firebase'
import { formatINR } from '../../core/utils/formatCurrency'
import { formatDateTime } from '../../core/utils/formatDate'

const STATUS_OPTIONS = ['all', 'pending', 'design_review', 'printing', 'shipped', 'delivered', 'cancelled']

function safeString(v, fallback = '') {
  return typeof v === 'string' ? v : v == null ? fallback : String(v)
}

function safeNumber(v, fallback = 0) {
  if (typeof v === 'number' && Number.isFinite(v)) return v
  if (typeof v === 'string' && v.trim() !== '') {
    const n = Number(v)
    return Number.isFinite(n) ? n : fallback
  }
  return fallback
}

function normalizeDateValue(v) {
  // Flutter writes `createdAt: FieldValue.serverTimestamp()` which resolves to a Firestore Timestamp.
  // Also guard against JS Date / string.
  if (!v) return null
  if (typeof v === 'string') return v
  if (typeof v === 'number') return new Date(v).toISOString()
  if (v?.toDate && typeof v.toDate === 'function') return v.toDate().toISOString()
  if (v instanceof Date) return v.toISOString()
  return null
}

function isPdfFilenameOrUrl(nameOrUrl) {
  const s = safeString(nameOrUrl, '').toLowerCase()
  return s.endsWith('.pdf') || s.includes('.pdf?')
}

function ExtractOrderItems(orderDoc) {
  const items = Array.isArray(orderDoc?.items) ? orderDoc.items : []

  return items
    .filter((it) => it && typeof it === 'object')
    .map((it) => ({
      productId: safeString(it.productId, ''),
      productName: safeString(it.productName, ''),
      image: safeString(it.productImage ?? it.image, ''),
      category: safeString(it.category, ''),
      quantity: safeNumber(it.quantity, 0),

      // Customer customization (optional)
      customDesignUrl: safeString(it.customDesignUrl, ''),
      customDesignFileName: safeString(it.customDesignFileName, ''),
      customerInstructions: safeString(it.customerInstructions, ''),
    }))
}

function getOrderStatus(order) {
  return safeString(order?.status, 'pending')
}

export default function OrdersPage() {
  const navigate = useNavigate()
  const [orders, setOrders] = useState([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState(null)

  const [searchCustomer, setSearchCustomer] = useState('')
  const [searchProduct, setSearchProduct] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const [expandedProductKey, setExpandedProductKey] = useState(null)

  useEffect(() => {
    let cancelled = false

    async function load() {
      if (!isFirebaseConfigured || !db) {
        setOrders([])
        setIsLoading(false)
        setError('Firebase is not configured')
        return
      }

      setIsLoading(true)
      setError(null)

      try {
        const snapshot = await getDocs(collection(db, 'orders'))
        const docs = snapshot?.docs ?? []
        const loaded = docs
          .map((d) => ({ id: d.id, ...(d.data?.() ?? {}) }))
          .filter((x) => x && typeof x === 'object')

        if (!cancelled) setOrders(Array.isArray(loaded) ? loaded : [])
      } catch (e) {
        if (!cancelled) {
          setOrders([])
          setError(e?.message || 'Failed to load orders')
        }
      } finally {
        if (!cancelled) setIsLoading(false)
      }
    }

    load()
    return () => {
      cancelled = true
    }
  }, [])

  const stats = useMemo(() => {
    const totalOrders = orders.length
    const revenue = orders.reduce((sum, o) => sum + safeNumber(o?.totalAmount, 0), 0)
    return { totalOrders, revenue }
  }, [orders])

  const normalizedOrders = useMemo(() => {
    return orders.map((o) => {
      const customerName = safeString(o?.userName || o?.customer?.name, '')
      const email = safeString(o?.userEmail || o?.customer?.email, '')
      const phone = safeString(o?.userPhone || o?.customer?.phone, '')

      return {
        id: safeString(o?.orderId || o?.id, safeString(o?.id, '')),
        orderDocId: safeString(o?.id, ''),
        createdAt: normalizeDateValue(o?.createdAt),
        status: getOrderStatus(o),
        deliveryAddress: safeString(o?.deliveryAddress, ''),
        totalAmount: safeNumber(o?.totalAmount, 0),
        customer: { name: customerName, email, phone },
        items: ExtractOrderItems(o),
      }
    })
  }, [orders])

  const filteredOrders = useMemo(() => {
    const custQ = searchCustomer.trim().toLowerCase()
    const prodQ = searchProduct.trim().toLowerCase()

    return normalizedOrders.filter((o) => {
      if (statusFilter !== 'all' && o.status !== statusFilter) return false

      const customerHaystack = [o.customer.name, o.customer.email, o.customer.phone]
        .filter(Boolean)
        .join(' ')
        .toLowerCase()
      const matchesCustomer = custQ === '' || customerHaystack.includes(custQ)

      const productHaystack = o.items
        .map((it) => `${it.productName} ${it.productId} ${it.category}`.toLowerCase())
        .join(' ')
      const matchesProduct = prodQ === '' || productHaystack.includes(prodQ)

      return matchesCustomer && matchesProduct
    })
  }, [normalizedOrders, searchCustomer, searchProduct, statusFilter])

  const grouped = useMemo(() => {
    // Group orders by productId.
    const map = new Map()

    for (const o of filteredOrders) {
      for (const it of o.items) {
        const key = safeString(it.productId, `__missing__:${it.productName}`)
        if (!map.has(key)) {
          map.set(key, {
            key,
            productId: it.productId,
            productName: it.productName,
            category: it.category,
            image: it.image,
            customers: [],
            orders: [],
            totalOrders: new Set(),
            totalQty: 0,
            revenue: 0,
            latestCreatedAt: null,

          })
        }

        const entry = map.get(key)

        entry.totalOrders.add(o.orderDocId || o.id || '')
        entry.totalQty += safeNumber(it.quantity, 0)
        entry.revenue += safeNumber(o.totalAmount, 0)

        const createdAt = o.createdAt ? new Date(o.createdAt).toISOString() : null
        if (!entry.latestCreatedAt && createdAt) entry.latestCreatedAt = createdAt
        if (createdAt) {
          if (
            !entry.latestCreatedAt ||
            new Date(createdAt).getTime() > new Date(entry.latestCreatedAt).getTime()
          ) {
            entry.latestCreatedAt = createdAt
          }
        }

        // Customer granularity per product:
        // If the same customer ordered multiple times for the same product, we aggregate quantity + revenue + latest status.
        const customerKey = `${o.customer.name}|${o.customer.email}|${o.customer.phone}`
        // Build per-order row data so expansion renders one card per order (no customer aggregation)
        if (!entry.orders) entry.orders = []

        const orderDocId = safeString(o.orderDocId || o.id || '', '')
        const orderKey = `${orderDocId}::${key}`


        // NOTE: keep grouping logic intact; this only changes what we store for UI rendering.
        entry.orders.push({
          key: orderKey,

          // Order & customer
          orderId: orderDocId,
          orderDate: o.createdAt,
          orderDateISO: o.createdAt ? new Date(o.createdAt).toISOString() : null,
          status: o.status,
          paymentStatus: safeString(o?.paymentStatus, ''),
          paymentMethod: safeString(o?.paymentMethod, ''),

          name:
            safeString(o?.shippingName, '') ||
            safeString(o?.billingName, '') ||
            safeString(o?.userName, '') ||
            safeString(o?.customer?.name, '') ||
            safeString(o?.customer?.shippingName, ''),
          email:
            safeString(o?.userEmail, '') ||
            safeString(o?.customer?.email, '') ||
            safeString(o?.customer?.billingEmail, ''),
          phone:
            safeString(o?.userPhone, '') ||
            safeString(o?.customer?.phone, '') ||
            safeString(o?.customer?.mobile, ''),

          // Product (for this specific line item)
          productName: it.productName,
          category: it.category,
          unitPrice: safeNumber(it.unitPrice, safeNumber(o?.unitPrice, 0)),
          quantity: safeNumber(it.quantity, 0),
          totalPaid: safeNumber(o.totalAmount, 0),
          selectedSize: safeString(it.selectedSize, ''),
          selectedFinish: safeString(it.selectedFinish, ''),

          deliveryAddress: o.deliveryAddress,

          // Customer customization (optional)
          customDesignUrl: safeString(it.customDesignUrl, ''),
          customDesignFileName: safeString(it.customDesignFileName, ''),
          customerInstructions: safeString(it.customerInstructions, ''),
        })

        // Keep existing customer aggregation to avoid changing the rest of the grouping logic
        let cust = entry.customers.find((c) => c.key === customerKey)
        if (!cust) {
          cust = {
            key: customerKey,
            name: o.customer.name,
            email: o.customer.email,
            phone: o.customer.phone,
            quantity: 0,
            totalPaid: 0,
            status: o.status,
            deliveryAddress: o.deliveryAddress,
            orderDate: o.createdAt,
            createdAtISO: o.createdAt ? new Date(o.createdAt).toISOString() : null,

            // Custom design fields (we keep the latest non-empty values seen)
            customDesignUrl: '',
            customDesignFileName: '',
            customerInstructions: '',
          }
          entry.customers.push(cust)
        }

        cust.quantity += safeNumber(it.quantity, 0)
        cust.totalPaid += safeNumber(o.totalAmount, 0)
        cust.status = o.status
        cust.deliveryAddress = o.deliveryAddress

        // Keep customization from items (pick last seen non-empty)
        if (safeString(it.customDesignUrl, '')) {
          cust.customDesignUrl = it.customDesignUrl
          cust.customDesignFileName = it.customDesignFileName
        }
        if (safeString(it.customerInstructions, '')) {
          cust.customerInstructions = it.customerInstructions
        }

        if (o.createdAt) {
          const next = new Date(o.createdAt).toISOString()
          if (!cust.createdAtISO || new Date(next).getTime() >= new Date(cust.createdAtISO).getTime()) {
            cust.createdAtISO = next
            cust.orderDate = o.createdAt
          }
        }

      }
    }

    const arr = Array.from(map.values())
    arr.sort((a, b) => {
      const ta = a.latestCreatedAt ? new Date(a.latestCreatedAt).getTime() : 0
      const tb = b.latestCreatedAt ? new Date(b.latestCreatedAt).getTime() : 0
      return tb - ta
    })

    return arr.map((p) => ({
      ...p,
      totalOrders: p.totalOrders.size,
      customers: p.customers.sort((a, b) => {
        const ta = a.createdAtISO ? new Date(a.createdAtISO).getTime() : 0
        const tb = b.createdAtISO ? new Date(b.createdAtISO).getTime() : 0
        return tb - ta
      }),
      orders: (p.orders || []).sort((a, b) => {
        const ta = a.createdAtISO ? new Date(a.createdAtISO).getTime() : 0
        const tb = b.createdAtISO ? new Date(b.createdAtISO).getTime() : 0
        return tb - ta
      }),
    }))
  }, [filteredOrders])

  const hasEmpty = !isLoading && (!grouped || grouped.length === 0)

  return (
    <div className="space-y-4">
      <PageHeader
        title="Orders"
        subtitle={`${stats.totalOrders} total orders · Revenue ${formatINR(stats.revenue)}`}
        actions={(
          <Button variant="secondary">Refresh</Button>
        )}
      />

      <div className="flex flex-wrap gap-3">
        <Input
          className="w-80"
          placeholder="Search customer (name/email/phone)"
          value={searchCustomer}
          onChange={(e) => setSearchCustomer(e.target.value)}
        />
        <Input
          className="w-72"
          placeholder="Search product (name/category)"
          value={searchProduct}
          onChange={(e) => setSearchProduct(e.target.value)}
        />
        <Select className="w-52" value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
          {STATUS_OPTIONS.map((s) => (
            <option key={s} value={s}>
              {s === 'all' ? 'All statuses' : s.replaceAll('_', ' ')}
            </option>
          ))}
        </Select>
      </div>

      {isLoading ? (
        <div className="rounded-xl border border-gray-100 bg-white p-6">Loading orders…</div>
      ) : hasEmpty ? (
        <div className="rounded-xl border border-gray-100 bg-white p-6">
          <p className="font-medium">No orders found</p>
          {error ? <p className="mt-1 text-sm text-gray-500">{error}</p> : null}
        </div>
      ) : (
        <div className="space-y-3">
          {grouped.map((p) => {
            const productTotalRevenue = p.revenue
            const isExpanded = expandedProductKey === p.key

            return (
              <div key={p.key} className="rounded-xl border border-gray-100 bg-white">
                <button
                  type="button"
                  className="flex w-full items-center gap-4 px-4 py-3 text-left hover:bg-gray-50"
                  onClick={() => setExpandedProductKey(isExpanded ? null : p.key)}
                >
                  <div className="h-12 w-12 overflow-hidden rounded-lg bg-gray-50">
                    {p.image ? (
                      <img src={p.image} alt={p.productName || 'Product'} className="h-full w-full object-cover" />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center text-xs text-gray-400">No Image</div>
                    )}
                  </div>

                  <div className="min-w-0 flex-1">
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <p className="truncate font-semibold">{p.productName || 'Unnamed product'}</p>
                        <p className="truncate text-xs text-gray-500">{p.category || 'Uncategorized'}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-xs text-gray-500">Total Orders</p>
                        <p className="font-semibold">{p.totalOrders}</p>
                      </div>
                    </div>

                    <div className="mt-2 flex flex-wrap gap-x-6 gap-y-1 text-sm">
                      <div>
                        <span className="text-gray-500">Qty Sold: </span>
                        <span className="font-semibold">{p.totalQty}</span>
                      </div>
                      <div>
                        <span className="text-gray-500">Revenue: </span>
                        <span className="font-semibold">{formatINR(productTotalRevenue)}</span>
                      </div>
                      {p.latestCreatedAt ? (
                        <div>
                          <span className="text-gray-500">Latest: </span>
                          <span className="font-semibold">{formatDateTime(p.latestCreatedAt)}</span>
                        </div>
                      ) : null}
                    </div>
                  </div>
                </button>

                {isExpanded ? (
                  <div className="border-t border-gray-100 px-4 py-3">
                    {p.orders?.length === 0 ? (
                      <div className="text-sm text-gray-500">No customer details for this product.</div>
                    ) : (
                      <div className="space-y-3">
                        {p.orders.map((c, idx) => {
                          const hasDesign = !!safeString(c.customDesignUrl, '')

                          const designIsPdf = hasDesign && isPdfFilenameOrUrl(c.customDesignFileName || c.customDesignUrl)

                          return (
                            <div key={c.key || idx} className="rounded-lg bg-gray-50 p-3">
                              <div className="flex items-start justify-between gap-3">
                                <div className="min-w-0">
                                  <p className="truncate font-semibold">
                                    {safeString(c.name, '').trim() || 'Unknown Customer'}
                                  </p>
                                  <p className="truncate text-xs text-gray-500">{safeString(c.email, '') || '—'}</p>
                                  <p className="text-xs text-gray-500">Phone: {safeString(c.phone, '') || '—'}</p>
                                </div>
                                <div className="text-right">
                                  <StatusBadge status={c.status} />
                                  <p className="mt-1 text-xs text-gray-500">{c.orderDate ? formatDateTime(c.orderDate) : '—'}</p>
                                </div>
                              </div>

                              <div className="mt-3 grid gap-2 md:grid-cols-2">
                                <div>
                                  <p className="text-xs text-gray-500">Product</p>
                                  <p className="font-semibold">{safeString(c.productName, '') || '—'}</p>
                                  <p className="text-xs text-gray-500">{safeString(c.category, '') || '—'}</p>
                                </div>
                                <div>
                                  <p className="text-xs text-gray-500">Order ID</p>
                                  <p className="font-semibold">{safeString(c.orderId, '') || '—'}</p>
                                  <p className="text-xs text-gray-500">{safeString(c.paymentStatus, '') || '—'}</p>
                                </div>

                                <div>
                                  <p className="text-xs text-gray-500">Quantity</p>
                                  <p className="font-semibold">{c.quantity}</p>
                                </div>
                                <div>
                                  <p className="text-xs text-gray-500">Unit Price</p>
                                  <p className="font-semibold">{formatINR(c.unitPrice ?? 0)}</p>
                                </div>

                                <div>
                                  <p className="text-xs text-gray-500">Total Paid</p>
                                  <p className="font-semibold">{formatINR(c.totalPaid)}</p>
                                </div>
                                <div>
                                  <p className="text-xs text-gray-500">Payment Method</p>
                                  <p className="font-semibold">{safeString(c.paymentMethod, '') || '—'}</p>
                                </div>

                                <div>
                                  <p className="text-xs text-gray-500">Selected Size</p>
                                  <p className="font-semibold">{safeString(c.selectedSize, '') || '—'}</p>
                                </div>
                                <div>
                                  <p className="text-xs text-gray-500">Selected Finish</p>
                                  <p className="font-semibold">{safeString(c.selectedFinish, '') || '—'}</p>
                                </div>

                                <div className="md:col-span-2">
                                  <p className="text-xs text-gray-500">Delivery Address</p>
                                  <p className="break-words text-sm font-medium">{c.deliveryAddress || '—'}</p>
                                </div>
                              </div>

                              {hasDesign ? (
                                <div className="mt-3">
                                  <p className="text-xs font-semibold text-gray-700">Customer Uploaded Design</p>

                                  {designIsPdf ? (
                                    <div className="mt-2">
                                      <a
                                        href={c.customDesignUrl}
                                        target="_blank"
                                        rel="noreferrer"
                                        className="inline-flex items-center gap-2 rounded-md bg-white px-3 py-2 text-sm font-medium text-indigo-600 ring-1 ring-indigo-100 hover:bg-indigo-50"
                                      >
                                        <span className="text-red-600">PDF</span>
                                        <span className="max-w-[180px] truncate">{c.customDesignFileName || 'Download PDF'}</span>
                                      </a>
                                    </div>
                                  ) : (
                                    <div className="mt-2">
                                      <a href={c.customDesignUrl} target="_blank" rel="noreferrer">
                                        <img
                                          src={c.customDesignUrl}
                                          alt="Customer design"
                                          className="h-24 w-24 rounded-md object-cover ring-1 ring-gray-200"
                                        />
                                      </a>
                                    </div>
                                  )}

                                  {safeString(c.customerInstructions, '').trim() ? (
                                    <div className="mt-2">
                                      <p className="text-xs font-semibold text-gray-700">Instructions:</p>
                                      <p className="break-words text-sm text-gray-700">{c.customerInstructions}</p>
                                    </div>
                                  ) : null}
                                </div>
                              ) : null}
                            </div>
                          )
                        })}
                      </div>
                    )}
                  </div>
                ) : null}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

