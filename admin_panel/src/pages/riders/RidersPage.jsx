import { useEffect, useState } from 'react'
import { Bike, Edit2, Trash2, CheckCircle, XCircle, Wifi, WifiOff } from 'lucide-react'
import toast from 'react-hot-toast'
import Card from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import { useRidersStore } from '../../store/ridersStore'

// ─── Online badge ─────────────────────────────────────────────────────────────

function OnlineBadge({ online }) {
  return online
    ? <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-700"><Wifi className="h-3 w-3" />Online</span>
    : <span className="inline-flex items-center gap-1 rounded-full bg-gray-100 px-2.5 py-0.5 text-xs font-medium text-gray-500"><WifiOff className="h-3 w-3" />Offline</span>
}

function StatusBadge({ status }) {
  const isActive = !status || status === 'active'
  return isActive
    ? <span className="rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-700">Active</span>
    : <span className="rounded-full bg-red-100 px-2.5 py-0.5 text-xs font-medium text-red-600">Disabled</span>
}

// ─── Edit Rider Modal ─────────────────────────────────────────────────────────

function EditRiderModal({ rider, onClose }) {
  const updateRider = useRidersStore((s) => s.updateRider)
  const [form, setForm] = useState({
    fullName: rider.fullName || '',
    phoneNumber: rider.phoneNumber || '',
    vehicleType: rider.vehicleType || '',
    vehicleNumber: rider.vehicleNumber || '',
  })
  const [saving, setSaving] = useState(false)

  const handleSave = async () => {
    setSaving(true)
    try {
      await updateRider(rider.id, form)
      toast.success('Rider updated')
      onClose()
    } catch {
      toast.error('Failed to update rider')
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal isOpen title="Edit Rider" onClose={onClose}
      footer={
        <div className="flex justify-end gap-2">
          <Button variant="secondary" onClick={onClose}>Cancel</Button>
          <Button loading={saving} onClick={handleSave}>Save Changes</Button>
        </div>
      }
    >
      <div className="space-y-3">
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Full Name</label>
          <Input value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} />
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Phone Number</label>
          <Input value={form.phoneNumber} onChange={(e) => setForm({ ...form, phoneNumber: e.target.value })} />
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Vehicle Type</label>
          <Input placeholder="e.g. Bike, Scooter" value={form.vehicleType} onChange={(e) => setForm({ ...form, vehicleType: e.target.value })} />
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Vehicle Number</label>
          <Input placeholder="e.g. MH12AB1234" value={form.vehicleNumber} onChange={(e) => setForm({ ...form, vehicleNumber: e.target.value })} />
        </div>
      </div>
    </Modal>
  )
}

// ─── Rider Row ────────────────────────────────────────────────────────────────

function RiderRow({ rider }) {
  const { setRiderStatus, deleteRider } = useRidersStore()
  const [editOpen, setEditOpen] = useState(false)
  const isActive = !rider.status || rider.status === 'active'

  const handleToggleStatus = async () => {
    try {
      await setRiderStatus(rider.id, isActive ? 'disabled' : 'active')
      toast.success(isActive ? 'Rider disabled' : 'Rider enabled')
    } catch {
      toast.error('Failed to update status')
    }
  }

  const handleDelete = async () => {
    if (!window.confirm(`Delete rider ${rider.fullName}? This cannot be undone.`)) return
    try {
      await deleteRider(rider.id)
      toast.success('Rider deleted')
    } catch {
      toast.error('Failed to delete rider')
    }
  }

  return (
    <>
      <tr className="border-b border-gray-100 transition-colors hover:bg-gray-50/50 dark:border-gray-800 dark:hover:bg-gray-800/30">
        {/* Rider */}
        <td className="px-4 py-3">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-primary-100 font-semibold text-primary-700 dark:bg-primary-900/30 dark:text-primary-400">
              {(rider.fullName?.[0] || '?').toUpperCase()}
            </div>
            <div>
              <p className="font-medium text-gray-800 dark:text-gray-100">{rider.fullName || '—'}</p>
              <p className="text-xs text-gray-400">{rider.email || '—'}</p>
            </div>
          </div>
        </td>
        {/* Phone */}
        <td className="px-4 py-3 text-sm text-gray-600 dark:text-gray-300">{rider.phoneNumber || '—'}</td>
        {/* Vehicle */}
        <td className="px-4 py-3">
          <p className="text-sm font-medium text-gray-700 dark:text-gray-200">{rider.vehicleType || '—'}</p>
          <p className="text-xs text-gray-400">{rider.vehicleNumber || ''}</p>
        </td>
        {/* Online */}
        <td className="px-4 py-3"><OnlineBadge online={rider.online} /></td>
        {/* Status */}
        <td className="px-4 py-3"><StatusBadge status={rider.status} /></td>
        {/* Actions */}
        <td className="px-4 py-3">
          <div className="flex items-center gap-1">
            <button
              type="button"
              title="Edit"
              onClick={() => setEditOpen(true)}
              className="rounded-lg p-1.5 text-gray-400 transition hover:bg-gray-100 hover:text-primary-600 dark:hover:bg-gray-700"
            >
              <Edit2 className="h-4 w-4" />
            </button>
            <button
              type="button"
              title={isActive ? 'Disable' : 'Enable'}
              onClick={handleToggleStatus}
              className={`rounded-lg p-1.5 transition ${isActive ? 'text-gray-400 hover:bg-red-50 hover:text-red-500' : 'text-gray-400 hover:bg-green-50 hover:text-green-600'} dark:hover:bg-gray-700`}
            >
              {isActive ? <XCircle className="h-4 w-4" /> : <CheckCircle className="h-4 w-4" />}
            </button>
            <button
              type="button"
              title="Delete"
              onClick={handleDelete}
              className="rounded-lg p-1.5 text-gray-400 transition hover:bg-red-50 hover:text-red-500 dark:hover:bg-gray-700"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        </td>
      </tr>
      {editOpen && <EditRiderModal rider={rider} onClose={() => setEditOpen(false)} />}
    </>
  )
}

// ─── Main Page ────────────────────────────────────────────────────────────────

export default function RidersPage() {
  const { riders, hasLoaded, isLoading, loadRiders } = useRidersStore()

  useEffect(() => {
    loadRiders()
  }, [loadRiders])

  const online = riders.filter((r) => r.online === true).length
  const active = riders.filter((r) => !r.status || r.status === 'active').length

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">Riders</h1>
          <p className="mt-0.5 text-sm text-gray-500">
            {riders.length} total · {online} online · {active} active
          </p>
        </div>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {[
          { label: 'Total Riders', value: riders.length, color: 'text-gray-800 dark:text-white' },
          { label: 'Online Now', value: online, color: 'text-green-600' },
          { label: 'Active', value: active, color: 'text-primary-600' },
          { label: 'Disabled', value: riders.filter((r) => r.status === 'disabled').length, color: 'text-red-500' },
        ].map((s) => (
          <Card key={s.label} className="text-center">
            <p className={`text-2xl font-bold ${s.color}`}>{s.value}</p>
            <p className="mt-0.5 text-xs text-gray-500">{s.label}</p>
          </Card>
        ))}
      </div>

      {/* Table */}
      <Card className="overflow-hidden p-0">
        {isLoading && !hasLoaded ? (
          <div className="p-8 text-center text-sm text-gray-400">Loading riders…</div>
        ) : riders.length === 0 ? (
          <div className="flex flex-col items-center gap-3 p-12 text-gray-400">
            <Bike className="h-10 w-10 opacity-30" />
            <p className="text-sm">No riders registered yet.</p>
            <p className="text-xs text-gray-300">Riders sign up via the PrintX Rider app and appear here automatically.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[700px] text-left text-sm">
              <thead className="border-b border-gray-100 bg-gray-50/70 dark:border-gray-800 dark:bg-gray-900/50">
                <tr>
                  {['Rider', 'Phone', 'Vehicle', 'Online', 'Status', 'Actions'].map((h) => (
                    <th key={h} className="px-4 py-3 text-xs font-semibold uppercase tracking-wide text-gray-400">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {riders.map((rider) => (
                  <RiderRow key={rider.id} rider={rider} />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  )
}
