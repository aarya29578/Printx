import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Card from '../../components/ui/Card'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import Button from '../../components/ui/Button'
import ImageUploadBox from '../../components/forms/ImageUploadBox'
import { useBannersStore } from '../../store/bannersStore'

const toLocalPreview = (file) => new Promise((resolve, reject) => {
  const reader = new FileReader()
  reader.onload = () => resolve(reader.result)
  reader.onerror = () => reject(reader.error)
  reader.readAsDataURL(file)
})

export default function AddEditBannerPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const { banners, addBanner, updateBanner } = useBannersStore()
  const selected = useMemo(() => banners.find((item) => item.id === id), [banners, id])
  const isEdit = Boolean(selected)
  const [title, setTitle] = useState(selected?.title || '')
  const [subtitle, setSubtitle] = useState(selected?.subtitle || '')
  const [ctaText, setCtaText] = useState(selected?.ctaText || 'Shop Now')
  const [linkTarget, setLinkTarget] = useState(selected?.linkTarget || '')
  const [route, setRoute] = useState(selected?.route || '')
  const [status, setStatus] = useState(selected?.status || 'active')
  const [position, setPosition] = useState(selected?.position || '')
  const [primaryColor, setPrimaryColor] = useState(selected?.gradientFrom || '#4F46E5')
  const [secondaryColor, setSecondaryColor] = useState(selected?.gradientTo || '#7C3AED')
  const [imageFile, setImageFile] = useState(null)
  const [imagePreview, setImagePreview] = useState(selected?.imageUrl || '')
  const [isSaving, setIsSaving] = useState(false)

  useEffect(() => {
    setTitle(selected?.title || '')
    setSubtitle(selected?.subtitle || '')
    setCtaText(selected?.ctaText || 'Shop Now')
    setLinkTarget(selected?.linkTarget || '')
    setRoute(selected?.route || '')
    setStatus(selected?.status || 'active')
    setPosition(selected?.position || '')
    setPrimaryColor(selected?.gradientFrom || '#4F46E5')
    setSecondaryColor(selected?.gradientTo || '#7C3AED')
    setImageFile(null)
    setImagePreview(selected?.imageUrl || '')
  }, [selected])

  useEffect(() => () => {
    if (imagePreview && imagePreview.startsWith('blob:')) {
      URL.revokeObjectURL(imagePreview)
    }
  }, [imagePreview])

  const handleFile = async (file) => {
    if (!file) {
      setImageFile(null)
      setImagePreview('')
      return
    }
    setImageFile(file)
    const preview = await toLocalPreview(file)
    setImagePreview(preview)
  }

  const onSubmit = async (event) => {
    event.preventDefault()
    if (!title.trim() || !subtitle.trim()) {
      toast.error('Title and subtitle are required')
      return
    }
    if (!isEdit && !imageFile) {
      toast.error('Please upload a banner image')
      return
    }

    setIsSaving(true)
    try {
      const payload = {
        title: title.trim(),
        subtitle: subtitle.trim(),
        ctaText: ctaText.trim() || 'Shop Now',
        linkTarget: linkTarget.trim(),
        route: route.trim(),
        status,
        position: position ? Number(position) : undefined,
        gradientFrom: primaryColor,
        gradientTo: secondaryColor,
        imageFile: imageFile || undefined,
        imageUrl: !imageFile ? selected?.imageUrl || imagePreview || '' : undefined,
      }

      if (isEdit) {
        await updateBanner(selected.id, payload)
        toast.success('Banner updated')
      } else {
        await addBanner(payload)
        toast.success('Banner created')
      }
      navigate('/banners')
    } catch (error) {
      toast.error(error?.message || 'Failed to save banner')
    } finally {
      setIsSaving(false)
    }
  }

  const previewSrc = imagePreview || selected?.imageUrl

  return (
    <div className="space-y-6">
      <PageHeader title={isEdit ? 'Edit Banner' : 'Add Banner'} subtitle="Hero Banners > Add/Edit" />

      <form onSubmit={onSubmit} className="grid gap-6 xl:grid-cols-3">
        <div className="space-y-6 xl:col-span-2">
          <Card>
            <h3 className="mb-4 font-semibold">Banner Details</h3>
            <div className="grid gap-4 md:grid-cols-2">
              <div className="md:col-span-2">
                <label className="mb-1 block text-sm font-medium">Title</label>
                <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Visiting Cards from ₹149" />
              </div>
              <div className="md:col-span-2">
                <label className="mb-1 block text-sm font-medium">Subtitle</label>
                <Input value={subtitle} onChange={(e) => setSubtitle(e.target.value)} placeholder="Premium quality, fast delivery" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">CTA Text</label>
                <Input value={ctaText} onChange={(e) => setCtaText(e.target.value)} placeholder="Shop Now" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Status</label>
                <Select value={status} onChange={(e) => setStatus(e.target.value)}>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </Select>
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Link Target</label>
                <Input value={linkTarget} onChange={(e) => setLinkTarget(e.target.value)} placeholder="CAT001 or /products/visiting-cards" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Route</label>
                <Input value={route} onChange={(e) => setRoute(e.target.value)} placeholder="/products/visiting-cards" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Position</label>
                <Input type="number" min="1" value={position} onChange={(e) => setPosition(e.target.value)} placeholder="1" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Primary Color</label>
                <Input type="color" value={primaryColor} onChange={(e) => setPrimaryColor(e.target.value)} className="h-10 p-1" />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Secondary Color</label>
                <Input type="color" value={secondaryColor} onChange={(e) => setSecondaryColor(e.target.value)} className="h-10 p-1" />
              </div>
            </div>
          </Card>

          <Card>
            <div className="space-y-2">
              <Button type="button" variant="secondary" className="w-full" onClick={() => navigate('/banners')}>Cancel</Button>
              <Button type="submit" className="w-full" loading={isSaving}>{isEdit ? 'Update Banner' : 'Save Banner'}</Button>
            </div>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <h3 className="mb-4 font-semibold">Banner Image</h3>
            <ImageUploadBox
              label="Upload banner image"
              hint="Recommended 1600x600 JPG/PNG"
              currentImage={previewSrc}
              onFile={handleFile}
            />
          </Card>

          <Card>
            <h3 className="mb-3 font-semibold">Preview</h3>
            <div className="overflow-hidden rounded-2xl bg-gray-900">
              <div className="relative h-44 text-white">
                {previewSrc ? (
                  <img src={previewSrc} alt={title || 'Banner preview'} className="h-full w-full object-cover" />
                ) : (
                  <div className="h-full w-full" style={{ background: `linear-gradient(90deg, ${primaryColor}, ${secondaryColor})` }} />
                )}
                <div className="absolute inset-0 bg-black/30" />
                <div className="absolute inset-x-0 bottom-0 p-4">
                  <p className="text-lg font-semibold">{title || 'Banner title'}</p>
                  <p className="text-sm text-white/80">{subtitle || 'Banner subtitle'}</p>
                </div>
              </div>
            </div>
          </Card>
        </div>
      </form>
    </div>
  )
}
