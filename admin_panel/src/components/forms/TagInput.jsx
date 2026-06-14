import { useState } from 'react'
import { X } from 'lucide-react'

export default function TagInput({ value = [], onChange, placeholder = 'Type and press Enter' }) {
  const [input, setInput] = useState('')

  const addTag = () => {
    const clean = input.trim()
    if (!clean || value.includes(clean)) return
    onChange([...(value || []), clean])
    setInput('')
  }

  return (
    <div className="rounded-xl border border-gray-200 p-2">
      <div className="mb-2 flex flex-wrap gap-2">
        {(value || []).map((tag) => (
          <span key={tag} className="inline-flex items-center gap-1 rounded-full bg-primary-100 px-2 py-1 text-xs text-primary-700">
            {tag}
            <button type="button" onClick={() => onChange(value.filter((t) => t !== tag))}><X className="h-3 w-3" /></button>
          </span>
        ))}
      </div>
      <input
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === 'Enter') {
            e.preventDefault()
            addTag()
          }
        }}
        placeholder={placeholder}
        className="w-full border-none text-sm outline-none"
      />
    </div>
  )
}
