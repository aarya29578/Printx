import { AnimatePresence, motion } from 'framer-motion'
import { X } from 'lucide-react'

export default function Modal({ isOpen, onClose, title, size = 'max-w-xl', children, footer }) {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div className="fixed inset-0 z-50 grid place-items-center bg-black/50 p-4 backdrop-blur-sm" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
          <motion.div className={`w-full ${size} rounded-2xl bg-white shadow-xl dark:bg-slate-900`} initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }}>
            <div className="flex items-center justify-between border-b border-gray-100 p-4 dark:border-slate-700">
              <h3 className="font-semibold">{title}</h3>
              <button type="button" onClick={onClose} title="Close"><X className="h-5 w-5" /></button>
            </div>
            <div className="max-h-[70vh] overflow-auto p-4">{children}</div>
            {footer && <div className="border-t border-gray-100 p-4 dark:border-slate-700">{footer}</div>}
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
