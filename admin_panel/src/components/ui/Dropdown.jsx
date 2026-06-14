export default function Dropdown({ items, onSelect }) {
  return (
    <div className="rounded-xl border border-gray-200 bg-white p-1 shadow-card dark:border-slate-700 dark:bg-slate-900">
      {items.map((item) => (
        <button key={item.value} type="button" onClick={() => onSelect(item.value)} className="block w-full rounded-lg px-3 py-2 text-left text-sm hover:bg-gray-50 dark:hover:bg-slate-800">
          {item.label}
        </button>
      ))}
    </div>
  )
}
