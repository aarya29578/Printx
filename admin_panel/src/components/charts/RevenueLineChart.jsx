import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { formatINR } from '../../core/utils/formatCurrency'

export default function RevenueLineChart({ data }) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={data}>
        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" />
        <XAxis dataKey="month" tick={{ fontSize: 12, fill: '#9CA3AF' }} />
        <YAxis tick={{ fontSize: 12, fill: '#9CA3AF' }} tickFormatter={(v) => `₹${v / 1000}k`} />
        <Tooltip formatter={(value) => formatINR(value)} />
        <Legend />
        <Line type="monotone" dataKey="thisYear" stroke="#4F46E5" strokeWidth={3} dot={false} />
        <Line type="monotone" dataKey="lastYear" stroke="#9CA3AF" strokeDasharray="5 5" strokeWidth={2} dot={false} />
      </LineChart>
    </ResponsiveContainer>
  )
}
