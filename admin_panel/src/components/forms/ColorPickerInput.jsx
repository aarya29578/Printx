import { useState } from 'react'
import { CompactPicker } from 'react-color'

export default function ColorPickerInput({ label, value, onChange }) {
  const [open, setOpen] = useState(false)

  return (
    <div>
      <p className="mb-1 text-sm font-medium">{label}</p>
      <button type="button" onClick={() => setOpen((v) => !v)} className="flex w-full items-center justify-between rounded-xl border border-gray-200 px-3 py-2 text-sm">
        <span>{value}</span>
        <span className="h-5 w-8 rounded" style={{ background: value }} />
      </button>
      {open && (
        <div className="mt-2">
          <CompactPicker color={value} onChange={(c) => onChange(c.hex)} />
        </div>
      )}
    </div>
  )
}
