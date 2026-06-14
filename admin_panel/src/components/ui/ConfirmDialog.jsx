import { useState } from 'react'
import { AlertTriangle } from 'lucide-react'
import Modal from './Modal'
import Button from './Button'
import Input from './Input'

export default function ConfirmDialog({
  isOpen,
  onClose,
  onConfirm,
  title = 'Confirm Action',
  description = 'This action cannot be undone.',
  confirmText = 'DELETE',
  requireTyped = true,
  typedValue,
}) {
  const [typed, setTyped] = useState('')
  const [loading, setLoading] = useState(false)
  const expectedValue = typedValue || confirmText

  const handleConfirm = async () => {
    setLoading(true)
    try {
      await onConfirm()
      setTyped('')
      onClose()
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} footer={(
      <div className="flex justify-end gap-2">
        <Button variant="secondary" onClick={onClose}>Cancel</Button>
        <Button variant="danger" onClick={handleConfirm} disabled={requireTyped ? typed !== expectedValue : false} loading={loading}>Confirm</Button>
      </div>
    )}>
      <div className="space-y-4 text-center">
        <div className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-amber-100 text-amber-600">
          <AlertTriangle className="h-7 w-7" />
        </div>
        <p className="text-sm text-gray-600 dark:text-gray-300">{description}</p>
        {requireTyped && (
          <>
            <p className="text-xs text-gray-500">Type <strong>{expectedValue}</strong> to continue</p>
            <Input value={typed} onChange={(e) => setTyped(e.target.value)} />
          </>
        )}
      </div>
    </Modal>
  )
}
