import { cn } from '../../core/utils/cn'

export default function Card({ className, children }) {
  return <div className={cn('rounded-2xl border border-gray-100 bg-white p-5 shadow-card dark:border-slate-700 dark:bg-slate-900', className)}>{children}</div>
}
