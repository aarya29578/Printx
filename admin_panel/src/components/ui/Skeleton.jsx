export default function Skeleton({ className = 'h-4 w-full' }) {
  return <div className={`animate-pulse rounded bg-gray-200 dark:bg-slate-700 ${className}`} />
}
