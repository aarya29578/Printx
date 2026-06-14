import { Pie, PieChart, Cell, ResponsiveContainer, Tooltip } from 'recharts'

export default function OrderDonutChart({ data }) {
  const total = data.reduce((sum, item) => sum + item.value, 0)
  return (
    <div>
      <div className="relative h-[300px]">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Pie data={data} dataKey="value" innerRadius={70} outerRadius={100}>
              {data.map((entry) => (
                <Cell key={entry.name} fill={entry.color} />
              ))}
            </Pie>
            <Tooltip />
          </PieChart>
        </ResponsiveContainer>
        <div className="pointer-events-none absolute inset-0 grid place-items-center text-center">
          <div>
            <p className="text-xl font-semibold">{total.toLocaleString('en-IN')}</p>
            <p className="text-xs text-gray-500">Total</p>
          </div>
        </div>
      </div>
      <div className="space-y-2">
        {data.map((item) => (
          <div key={item.name} className="flex items-center justify-between text-sm">
            <span className="flex items-center gap-2"><span className="h-2.5 w-2.5 rounded-sm" style={{ background: item.color }} />{item.name}</span>
            <span>{item.value}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
