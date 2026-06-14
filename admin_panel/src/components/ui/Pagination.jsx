export default function Pagination({ page, totalPages, onChange }) {
  return (
    <div className="flex items-center gap-2">
      <button type="button" onClick={() => onChange(Math.max(1, page - 1))} disabled={page === 1} className="rounded border px-2 py-1 text-sm disabled:opacity-40">Prev</button>
      <span className="text-sm text-gray-500">Page {page} of {totalPages}</span>
      <button type="button" onClick={() => onChange(Math.min(totalPages, page + 1))} disabled={page >= totalPages} className="rounded border px-2 py-1 text-sm disabled:opacity-40">Next</button>
    </div>
  )
}
