import { useMemo, useState } from 'react'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Tabs from '../../components/ui/Tabs'
import Card from '../../components/ui/Card'
import Button from '../../components/ui/Button'
import Textarea from '../../components/ui/Textarea'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import { useSettingsStore } from '../../store/settingsStore'

export default function DeliverySettingsPage() {
  const [tab, setTab] = useState('zones')
  const delivery = useSettingsStore((state) => state.settings.delivery)
  const updateNestedSettings = useSettingsStore((state) => state.updateNestedSettings)

  const [zoneName, setZoneName] = useState('')
  const [zonePincodes, setZonePincodes] = useState('')
  const [notes, setNotes] = useState(delivery.holidayNotes || '')
  const [newEta, setNewEta] = useState({ category: '', minDays: 2, maxDays: 4 })

  const zoneList = useMemo(() => delivery.zones || [], [delivery.zones])

  const addZone = () => {
    if (!zoneName.trim() || !zonePincodes.trim()) {
      toast.error('Enter zone name and pincodes')
      return
    }
    const next = [
      ...zoneList,
      {
        id: `zone-${Date.now()}`,
        name: zoneName.trim(),
        pincodes: zonePincodes.split(',').map((p) => p.trim()).filter(Boolean),
        status: 'active',
      },
    ]
    updateNestedSettings('delivery', { zones: next })
    setZoneName('')
    setZonePincodes('')
    toast.success('Zone added')
  }

  return (
    <div className="space-y-4">
      <PageHeader title="Delivery Settings" />
      <Tabs
        tabs={[
          { label: 'Delivery Zones', value: 'zones' },
          { label: 'Pricing', value: 'pricing' },
          { label: 'ETA Settings', value: 'eta' },
        ]}
        active={tab}
        onChange={setTab}
      />

      {tab === 'zones' && (
        <Card className="space-y-4">
          <div className="grid gap-3 md:grid-cols-3">
            <Input value={zoneName} onChange={(e) => setZoneName(e.target.value)} placeholder="Zone name" />
            <Input value={zonePincodes} onChange={(e) => setZonePincodes(e.target.value)} placeholder="Pincodes (comma separated)" />
            <Button onClick={addZone}>Add Zone</Button>
          </div>

          {zoneList.length === 0 ? (
            <p className="text-sm text-gray-500">No zones configured yet.</p>
          ) : (
            <div className="space-y-2">
              {zoneList.map((zone) => (
                <div key={zone.id} className="flex flex-wrap items-center gap-2 rounded-xl border border-gray-200 p-3 dark:border-gray-700">
                  <div className="min-w-0 flex-1">
                    <p className="font-medium dark:text-white">{zone.name}</p>
                    <p className="text-xs text-gray-500">{zone.pincodes.join(', ')}</p>
                  </div>
                  <Select
                    className="w-32"
                    value={zone.status}
                    onChange={(e) => {
                      const next = zoneList.map((item) => (item.id === zone.id ? { ...item, status: e.target.value } : item))
                      updateNestedSettings('delivery', { zones: next })
                    }}
                  >
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                  </Select>
                  <Button
                    variant="danger"
                    size="sm"
                    onClick={() => {
                      const next = zoneList.filter((item) => item.id !== zone.id)
                      updateNestedSettings('delivery', { zones: next })
                      toast.success('Zone removed')
                    }}
                  >
                    Remove
                  </Button>
                </div>
              ))}
            </div>
          )}
        </Card>
      )}

      {tab === 'pricing' && (
        <Card className="space-y-3">
          <h3 className="font-semibold dark:text-white">Delivery Pricing</h3>
          <div className="space-y-2">
            {(delivery.pricing || []).map((item) => (
              <div key={item.id} className="grid gap-2 rounded-xl border border-gray-200 p-3 md:grid-cols-5 dark:border-gray-700">
                <Input value={item.type} onChange={(e) => {
                  const next = delivery.pricing.map((p) => (p.id === item.id ? { ...p, type: e.target.value } : p))
                  updateNestedSettings('delivery', { pricing: next })
                }} />
                <Input type="number" value={item.basePrice} onChange={(e) => {
                  const next = delivery.pricing.map((p) => (p.id === item.id ? { ...p, basePrice: Number(e.target.value) } : p))
                  updateNestedSettings('delivery', { pricing: next })
                }} />
                <Input type="number" value={item.freeAbove} onChange={(e) => {
                  const next = delivery.pricing.map((p) => (p.id === item.id ? { ...p, freeAbove: Number(e.target.value) } : p))
                  updateNestedSettings('delivery', { pricing: next })
                }} />
                <Input value={item.days} onChange={(e) => {
                  const next = delivery.pricing.map((p) => (p.id === item.id ? { ...p, days: e.target.value } : p))
                  updateNestedSettings('delivery', { pricing: next })
                }} />
                <Select value={item.status} onChange={(e) => {
                  const next = delivery.pricing.map((p) => (p.id === item.id ? { ...p, status: e.target.value } : p))
                  updateNestedSettings('delivery', { pricing: next })
                }}>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </Select>
              </div>
            ))}
          </div>
          <Button onClick={() => toast.success('Delivery pricing updated')}>Save Changes</Button>
        </Card>
      )}

      {tab === 'eta' && (
        <Card className="space-y-4">
          <h3 className="font-semibold dark:text-white">Category ETA Rules</h3>
          <div className="grid gap-3 md:grid-cols-4">
            <Input value={newEta.category} onChange={(e) => setNewEta((prev) => ({ ...prev, category: e.target.value }))} placeholder="Category" />
            <Input type="number" value={newEta.minDays} onChange={(e) => setNewEta((prev) => ({ ...prev, minDays: Number(e.target.value) }))} />
            <Input type="number" value={newEta.maxDays} onChange={(e) => setNewEta((prev) => ({ ...prev, maxDays: Number(e.target.value) }))} />
            <Button onClick={() => {
              if (!newEta.category.trim()) {
                toast.error('Category is required')
                return
              }
              updateNestedSettings('delivery', {
                etaByCategory: [
                  ...(delivery.etaByCategory || []),
                  { id: `eta-${Date.now()}`, ...newEta },
                ],
              })
              setNewEta({ category: '', minDays: 2, maxDays: 4 })
            }}>Add Rule</Button>
          </div>

          <div className="space-y-2">
            {(delivery.etaByCategory || []).map((rule) => (
              <div key={rule.id} className="flex items-center justify-between rounded-xl border border-gray-200 p-3 text-sm dark:border-gray-700">
                <p className="dark:text-gray-200">{rule.category}: {rule.minDays}-{rule.maxDays} days</p>
                <Button
                  size="sm"
                  variant="danger"
                  onClick={() => updateNestedSettings('delivery', { etaByCategory: delivery.etaByCategory.filter((item) => item.id !== rule.id) })}
                >
                  Remove
                </Button>
              </div>
            ))}
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium">Holiday / Non-Working Notes</label>
            <Textarea rows={4} value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Eg: Diwali week may delay dispatch by 1 day" />
            <Button className="mt-3" onClick={() => {
              updateNestedSettings('delivery', { holidayNotes: notes })
              toast.success('Holiday notes saved')
            }}>Save Notes</Button>
          </div>
        </Card>
      )}
    </div>
  )
}
