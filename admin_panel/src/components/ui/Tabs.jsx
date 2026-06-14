import { cn } from '../../core/utils/cn'

export default function Tabs({ tabs, active, onChange }) {
  return (
    <div className="flex flex-wrap gap-2">
      {tabs.map((tab) => (
        <button
          key={tab.value}
          type="button"
          onClick={() => onChange(tab.value)}
          className={cn(
            'rounded-full px-3 py-1.5 text-sm transition',
            active === tab.value ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200',
          )}
        >
          {tab.label}
        </button>
      ))}
    </div>
  )
}
