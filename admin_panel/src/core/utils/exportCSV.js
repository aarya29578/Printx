import Papa from 'papaparse'
import { formatDate } from './formatDate'

export const exportToCSV = (data, filename) => {
  const csv = Papa.unparse(data)
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${filename}-${formatDate(new Date())}.csv`
  a.click()
  URL.revokeObjectURL(url)
}
