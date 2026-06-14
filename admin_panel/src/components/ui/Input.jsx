import React from 'react'
import { cn } from '../../core/utils/cn'

const Input = React.forwardRef(
  ({ className, error, ...props }, ref) => {
    return (
      <input
        ref={ref}
        {...props}
        className={cn(
          'h-10 w-full rounded-xl border border-gray-200 bg-white px-3 text-sm outline-none transition focus:border-primary-500 focus:ring-2 focus:ring-primary-100 dark:border-slate-700 dark:bg-slate-900',
          error && 'border-red-500 focus:ring-red-100',
          className,
        )}
      />
    )
  }
)

Input.displayName = 'Input'

export default Input