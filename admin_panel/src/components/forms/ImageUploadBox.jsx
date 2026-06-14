import { useCallback, useState } from 'react'
import { useDropzone } from 'react-dropzone'
import { UploadCloud } from 'lucide-react'
import Button from '../ui/Button'

export default function ImageUploadBox({ label, hint, onFile, currentImage }) {
  const [preview, setPreview] = useState(currentImage || null)

  const onDrop = useCallback((accepted) => {
    const file = accepted[0]
    if (!file) return
    const url = URL.createObjectURL(file)
    setPreview(url)
    onFile?.(file)
  }, [onFile])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    maxFiles: 1,
    accept: { 'image/*': [] },
    onDrop,
  })

  return (
    <div>
      {label ? <p className="mb-2 text-sm font-medium">{label}</p> : null}
      <div
        {...getRootProps()}
        className={`relative min-h-36 cursor-pointer rounded-xl border-2 border-dashed p-4 text-center transition ${isDragActive ? 'border-primary-400 bg-primary-50' : 'border-gray-300'}`}
      >
        <input {...getInputProps()} />
        {!preview ? (
          <div className="grid place-items-center gap-2 text-gray-500">
            <UploadCloud className="h-8 w-8" />
            <p className="text-sm">Drag and drop or click to upload</p>
            <p className="text-xs">{hint || 'PNG/JPG, max 5MB'}</p>
          </div>
        ) : (
          <>
            <img src={preview} alt="Preview" className="h-36 w-full rounded-xl object-cover" />
            <div className="absolute inset-x-4 bottom-4 flex justify-center gap-2 opacity-0 transition hover:opacity-100">
              <Button type="button" size="sm" variant="secondary">Change</Button>
              <Button
                type="button"
                size="sm"
                variant="danger"
                onClick={(e) => {
                  e.stopPropagation()
                  setPreview(null)
                  onFile?.(null)
                }}
              >
                Remove
              </Button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
