import { cn } from '../../core/utils/cn'

export default function Textarea({ className, ...props }) {
  return (
    <textarea
      {...props}
      className={cn(
        'w-full rounded-xl border border-gray-200 bg-white px-3 py-2 text-sm outline-none transition focus:border-primary-500 focus:ring-2 focus:ring-primary-100 dark:border-slate-700 dark:bg-slate-900',
        className,
      )}
    />
  )
}
