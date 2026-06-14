import { useState } from 'react'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Tabs from '../../components/ui/Tabs'
import Card from '../../components/ui/Card'
import Input from '../../components/ui/Input'
import Textarea from '../../components/ui/Textarea'
import Button from '../../components/ui/Button'
import Toggle from '../../components/ui/Toggle'
import { useSettingsStore } from '../../store/settingsStore'
import ColorPickerInput from '../../components/forms/ColorPickerInput'

export default function GeneralSettingsPage() {
  const [tab, setTab] = useState('app')
  const settings = useSettingsStore((state) => state.settings)
  const updateSettings = useSettingsStore((state) => state.updateSettings)
  const updateNestedSettings = useSettingsStore((state) => state.updateNestedSettings)

  const save = () => toast.success('Settings saved')

  return (
    <div className="space-y-4">
      <PageHeader title="General Settings" />
      <Tabs
        tabs={[
          { label: 'App Settings', value: 'app' },
          { label: 'Branding', value: 'branding' },
          { label: 'Payment', value: 'payment' },
          { label: 'Invoice', value: 'invoice' },
          { label: 'Maintenance', value: 'maintenance' },
        ]}
        active={tab}
        onChange={setTab}
      />

      {tab === 'app' && (
        <Card className="space-y-3">
          <Input value={settings.appName} onChange={(e) => updateSettings({ appName: e.target.value })} placeholder="Business name" />
          <Input value={settings.supportEmail} onChange={(e) => updateSettings({ supportEmail: e.target.value })} placeholder="Support email" />
          <Input value={settings.supportPhone} onChange={(e) => updateSettings({ supportPhone: e.target.value })} placeholder="Support phone" />
          <Textarea value={settings.businessAddress} onChange={(e) => updateSettings({ businessAddress: e.target.value })} rows={3} />
          <Button onClick={save}>Save Changes</Button>
        </Card>
      )}

      {tab === 'branding' && (
        <Card className="space-y-3">
          <ColorPickerInput label="Primary Color" value={settings.branding.primary} onChange={(val) => updateSettings({ branding: { ...settings.branding, primary: val } })} />
          <ColorPickerInput label="Secondary Color" value={settings.branding.secondary} onChange={(val) => updateSettings({ branding: { ...settings.branding, secondary: val } })} />
          <ColorPickerInput label="Accent Color" value={settings.branding.accent} onChange={(val) => updateSettings({ branding: { ...settings.branding, accent: val } })} />
          <Button onClick={save}>Save Branding</Button>
        </Card>
      )}

      {tab === 'payment' && (
        <Card className="space-y-3">
          <h3 className="font-semibold dark:text-white">Payment Gateway</h3>
          <div className="grid gap-3 md:grid-cols-2">
            <Input
              value={settings.payment.razorpayKeyId}
              onChange={(e) => updateNestedSettings('payment', { razorpayKeyId: e.target.value })}
              placeholder="Razorpay Key ID"
            />
            <Input
              value={settings.payment.razorpaySecret}
              onChange={(e) => updateNestedSettings('payment', { razorpaySecret: e.target.value })}
              placeholder="Razorpay Secret"
            />
          </div>

          <h4 className="pt-1 text-sm font-semibold text-gray-600 dark:text-gray-300">Enabled Methods</h4>
          <div className="grid gap-2 sm:grid-cols-2">
            {Object.entries(settings.payment.methods).map(([key, enabled]) => (
              <label key={key} className="flex items-center justify-between rounded-xl border border-gray-200 p-3 text-sm capitalize dark:border-gray-700">
                <span>{key.replace('netBanking', 'Net Banking')}</span>
                <Toggle
                  checked={enabled}
                  onChange={(value) => updateNestedSettings('payment', { methods: { ...settings.payment.methods, [key]: value } })}
                />
              </label>
            ))}
          </div>
          <Button onClick={save}>Save Payment Settings</Button>
        </Card>
      )}

      {tab === 'invoice' && (
        <Card className="space-y-3">
          <h3 className="font-semibold dark:text-white">Invoice Details</h3>
          <Input value={settings.invoice.companyName} onChange={(e) => updateNestedSettings('invoice', { companyName: e.target.value })} placeholder="Company Name" />
          <Input value={settings.invoice.gstin} onChange={(e) => updateNestedSettings('invoice', { gstin: e.target.value })} placeholder="GSTIN" />
          <Textarea rows={3} value={settings.invoice.footerText} onChange={(e) => updateNestedSettings('invoice', { footerText: e.target.value })} placeholder="Footer text" />
          <Button onClick={save}>Save Invoice Settings</Button>
        </Card>
      )}

      {tab === 'maintenance' && (
        <Card className="border-2 border-red-200 bg-red-50">
          <h3 className="font-semibold text-red-700">Maintenance Mode</h3>
          <p className="mb-3 text-sm text-red-700">When enabled, users will see a maintenance screen in the app.</p>
          <div className="mb-3 flex items-center gap-2"><Toggle checked={settings.maintenanceMode} onChange={(v) => updateSettings({ maintenanceMode: v })} /> Enable Maintenance</div>
          <Textarea rows={3} value={settings.maintenanceMessage} onChange={(e) => updateSettings({ maintenanceMessage: e.target.value })} />
          <Button variant="danger" className="mt-3" onClick={save}>Activate Maintenance Mode</Button>
        </Card>
      )}
    </div>
  )
}
