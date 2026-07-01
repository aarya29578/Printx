/**
 * Safe date conversion utility
 * Handles multiple date formats from Firestore:
 * - Firestore Timestamp (object with toDate() method)
 * - ISO string
 * - Date object
 * - Number (milliseconds)
 * - null/undefined (returns null)
 */

export const safeConvertToDate = (value) => {
  if (!value) return null

  try {
    // Check if it's a Firestore Timestamp (has toDate method)
    if (value && typeof value === 'object' && typeof value.toDate === 'function') {
      return value.toDate()
    }

    // Check if it's already a Date object
    if (value instanceof Date) {
      return isValidDate(value) ? value : null
    }

    // Try to convert string or number to Date
    const date = new Date(value)
    return isValidDate(date) ? date : null
  } catch (error) {
    console.warn('Failed to convert date:', value, error)
    return null
  }
}

/**
 * Check if a Date object is valid
 */
export const isValidDate = (date) => {
  return date instanceof Date && !isNaN(date.getTime())
}

/**
 * Safe format date - never throws
 * Returns formatted date or fallback string
 */
export const safeFormatDate = (value) => {
  const date = safeConvertToDate(value)
  if (!date) return '—'

  try {
    return date.toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    })
  } catch (error) {
    console.warn('Failed to format date:', value, error)
    return '—'
  }
}

/**
 * Safe format date and time - never throws
 */
export const safeFormatDateTime = (value) => {
  const date = safeConvertToDate(value)
  if (!date) return '—'

  try {
    return date.toLocaleString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  } catch (error) {
    console.warn('Failed to format date time:', value, error)
    return '—'
  }
}

/**
 * Safe format relative time (e.g., "2 days ago")
 */
export const safeFormatTimeAgo = (value) => {
  const date = safeConvertToDate(value)
  if (!date) return '—'

  try {
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffSec = Math.floor(diffMs / 1000)
    const diffMin = Math.floor(diffSec / 60)
    const diffHour = Math.floor(diffMin / 60)
    const diffDay = Math.floor(diffHour / 24)

    if (diffSec < 60) return 'just now'
    if (diffMin < 60) return `${diffMin}m ago`
    if (diffHour < 24) return `${diffHour}h ago`
    if (diffDay < 7) return `${diffDay}d ago`
    if (diffDay < 30) return `${Math.floor(diffDay / 7)}w ago`
    return `${Math.floor(diffDay / 30)}mo ago`
  } catch (error) {
    console.warn('Failed to format time ago:', value, error)
    return '—'
  }
}
