// Shared order date normalization — handles Firestore Timestamp, {seconds,nanoseconds},
// ISO string, Unix ms/s, JS Date, and null/undefined gracefully.

export const normalizeOrderDate = (value) => {
  if (value === null || value === undefined) return null

  if (typeof value === 'string') {
    const trimmed = value.trim()
    if (!trimmed) return null
    if (/^-?\d+(\.\d+)?$/.test(trimmed)) {
      const num = Number(trimmed)
      if (!Number.isFinite(num)) return null
      const millis = num > 1e12 ? num : num * 1000
      const d = new Date(millis)
      return Number.isNaN(d.getTime()) ? null : d
    }
    const d = new Date(trimmed)
    return Number.isNaN(d.getTime()) ? null : d
  }

  if (typeof value === 'object' && typeof value.toDate === 'function') {
    try {
      const d = value.toDate()
      return d instanceof Date && !Number.isNaN(d.getTime()) ? d : null
    } catch { return null }
  }

  if (typeof value === 'object' && value !== null && ('seconds' in value || 'nanoseconds' in value)) {
    const ms = Number(value.seconds) * 1000 + Math.floor(Number(value.nanoseconds || 0) / 1e6)
    if (!Number.isFinite(ms)) return null
    const d = new Date(ms)
    return Number.isNaN(d.getTime()) ? null : d
  }

  if (typeof value === 'number') {
    if (!Number.isFinite(value)) return null
    const millis = value > 1e12 ? value : value * 1000
    const d = new Date(millis)
    return Number.isNaN(d.getTime()) ? null : d
  }

  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value

  return null
}

export const safeFormatOrderDate = (value) => {
  const d = normalizeOrderDate(value)
  if (!d) return '—'
  return new Intl.DateTimeFormat('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }).format(d)
}

export const safeFormatOrderDateTime = (value) => {
  const d = normalizeOrderDate(value)
  if (!d) return '—'
  return new Intl.DateTimeFormat('en-GB', {
    day: '2-digit', month: 'short', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(d)
}
