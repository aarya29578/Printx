import { useState } from 'react'
import DatePicker from 'react-datepicker'

export default function DateRangePicker({ value, onChange }) {
  const [range, setRange] = useState(value || [null, null])

  return (
    <DatePicker
      selectsRange
      startDate={range[0]}
      endDate={range[1]}
      onChange={(dates) => {
        setRange(dates)
        onChange?.(dates)
      }}
      isClearable
      className="h-10 rounded-xl border border-gray-200 px-3 text-sm"
      placeholderText="Select date range"
    />
  )
}
