import { useState } from 'react'
import { useParams } from 'react-router-dom'
import { Check, FileDown, Mail, MessageCircle, Palette } from 'lucide-react'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Card from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Input from '../../components/ui/Input'
import Textarea from '../../components/ui/Textarea'
import StatusBadge from '../../components/ui/Badge'
import { useOrdersStore } from '../../store/ordersStore'
import { formatDateTime } from '../../core/utils/formatDate'
import { formatINR } from '../../core/utils/formatCurrency'
import { generateInvoicePDF } from '../../core/utils/generatePDF'

export default function OrderDetailPage() {
  const { id } = useParams()
  const { orders, updateStatus, addAdminNote, updateTrackingNumber } = useOrdersStore()
  const [note, setNote] = useState('')
  const [tracking, setTracking] = useState('')
  const order = orders.find((o) => o.id === id) || orders[0]

  if (!order) return null

  return (
    <div className="space-y-6">
      <PageHeader
        title={`#${order.id}`}
        subtitle={`Placed on ${formatDateTime(order.date)}`}
        actions={(
          <>
            <Button variant="secondary" icon={FileDown} onClick={() => generateInvoicePDF(order)}>Print Invoice</Button>
            <Button variant="secondary" icon={Mail} onClick={() => window.open(`mailto:${order.customer.email}`)}>Contact Customer</Button>
          </>
        )}
      />

      <div className="grid gap-6 xl:grid-cols-3">
        <div className="space-y-6 xl:col-span-2">
          <Card>
            <h3 className="mb-4 font-semibold">Order Timeline</h3>
            <div className="space-y-4">
              {order.timeline.map((step) => (
                <div key={step.step} className="flex items-start gap-3">
                  <div className={`mt-1 grid h-6 w-6 place-items-center rounded-full border ${step.done ? 'border-green-600 bg-green-600 text-white' : 'border-gray-300 text-gray-400'}`}>
                    {step.done ? <Check className="h-4 w-4" /> : null}
                  </div>
                  <div>
                    <p className="font-medium">{step.step}</p>
                    <p className="text-sm text-gray-500">{step.time ? formatDateTime(step.time) : 'Pending'}</p>
                  </div>
                </div>
              ))}
            </div>
          </Card>

          <Card>
            <h3 className="mb-4 font-semibold">Order Items</h3>
            <div className="overflow-x-auto">
              <table className="min-w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-xs uppercase tracking-wider text-gray-500">
                    <th className="py-2">Product</th>
                    <th className="py-2">Specs</th>
                    <th className="py-2">Qty</th>
                    <th className="py-2">Unit</th>
                    <th className="py-2">Total</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td className="py-3">{order.product.name}</td>
                    <td className="py-3">{order.product.specs}</td>
                    <td className="py-3">{order.qty}</td>
                    <td className="py-3">{formatINR(order.amount / order.qty)}</td>
                    <td className="py-3 font-semibold">{formatINR(order.amount)}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </Card>

          <Card>
            <h3 className="mb-2 font-semibold">Internal Admin Notes</h3>
            <div className="space-y-2">
              {(order.adminNotes || []).map((entry, idx) => (
                <div key={idx} className="rounded-lg bg-gray-50 p-2 text-sm dark:bg-gray-700">
                  {typeof entry === 'string' ? (
                    <p>{entry}</p>
                  ) : (
                    <>
                      <p className="font-medium">{entry.text}</p>
                      <p className="text-xs text-gray-500">{entry.by} · {formatDateTime(entry.createdAt)}</p>
                    </>
                  )}
                </div>
              ))}
            </div>
            <Textarea className="mt-3" rows={3} value={note} onChange={(e) => setNote(e.target.value)} placeholder="Add internal note..." />
            <Button
              size="sm"
              className="mt-2"
              onClick={() => {
                if (!note.trim()) {
                  toast.error('Write a note first')
                  return
                }
                addAdminNote(order.id, note)
                setNote('')
                toast.success('Note added')
              }}
            >
              Add Note
            </Button>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <h3 className="mb-4 font-semibold">Order Summary</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between"><span>Order ID</span><span className="font-mono">{order.id}</span></div>
              <div className="flex justify-between"><span>Payment</span><span>{order.payment}</span></div>
              <div className="flex justify-between"><span>Status</span><StatusBadge status={order.status} /></div>
              <hr />
              <div className="flex justify-between"><span>Subtotal</span><span>{formatINR(order.amount * 0.82)}</span></div>
              <div className="flex justify-between"><span>GST</span><span>{formatINR(order.amount * 0.18)}</span></div>
              <div className="flex justify-between font-semibold"><span>Total</span><span>{formatINR(order.amount)}</span></div>
            </div>
          </Card>

          <Card>
            <h3 className="mb-2 font-semibold">Delivery Details</h3>
            <p className="text-sm text-gray-600">{order.address}</p>
            <p className="mt-2 text-sm">Delivery Type: <StatusBadge status={order.deliveryType.toLowerCase().replace(' ', '_')} /></p>
            <div className="mt-3 flex gap-2">
              <Input value={tracking} onChange={(e) => setTracking(e.target.value)} placeholder="Tracking number" />
              <Button variant="secondary" onClick={() => {
                if (!tracking.trim()) {
                  toast.error('Enter tracking number')
                  return
                }
                updateTrackingNumber(order.id, tracking)
                toast.success('Tracking saved')
              }}>Save</Button>
            </div>
            <Button className="mt-2 w-full" size="sm" onClick={() => toast.success('Tracking update sent')}>Send tracking update</Button>
          </Card>

          <Card>
            <h3 className="mb-2 font-semibold">Actions</h3>
            <div className="space-y-2">
              <select className="h-10 w-full rounded-xl border border-gray-200 px-3 text-sm" defaultValue={order.status} onChange={(e) => updateStatus(order.id, e.target.value)}>
                <option value="pending">Pending</option>
                <option value="design_review">Design Review</option>
                <option value="printing">Printing</option>
                <option value="shipped">Shipped</option>
                <option value="delivered">Delivered</option>
                <option value="cancelled">Cancelled</option>
              </select>
              <Button variant="secondary" className="w-full" icon={MessageCircle}>Contact Customer</Button>
              <Button variant="secondary" className="w-full" icon={Palette}>Request Design Change</Button>
              <Button variant="danger" className="w-full">Cancel & Refund</Button>
            </div>
          </Card>
        </div>
      </div>
    </div>
  )
}
