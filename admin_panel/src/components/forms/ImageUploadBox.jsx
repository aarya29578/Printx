import { useCallback, useEffect, useMemo, useState } from 'react'
import { useDropzone } from 'react-dropzone'
import { UploadCloud, RefreshCcw, Trash2 } from 'lucide-react'
import Button from '../ui/Button'

const CATEGORY_UPLOAD_URL = import.meta.env.VITE_CATEGORY_UPLOAD_URL || 'https://jenishaonlineservice.com/printx/api/categorie_image.php'

export default function ImageUploadBox({
  label,
  hint,
  categoryId,
  currentImage,
  onChange,
  onUploadStateChange,
}) {
  const [previewUrl, setPreviewUrl] = useState(currentImage || null)
  const [isUploading, setIsUploading] = useState(false)
  const [errorMessage, setErrorMessage] = useState('')

  useEffect(() => {
    setPreviewUrl(currentImage || null)
  }, [currentImage])

  useEffect(() => {
    onUploadStateChange?.(isUploading)
  }, [isUploading, onUploadStateChange])

  const uploadImage = useCallback(async (file) => {
    if (!file) return null
    if (!categoryId) {
      throw new Error('Category ID is required for image upload')
    }

    const formData = new FormData()
    formData.append('categoryId', categoryId)
    formData.append('image', file)

    const response = await fetch(CATEGORY_UPLOAD_URL, {
      method: 'POST',
      body: formData,
    })

    const data = await response.json().catch(() => null)
    if (!response.ok || !data) {
      throw new Error(data?.error || 'Upload request failed')
    }
    if (data.success !== true) {
      throw new Error(data?.error || 'Upload failed')
    }
    if (!data.url || typeof data.url !== 'string') {
      throw new Error('Upload response did not return a valid image URL')
    }
    return data.url
  }, [categoryId])

  const onDrop = useCallback(async (accepted) => {
    const file = accepted[0]
    if (!file) return

    setErrorMessage('')
    const localPreview = URL.createObjectURL(file)
    setPreviewUrl(localPreview)
    setIsUploading(true)
    onChange?.(null)

    try {
      const uploadedUrl = await uploadImage(file)
      setPreviewUrl(uploadedUrl)
      onChange?.(uploadedUrl)
    } catch (error) {
      const message = error?.message || 'Image upload failed'
      setErrorMessage(message)
      setPreviewUrl(currentImage || null)
      onChange?.(null)
    } finally {
      setIsUploading(false)
      if (localPreview.startsWith('blob:')) {
        URL.revokeObjectURL(localPreview)
      }
    }
  }, [currentImage, onChange, uploadImage])

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    maxFiles: 1,
    accept: { 'image/*': [] },
    onDrop,
  })

  const canRemove = useMemo(() => Boolean(previewUrl), [previewUrl])

  const handleRemove = (event) => {
    event.stopPropagation()
    setPreviewUrl(null)
    setErrorMessage('')
    onChange?.(null)
  }

  return (
    <div>
      {label ? <p className="mb-2 text-sm font-medium">{label}</p> : null}
      <div
        {...getRootProps()}
        className={`relative min-h-36 cursor-pointer rounded-xl border-2 border-dashed p-4 text-center transition ${isDragActive ? 'border-primary-400 bg-primary-50' : 'border-gray-300'} ${isUploading ? 'opacity-70' : ''}`}
      >
        <input {...getInputProps()} disabled={isUploading} />
        {!previewUrl ? (
          <div className="grid place-items-center gap-2 text-gray-500">
            <UploadCloud className="h-8 w-8" />
            <p className="text-sm">Drag and drop or click to upload</p>
            <p className="text-xs">{hint || 'PNG/JPG, max 5MB'}</p>
          </div>
        ) : (
          <>
            <img src={previewUrl} alt="Preview" className="h-36 w-full rounded-xl object-cover" />
            <div className="absolute inset-x-4 bottom-4 flex justify-center gap-2 opacity-0 transition hover:opacity-100">
              <Button type="button" size="sm" variant="secondary" disabled={isUploading}>
                <RefreshCcw className="h-4 w-4" /> Replace
              </Button>
              <Button
                type="button"
                size="sm"
                variant="danger"
                onClick={handleRemove}
                disabled={isUploading}
              >
                <Trash2 className="h-4 w-4" /> Remove
              </Button>
            </div>
          </>
        )}
      </div>
      {isUploading ? <p className="mt-2 text-sm text-blue-600">Uploading image…</p> : null}
      {errorMessage ? <p className="mt-2 text-sm text-red-600">{errorMessage}</p> : null}
    </div>
  )
}
