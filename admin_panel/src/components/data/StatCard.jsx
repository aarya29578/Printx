import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { TrendingDown, TrendingUp } from 'lucide-react'
import Card from '../ui/Card'

function useCountUp(target, duration = 1500) {
  const [count, setCount] = useState(0)

  useEffect(() => {
    let start = 0
    const step = target / (duration / 16)
    const timer = setInterval(() => {
      start += step
      if (start >= target) {
        setCount(target)
        clearInterval(timer)
      } else {
        setCount(Math.floor(start))
      }
    }, 16)
    return () => clearInterval(timer)
  }, [target, duration])

  return count
}

export default function StatCard({
  index = 0,
  title,
  value,
  rawValue,
  formatter,
  icon: Icon,
  iconBg = 'bg-primary-600',
  growth = 0,
  growthLabel = 'vs last month',
}) {
  const positive = Number(growth) >= 0
  const count = useCountUp(Number(rawValue || 0))
  const displayValue = rawValue ? (formatter ? formatter(count) : count.toLocaleString('en-IN')) : value

  return (
    <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: index * 0.06 }}>
      <Card className="p-5">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm text-gray-500">{title}</p>
            <h3 className="font-display text-2xl font-bold text-gray-900 dark:text-gray-100">{displayValue}</h3>
          </div>
          <div className={`grid h-12 w-12 place-items-center rounded-xl text-white ${iconBg}`}>
            {Icon ? <Icon className="h-5 w-5" /> : null}
          </div>
        </div>
        <div className="mt-3 flex items-center gap-1 text-sm">
          {positive ? <TrendingUp className="h-4 w-4 text-green-600" /> : <TrendingDown className="h-4 w-4 text-red-600" />}
          <span className={positive ? 'text-green-600' : 'text-red-600'}>{positive ? '+' : ''}{growth}%</span>
          <span className="text-gray-500">{growthLabel}</span>
        </div>
      </Card>
    </motion.div>
  )
}
