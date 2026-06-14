import { useState } from 'react'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Tabs from '../../components/ui/Tabs'
import Card from '../../components/ui/Card'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'
import Toggle from '../../components/ui/Toggle'
import { useSettingsStore } from '../../store/settingsStore'

export default function PricingRulesPage() {
  const [tab, setTab] = useState('bulk')
  const pricingRules = useSettingsStore((state) => state.settings.pricingRules)
  const invoiceGstin = useSettingsStore((state) => state.settings.invoice.gstin)
  const updateNestedSettings = useSettingsStore((state) => state.updateNestedSettings)

  const [flash, setFlash] = useState({ discount: 15, start: '', end: '' })

  return (
    <div className="space-y-4">
      <PageHeader title="Pricing Rules" />
      <Tabs
        tabs={[
          { label: 'Bulk Discounts', value: 'bulk' },
          { label: 'GST Settings', value: 'gst' },
          { label: 'Flash Sales', value: 'flash' },
        ]}
        active={tab}
        onChange={setTab}
      />

      {tab === 'bulk' && (
        <Card className="space-y-3">
          <h3 className="font-semibold dark:text-white">Global Bulk Rule</h3>
          <div className="flex items-center gap-2 text-sm dark:text-gray-300">
            <Toggle
              checked={pricingRules.bulkEnabled}
              onChange={(v) => updateNestedSettings('pricingRules', { bulkEnabled: v })}
            />
            Enable automatic bulk discount
          </div>
          <div className="grid gap-3 md:grid-cols-3">
            <Input
              type="number"
              value={pricingRules.bulkThreshold}
              onChange={(e) => updateNestedSettings('pricingRules', { bulkThreshold: Number(e.target.value) })}
              placeholder="Orders above ₹"
            />
            <Input
              type="number"
              value={pricingRules.bulkDiscount}
              onChange={(e) => updateNestedSettings('pricingRules', { bulkDiscount: Number(e.target.value) })}
              placeholder="Discount %"
            />
            <Button onClick={() => toast.success('Bulk pricing saved')}>Save</Button>
          </div>
        </Card>
      )}

      {tab === 'gst' && (
        <Card className="space-y-3">
          <h3 className="font-semibold dark:text-white">GST Settings</h3>
          <div className="grid gap-3 md:grid-cols-3">
            <select
              className="h-10 rounded-xl border border-gray-200 bg-white px-3 dark:border-gray-700 dark:bg-gray-800"
              value={pricingRules.gstDefault}
              onChange={(e) => updateNestedSettings('pricingRules', { gstDefault: Number(e.target.value) })}
            >
              <option value={18}>18%</option>
              <option value={12}>12%</option>
              <option value={5}>5%</option>
              <option value={0}>0%</option>
            </select>
            <Input value={invoiceGstin} readOnly />
            <Button onClick={() => toast.success('GST settings saved')}>Save</Button>
          </div>
        </Card>
      )}

      {tab === 'flash' && (
        <Card className="space-y-3">
          <h3 className="font-semibold dark:text-white">Flash Sale</h3>
          <div className="grid gap-3 md:grid-cols-3">
            <Input type="number" value={flash.discount} onChange={(e) => setFlash((prev) => ({ ...prev, discount: Number(e.target.value) }))} placeholder="Discount %" />
            <Input type="datetime-local" value={flash.start} onChange={(e) => setFlash((prev) => ({ ...prev, start: e.target.value }))} />
            <Input type="datetime-local" value={flash.end} onChange={(e) => setFlash((prev) => ({ ...prev, end: e.target.value }))} />
          </div>
          <Button
            onClick={() => {
              if (!flash.start || !flash.end) {
                toast.error('Select start and end date')
                return
              }
              updateNestedSettings('pricingRules', {
                flashSales: [
                  ...(pricingRules.flashSales || []),
                  { id: `flash-${Date.now()}`, ...flash, status: 'active' },
                ],
              })
              toast.success('Flash sale scheduled')
            }}
          >
            Start Flash Sale
          </Button>

          <div className="space-y-2">
            {(pricingRules.flashSales || []).map((sale) => (
              <div key={sale.id} className="flex items-center justify-between rounded-xl border border-gray-200 p-3 text-sm dark:border-gray-700">
                <p className="dark:text-gray-200">{sale.discount}% from {new Date(sale.start).toLocaleString()} to {new Date(sale.end).toLocaleString()}</p>
                <Button
                  variant="danger"
                  size="sm"
                  onClick={() => updateNestedSettings('pricingRules', { flashSales: pricingRules.flashSales.filter((item) => item.id !== sale.id) })}
                >
                  Remove
                </Button>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  )
}
