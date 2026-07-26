import { useState, useEffect } from 'react'
import { useParams, Link, useNavigate } from 'react-router-dom'
import { getDoc, doc, onSnapshot } from 'firebase/firestore'
import {
  ChevronRight,
  Check,
  FileDown,
  Mail,
  Download,
  ZoomIn,
  X,
  ExternalLink,
  MapPin,
  Phone,
  User,
  Package,
  Truck,
  ClipboardList,
  MessageSquare,
  Clock,
  UserCheck,
  Wifi,
  WifiOff,
} from 'lucide-react'
import toast from 'react-hot-toast'
import Card from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'
import Textarea from '../../components/ui/Textarea'
import StatusBadge from '../../components/ui/Badge'
import { useOrdersStore } from '../../store/ordersStore'
import { useRidersStore } from '../../store/ridersStore'
import { db, isFirebaseConfigured } from '../../services/firebase'
import { formatINR } from '../../core/utils/formatCurrency'
import { safeFormatOrderDate, safeFormatOrderDateTime } from '../../core/utils/formatOrderDate'
import { generateInvoicePDF } from '../../core/utils/generatePDF'

// Canonical timeline stages with display labels
const TIMELINE_STAGES = [
  { key: 'pending',       label: 'Order Placed' },
  { key: 'design_review', label: 'Design Review' },
  { key: 'approved',      label: 'Design Approved' },
  { key: 'printing',      label: 'Printing' },
  { key: 'quality_check', label: 'Quality Check' },
  { key: 'packing',       label: 'Packing' },
  { key: 'shipped',       label: 'Shipped' },
  { key: 'delivered',     label: 'Delivered' },
]

const STATUS_ORDER = TIMELINE_STAGES.map((s) => s.key)

// Statuses that allow rider assignment
const ASSIGNABLE_STATUSES = [
  'accepted', 'confirmed', 'design_review', 'printing',
  'quality_check', 'shipped', 'dispatched',
]

// If the order already has a timeline array use it; otherwise derive from status.
function resolveTimeline(order) {
  if (Array.isArray(order.timeline) && order.timeline.length > 0) {
    return order.timeline
  }
  const statusIdx = STATUS_ORDER.indexOf(order.status)
  return TIMELINE_STAGES.map((stage, i) => ({
    step:  stage.label,
    key:   stage.key,
    done:  i <= Math.max(statusIdx, 0),
    time:  i === 0 ? (order.createdAt ?? null) : (i <= statusIdx ? (order.updatedAt ?? null) : null),
    note:  '',
  }))
}

// ─── Small reusable sub-components ───────────────────────────────────────────

function InfoRow({ icon, label, value }) {
  return (
    <div className="flex items-start gap-2">
      <span className="mt-0.5 flex-shrink-0 text-gray-400">{icon}</span>
      <div>
        <p className="text-xs text-gray-400">{label}</p>
        <p className="text-sm font-medium text-gray-800 dark:text-gray-200">{value || '—'}</p>
      </div>
    </div>
  )
}

function SummaryRow({ label, value }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-gray-500 dark:text-gray-400">{label}</span>
      <span className="text-gray-800 dark:text-gray-200">{value}</span>
    </div>
  )
}

// ─── Main component ───────────────────────────────────────────────────────────

export default function OrderDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { orders, updateStatus, addAdminNote, updateTrackingNumber, assignRider, unassignRider } = useOrdersStore()
  const { riders, loadRiders } = useRidersStore()

  const [note, setNote] = useState('')
  const [tracking, setTracking] = useState('')
  const [zoomImage, setZoomImage] = useState(null)
  const [customerProfile, setCustomerProfile] = useState(null)
  const [savingNote, setSavingNote] = useState(false)
  const [savingTracking, setSavingTracking] = useState(false)
  // Inline rider selection — replaces the modal approach
  const [selectedRiderId, setSelectedRiderId] = useState('')
  const [assigningRider, setAssigningRider] = useState(false)
  // Live Firestore subscription for this specific order document
  const [liveOrder, setLiveOrder] = useState(null)

  const order = orders.find((o) => o.id === id)

  // Fetch customer profile from Firestore users/{userId} (read-only)
  useEffect(() => {
    if (!order?.userId || !isFirebaseConfigured) return
    getDoc(doc(db, 'users', order.userId))
      .then((snap) => { if (snap.exists()) setCustomerProfile(snap.data()) })
      .catch(() => {})
  }, [order?.userId])

  // Load riders list
  useEffect(() => { loadRiders() }, [loadRiders])

  // Pre-fill tracking input if already set
  useEffect(() => {
    if (order?.trackingNumber) setTracking(order.trackingNumber)
  }, [order?.trackingNumber])

  // Direct real-time subscription to this order document.
  // This ensures the Assign Rider section updates instantly when the vendor
  // accepts — even if the admin had the page open before acceptance.
  useEffect(() => {
    if (!isFirebaseConfigured || !id) return
    const unsub = onSnapshot(
      doc(db, 'orders', id),
      (snap) => { if (snap.exists()) setLiveOrder({ id: snap.id, ...snap.data() }) },
      () => {},
    )
    return () => unsub()
  }, [id])

  if (!order) {
    return (
      <div className="flex flex-col items-center justify-center p-16 text-gray-500">
        <Package className="mb-3 h-10 w-10 text-gray-300" />
        <p className="mb-4">Order not found.</p>
        <Button variant="secondary" onClick={() => navigate('/orders')}>Back to Orders</Button>
      </div>
    )
  }

  // currentOrder uses the live Firestore document when available, falling back
  // to the store entry. This is used for all status/assignment checks so the
  // Assign Rider section reflects Firestore state in real time.
  const currentOrder = liveOrder ?? order

  const timeline        = resolveTimeline(order)
  const customerName    = customerProfile?.fullName    || order.userName       || '—'
  const customerEmail   = customerProfile?.email       || order.userEmail      || '—'
  const customerPhone   = customerProfile?.phoneNumber || order.userPhone      || '—'
  const customerAddress = customerProfile?.address     || order.deliveryAddress || '—'
  const customerImage   = customerProfile?.profileImage ?? null

  const isReadyToAssign = (
    currentOrder.vendorAccepted === true ||
    ASSIGNABLE_STATUSES.includes(currentOrder.status)
  )

  // Assign or re-assign a rider
  const handleAssignRider = async () => {
    if (!selectedRiderId) { toast.error('Please select a rider'); return }
    const riderDoc = riders.find((r) => r.id === selectedRiderId)
    if (!riderDoc) { toast.error('Rider not found'); return }
    setAssigningRider(true)
    try {
      await assignRider(currentOrder.id, {
        riderId:    riderDoc.id,
        riderName:  riderDoc.fullName || riderDoc.id,
      })
      toast.success(`Assigned to ${riderDoc.fullName || 'rider'}`)
      setSelectedRiderId('')
    } catch {
      toast.error('Failed to assign rider')
    } finally {
      setAssigningRider(false)
    }
  }

  const activeRiders = riders
    .filter((r) => !r.status || r.status === 'active')
    .sort((a, b) => (b.online ? 1 : 0) - (a.online ? 1 : 0))

  const riderSelectJSX = (
    <select
      value={selectedRiderId}
      onChange={(e) => setSelectedRiderId(e.target.value)}
      className="h-10 w-full rounded-xl border border-gray-200 px-3 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200"
    >
      <option value="">Select a rider…</option>
      {activeRiders.map((rider) => (
        <option key={rider.id} value={rider.id}>
          {rider.online ? '● ' : '○ '}{rider.fullName || rider.id}
          {rider.vehicleType ? ` · ${rider.vehicleType}` : ''}
        </option>
      ))}
    </select>
  )

  return (
    <div className="space-y-5">
      {/* Breadcrumb */}
      <nav className="flex flex-wrap items-center gap-1.5 text-sm text-gray-500">
        <Link to="/orders" className="hover:text-primary-600">Orders</Link>
        <ChevronRight className="h-3.5 w-3.5 flex-shrink-0" />
        <span className="font-medium text-gray-800 dark:text-gray-200">#{order.id}</span>
      </nav>

      {/* Page header */}
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <div className="flex flex-wrap items-center gap-3">
            <h1 className="text-xl font-bold text-gray-900 dark:text-white">Order #{order.id}</h1>
            <StatusBadge status={currentOrder.status} />
          </div>
          <p className="mt-1 text-sm text-gray-500">
            Placed on {safeFormatOrderDateTime(order.createdAt ?? order.date)}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button variant="secondary" icon={FileDown} onClick={() => generateInvoicePDF(order)}>
            Invoice
          </Button>
          {customerEmail !== '—' && (
            <Button
              variant="secondary"
              icon={Mail}
              onClick={() => window.open(`mailto:${customerEmail}`)}
            >
              Contact Customer
            </Button>
          )}
        </div>
      </div>

      <div className="grid gap-5 xl:grid-cols-3">
        {/* ──── Left column (2 of 3) ─────────────────────────────────────── */}
        <div className="space-y-5 xl:col-span-2">

          {/* Customer Information */}
          <Card>
            <div className="mb-4 flex items-center gap-2">
              <User className="h-4 w-4 text-primary-600" />
              <h3 className="font-semibold">Customer Information</h3>
            </div>
            <div className="flex gap-4">
              {customerImage ? (
                <img
                  src={customerImage}
                  alt={customerName}
                  className="h-14 w-14 flex-shrink-0 rounded-full border border-gray-200 object-cover"
                  onError={(e) => { e.currentTarget.style.display = 'none' }}
                />
              ) : (
                <div className="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-full border border-primary-100 bg-primary-50 text-xl font-bold text-primary-700">
                  {customerName?.[0]?.toUpperCase() ?? '?'}
                </div>
              )}
              <div className="grid flex-1 gap-2 sm:grid-cols-2">
                <InfoRow icon={<User  className="h-3.5 w-3.5" />} label="Full Name"    value={customerName}    />
                <InfoRow icon={<Mail  className="h-3.5 w-3.5" />} label="Email"        value={customerEmail}   />
                <InfoRow icon={<Phone className="h-3.5 w-3.5" />} label="Phone"        value={customerPhone}   />
                <InfoRow icon={<MapPin className="h-3.5 w-3.5" />} label="Address"     value={customerAddress} />
              </div>
            </div>
          </Card>

          {/* Order Items */}
          <Card>
            <div className="mb-4 flex items-center gap-2">
              <Package className="h-4 w-4 text-primary-600" />
              <h3 className="font-semibold">
                Order Items
                <span className="ml-2 rounded-full bg-gray-100 px-2 py-0.5 text-xs font-normal text-gray-500 dark:bg-gray-700">
                  {(order.items || []).length}
                </span>
              </h3>
            </div>

            <div className="space-y-4">
              {(order.items || []).map((item, idx) => (
                <div
                  key={idx}
                  className="rounded-xl border border-gray-100 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-800/50"
                >
                  <div className="flex gap-3">
                    {item.productImage ? (
                      <img
                        src={item.productImage}
                        alt={item.productName}
                        className="h-16 w-16 flex-shrink-0 rounded-lg border border-gray-200 object-cover"
                        onError={(e) => { e.currentTarget.style.display = 'none' }}
                      />
                    ) : (
                      <div className="flex h-16 w-16 flex-shrink-0 items-center justify-center rounded-lg bg-gray-200 dark:bg-gray-700">
                        <Package className="h-6 w-6 text-gray-400" />
                      </div>
                    )}

                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-gray-800 dark:text-white">{item.productName || '—'}</p>
                      <div className="mt-1 flex flex-wrap gap-x-4 gap-y-0.5 text-xs text-gray-500">
                        {item.size     && <span>Size: <strong className="text-gray-700 dark:text-gray-300">{item.size}</strong></span>}
                        {item.finish   && <span>Finish: <strong className="text-gray-700 dark:text-gray-300">{item.finish}</strong></span>}
                        {item.quantity && <span>Qty: <strong className="text-gray-700 dark:text-gray-300">{item.quantity}</strong></span>}
                        {item.price    && <span>Unit: <strong className="text-gray-700 dark:text-gray-300">{formatINR(item.price)}</strong></span>}
                        {item.quantity && item.price && (
                          <span>Subtotal: <strong className="text-gray-700 dark:text-gray-300">{formatINR(item.quantity * item.price)}</strong></span>
                        )}
                      </div>
                    </div>
                  </div>

                  {item.customerInstructions && (
                    <div className="mt-3 rounded-lg border border-amber-100 bg-amber-50 p-3 dark:border-amber-800/30 dark:bg-amber-900/20">
                      <p className="mb-1 text-xs font-semibold text-amber-700 dark:text-amber-400">Customer Instructions</p>
                      <p className="text-sm text-amber-900 dark:text-amber-200">{item.customerInstructions}</p>
                    </div>
                  )}

                  {item.customDesignUrl && (
                    <div className="mt-3">
                      <p className="mb-2 text-xs font-semibold text-gray-600 dark:text-gray-400">Uploaded Design</p>
                      <div className="flex items-start gap-3">
                        <button
                          type="button"
                          className="relative h-24 w-24 flex-shrink-0 overflow-hidden rounded-lg border border-gray-200 bg-gray-100 dark:border-gray-700 dark:bg-gray-700"
                          onClick={() => setZoomImage(item.customDesignUrl)}
                          title="Click to zoom"
                        >
                          <img
                            src={item.customDesignUrl}
                            alt="Customer design"
                            className="h-full w-full object-contain"
                            onError={(e) => { e.currentTarget.style.display = 'none' }}
                          />
                          <div className="absolute bottom-1 right-1 rounded bg-black/60 p-0.5">
                            <ZoomIn className="h-3 w-3 text-white" />
                          </div>
                        </button>

                        <div className="flex flex-col gap-1.5">
                          {item.customDesignFileName && (
                            <p className="text-xs text-gray-500 dark:text-gray-400 max-w-[180px] truncate">
                              {item.customDesignFileName}
                            </p>
                          )}
                          <a
                            href={item.customDesignUrl}
                            download={item.customDesignFileName || 'design'}
                            className="flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-medium transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700"
                          >
                            <Download className="h-3 w-3" /> Download
                          </a>
                          <a
                            href={item.customDesignUrl}
                            target="_blank"
                            rel="noreferrer"
                            className="flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-medium transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700"
                          >
                            <ExternalLink className="h-3 w-3" /> Open Full Image
                          </a>
                          <button
                            type="button"
                            onClick={() => setZoomImage(item.customDesignUrl)}
                            className="flex items-center gap-1.5 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-xs font-medium transition hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-800 dark:hover:bg-gray-700"
                          >
                            <ZoomIn className="h-3 w-3" /> Zoom
                          </button>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              ))}

              {(order.items || []).length === 0 && (
                <p className="text-sm text-gray-400">No items recorded for this order.</p>
              )}
            </div>
          </Card>

          {/* Timeline */}
          <Card>
            <div className="mb-5 flex items-center gap-2">
              <Clock className="h-4 w-4 text-primary-600" />
              <h3 className="font-semibold">Order Timeline</h3>
            </div>

            <div className="relative pl-3">
              <div className="absolute left-6 top-3 h-[calc(100%-1.5rem)] w-px bg-gray-200 dark:bg-gray-700" />

              <div className="space-y-5">
                {timeline.map((step, idx) => (
                  <div key={idx} className="flex gap-4">
                    <div
                      className={`relative z-10 mt-0.5 flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full border-2 transition-colors ${
                        step.done
                          ? 'border-green-500 bg-green-500 text-white'
                          : 'border-gray-300 bg-white text-gray-400 dark:border-gray-600 dark:bg-gray-900'
                      }`}
                    >
                      {step.done
                        ? <Check className="h-3.5 w-3.5" />
                        : <span className="text-[10px] font-semibold">{idx + 1}</span>}
                    </div>

                    <div className="flex-1 pb-1">
                      <div className="flex flex-wrap items-baseline gap-2">
                        <p className={`font-medium ${step.done ? 'text-gray-800 dark:text-white' : 'text-gray-400 dark:text-gray-500'}`}>
                          {step.step || step.label}
                        </p>
                        {step.done && step.time && (
                          <span className="text-xs text-gray-400">
                            {safeFormatOrderDateTime(step.time)}
                          </span>
                        )}
                        {!step.done && (
                          <span className="text-xs text-gray-300 dark:text-gray-600">Pending</span>
                        )}
                      </div>
                      {step.note && (
                        <p className="mt-0.5 text-xs text-gray-500 dark:text-gray-400">{step.note}</p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </Card>

          {/* Admin Notes */}
          <Card>
            <div className="mb-4 flex items-center gap-2">
              <MessageSquare className="h-4 w-4 text-primary-600" />
              <h3 className="font-semibold">Internal Admin Notes</h3>
            </div>

            <div className="space-y-2">
              {(order.adminNotes || []).length === 0 && (
                <p className="text-sm text-gray-400 dark:text-gray-500">No notes yet.</p>
              )}
              {(order.adminNotes || []).map((entry, idx) => (
                <div key={idx} className="rounded-lg bg-gray-50 p-3 text-sm dark:bg-gray-800">
                  {typeof entry === 'string' ? (
                    <p className="text-gray-800 dark:text-gray-200">{entry}</p>
                  ) : (
                    <>
                      <p className="text-gray-800 dark:text-gray-200">{entry.text}</p>
                      <p className="mt-1 text-xs text-gray-400">
                        {entry.by} · {safeFormatOrderDateTime(entry.createdAt)}
                      </p>
                    </>
                  )}
                </div>
              ))}
            </div>

            <div className="mt-4 space-y-2">
              <Textarea
                rows={3}
                value={note}
                onChange={(e) => setNote(e.target.value)}
                placeholder="Add an internal note visible only to admins…"
              />
              <Button
                size="sm"
                loading={savingNote}
                onClick={async () => {
                  if (!note.trim()) { toast.error('Write a note first'); return }
                  setSavingNote(true)
                  try {
                    await addAdminNote(order.id, note)
                    setNote('')
                    toast.success('Note added')
                  } catch {
                    toast.error('Failed to save note')
                  } finally {
                    setSavingNote(false)
                  }
                }}
              >
                Add Note
              </Button>
            </div>
          </Card>
        </div>

        {/* ──── Right column (1 of 3) ───────────────────────────────────── */}
        <div className="space-y-5">

          {/* Order Summary */}
          <Card>
            <div className="mb-4 flex items-center gap-2">
              <ClipboardList className="h-4 w-4 text-primary-600" />
              <h3 className="font-semibold">Order Summary</h3>
            </div>
            <div className="space-y-2.5 text-sm">
              <SummaryRow label="Order ID" value={<span className="font-mono text-xs">{order.id}</span>} />
              <SummaryRow label="Date"     value={safeFormatOrderDate(order.createdAt ?? order.date)} />
              <SummaryRow label="Payment"  value={order.payment || '—'} />
              <SummaryRow label="Status"   value={<StatusBadge status={currentOrder.status} />} />
              <hr className="border-gray-100 dark:border-gray-700" />
              <SummaryRow
                label="Total"
                value={
                  <span className="text-base font-bold text-gray-900 dark:text-white">
                    {formatINR(order.totalAmount ?? order.amount ?? 0)}
                  </span>
                }
              />
            </div>
          </Card>

          {/* Delivery & Tracking */}
          <Card>
            <div className="mb-4 flex items-center gap-2">
              <Truck className="h-4 w-4 text-primary-600" />
              <h3 className="font-semibold">Delivery & Tracking</h3>
            </div>

            <div className="space-y-3">
              <div className="flex items-start gap-2 text-sm">
                <MapPin className="mt-0.5 h-3.5 w-3.5 flex-shrink-0 text-gray-400" />
                <p className="text-gray-600 dark:text-gray-400">{order.deliveryAddress || customerAddress || '—'}</p>
              </div>

              {order.trackingNumber && (
                <div className="rounded-lg bg-gray-50 p-3 text-sm dark:bg-gray-800">
                  <p className="text-xs text-gray-500">Current Tracking Number</p>
                  <p className="mt-0.5 font-mono font-medium text-gray-800 dark:text-gray-200">
                    {order.trackingNumber}
                  </p>
                </div>
              )}

              <div className="flex gap-2">
                <Input
                  className="flex-1"
                  value={tracking}
                  onChange={(e) => setTracking(e.target.value)}
                  placeholder="Enter tracking number"
                />
                <Button
                  variant="secondary"
                  loading={savingTracking}
                  onClick={async () => {
                    if (!tracking.trim()) { toast.error('Enter tracking number'); return }
                    setSavingTracking(true)
                    try {
                      await updateTrackingNumber(order.id, tracking)
                      toast.success('Tracking saved')
                    } catch {
                      toast.error('Failed to save')
                    } finally {
                      setSavingTracking(false)
                    }
                  }}
                >
                  Save
                </Button>
              </div>
            </div>
          </Card>

          {/* Update Status */}
          <Card>
            <h3 className="mb-3 font-semibold">Update Status</h3>
            <select
              className="h-10 w-full rounded-xl border border-gray-200 px-3 text-sm dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200"
              value={currentOrder.status}
              onChange={(e) => {
                updateStatus(order.id, e.target.value)
                toast.success('Order status updated')
              }}
            >
              <option value="pending">Pending</option>
              <option value="accepted">Accepted (by Vendor)</option>
              <option value="design_review">Design Review</option>
              <option value="printing">Printing</option>
              <option value="quality_check">Quality Check</option>
              <option value="shipped">Shipped</option>
              <option value="assigned">Assigned to Rider</option>
              <option value="picked_up">Picked Up</option>
              <option value="out_for_delivery">Out for Delivery</option>
              <option value="delivered">Delivered</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </Card>

          {/* ── Assign Rider ─────────────────────────────────────────────── */}
          {/*
            Always rendered. Shows:
            - If rider already assigned: rider info + inline re-assign form
            - If ready to assign (vendor accepted): inline select + Assign Rider button
            - Otherwise: waiting message
          */}
          <Card>
            <div className="mb-3 flex items-center gap-2">
              <UserCheck className="h-4 w-4 text-primary-600" />
              <h3 className="font-semibold">
                {currentOrder.assignedRiderId ? 'Delivery Rider' : 'Assign Rider'}
              </h3>
            </div>

            {currentOrder.assignedRiderId ? (
              /* ── Rider already assigned ── */
              <div className="space-y-3">
                <div className="flex items-center gap-3 rounded-xl bg-green-50 p-3 dark:bg-green-900/20">
                  <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-green-600 font-bold text-white text-sm">
                    {(currentOrder.assignedRiderName?.[0] || '?').toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-semibold text-sm text-gray-800 dark:text-gray-100 truncate">
                      {currentOrder.assignedRiderName || currentOrder.assignedRiderId}
                    </p>
                    <p className="text-xs text-gray-500">Assigned rider</p>
                  </div>
                  {(() => {
                    const riderDoc = riders.find((r) => r.id === currentOrder.assignedRiderId)
                    return riderDoc?.online
                      ? <span className="flex items-center gap-1 text-xs text-green-600"><Wifi className="h-3 w-3" />Online</span>
                      : <span className="flex items-center gap-1 text-xs text-gray-400"><WifiOff className="h-3 w-3" />Offline</span>
                  })()}
                </div>

                <p className="text-xs font-medium text-gray-500">Reassign Rider</p>
                {riderSelectJSX}
                <div className="flex gap-2">
                  <Button
                    className="flex-1"
                    size="sm"
                    loading={assigningRider}
                    disabled={!selectedRiderId}
                    onClick={handleAssignRider}
                  >
                    Update Rider
                  </Button>
                  <Button
                    variant="secondary"
                    size="sm"
                    onClick={async () => {
                      try { await unassignRider(currentOrder.id); toast.success('Rider unassigned') }
                      catch { toast.error('Failed to unassign') }
                    }}
                  >
                    Remove
                  </Button>
                </div>
              </div>
            ) : isReadyToAssign ? (
              /* ── Vendor accepted — show inline assignment form ── */
              <div className="space-y-3">
                <p className="text-xs font-medium text-amber-600">
                  Vendor accepted · ready to assign a rider
                </p>
                <label className="block text-sm font-medium text-gray-600 dark:text-gray-400">
                  Select Rider
                </label>
                {riderSelectJSX}
                <Button
                  className="w-full"
                  loading={assigningRider}
                  disabled={!selectedRiderId}
                  onClick={handleAssignRider}
                >
                  Assign Rider
                </Button>
              </div>
            ) : (
              /* ── Pending vendor acceptance ── */
              <p className="text-sm text-gray-400">
                Waiting for vendor to accept before assigning a rider.
              </p>
            )}
          </Card>
        </div>
      </div>

      {/* Design zoom overlay */}
      {zoomImage && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/85 p-4"
          onClick={() => setZoomImage(null)}
        >
          <button
            type="button"
            className="absolute right-4 top-4 rounded-full bg-white/20 p-2 text-white transition hover:bg-white/30"
            onClick={() => setZoomImage(null)}
          >
            <X className="h-5 w-5" />
          </button>
          <img
            src={zoomImage}
            alt="Design zoom"
            className="max-h-[90vh] max-w-[90vw] rounded-xl object-contain shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          />
          <div className="absolute bottom-4 left-1/2 flex -translate-x-1/2 gap-3">
            <a
              href={zoomImage}
              download
              className="flex items-center gap-1.5 rounded-full bg-white/20 px-4 py-2 text-sm text-white backdrop-blur transition hover:bg-white/30"
              onClick={(e) => e.stopPropagation()}
            >
              <Download className="h-4 w-4" /> Download
            </a>
            <a
              href={zoomImage}
              target="_blank"
              rel="noreferrer"
              className="flex items-center gap-1.5 rounded-full bg-white/20 px-4 py-2 text-sm text-white backdrop-blur transition hover:bg-white/30"
              onClick={(e) => e.stopPropagation()}
            >
              <ExternalLink className="h-4 w-4" /> Open Full
            </a>
          </div>
        </div>
      )}
    </div>
  )
}
