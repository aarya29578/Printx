import { motion } from 'framer-motion'
import { Loader2 } from 'lucide-react'
import { cn } from '../../core/utils/cn'

const variantMap = {
  primary: 'bg-gradient-to-r from-primary-600 to-primary-700 text-white shadow-btn hover:opacity-90',
  secondary: 'border border-gray-200 bg-white text-gray-700 hover:bg-gray-50 dark:border-slate-700 dark:bg-slate-900 dark:text-gray-200',
  danger: 'bg-red-500 text-white hover:bg-red-600',
  ghost: 'text-primary-600 hover:bg-primary-50',
  outline: 'border border-primary-600 text-primary-600 hover:bg-primary-50',
}

const sizeMap = {
  sm: 'h-8 px-3 text-sm',
  md: 'h-10 px-4 text-sm',
  lg: 'h-12 px-6 text-base',
}

export default function Button({
  variant = 'primary',
  size = 'md',
  loading = false,
  disabled = false,
  icon: Icon,
  children,
  className,
  ...props
}) {
  return (
    <motion.button
      whileTap={{ scale: 0.97 }}
      disabled={disabled || loading}
      className={cn(
        'inline-flex items-center justify-center gap-2 rounded-xl font-medium transition disabled:cursor-not-allowed disabled:opacity-60',
        variantMap[variant],
        sizeMap[size],
        className,
      )}
      {...props}
    >
      {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : Icon ? <Icon className="h-4 w-4" /> : null}
      {children}
    </motion.button>
  )
}
