import { useMemo, useState, useEffect } from 'react'
import { useParams, useNavigate, useSearchParams } from 'react-router-dom'
import { useForm, Controller } from 'react-hook-form'
import toast from 'react-hot-toast'
import { useProductsStore } from '../../store/productsStore'
import { useCategoriesStore } from '../../store/categoriesStore'
import PageHeader from '../../components/ui/PageHeader'
import Card from '../../components/ui/Card'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import Button from '../../components/ui/Button'
import Toggle from '../../components/ui/Toggle'
import RichTextEditor from '../../components/forms/RichTextEditor'
import TagInput from '../../components/forms/TagInput'
import ImageUploadBox from '../../components/forms/ImageUploadBox'
import DateRangePicker from '../../components/forms/DateRangePicker'

export default function AddEditProductPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const { products, addProduct, updateProduct, deleteProduct, loadProducts } = useProductsStore()
  const { categories, refreshCategory } = useCategoriesStore()
  const [tags, setTags] = useState([])
  const [featured, setFeatured] = useState(false)
  const [newArrival, setNewArrival] = useState(false)
  const [publishDate, setPublishDate] = useState([null, null])
  const [imageFile, setImageFile] = useState(null)
  const [imagePreview, setImagePreview] = useState('')

  const selected = useMemo(() => products.find((p) => p.id === id), [products, id])
  const isEdit = Boolean(selected)
  const prefillCategory = searchParams.get('category') || ''

  const {
    register,
    handleSubmit,
    control,
    setValue,
    getValues,
    formState: { isSubmitting },
  } = useForm({
    defaultValues: {
      name: selected?.name || '',
      description: selected?.description || '',
      category: selected?.category || prefillCategory,
      basePrice: selected?.basePrice || 0,
      status: selected?.status || 'active',
      minQty: selected?.minQty || 1,
      sizes: selected?.sizes || [],
      finishes: selected?.finishes || [],
    },
  })

  useEffect(() => {
    if (!selected && prefillCategory) {
      setValue('category', prefillCategory, { shouldValidate: true })
    }
  }, [prefillCategory, selected, setValue])

  useEffect(() => {
    if (!selected) return
    setValue('name', selected.name || '')
    setValue('description', selected.description || '')
    // Category stored as category ID (document ID in Firestore)
    setValue('category', selected.category || '')
    setValue('basePrice', selected.basePrice ?? '')
    setValue('status', selected.status || 'active')
    setValue('minQty', selected.minQty ?? '')
    setValue('sizes', selected.sizes || [])
    setValue('finishes', selected.finishes || [])
    setTags(selected.tags || [])
    setFeatured(Boolean(selected.isBestseller))
    setNewArrival(Boolean(selected.isNew))
    setImageFile(null)
    setImagePreview(selected.imageUrl || '')
  }, [selected])

  const handleFile = async (file) => {
    if (!file) {
      setImageFile(null)
      setImagePreview('')
      return
    }
    setImageFile(file)
    setImagePreview(URL.createObjectURL(file))
  }

  const onSubmit = async (values) => {
      console.log("================================");
  console.log("FORM SUBMIT STARTED");
  console.log("FULL VALUES:", values);
  console.log("NAME:", values?.name);
  console.log("DESCRIPTION:", values?.description);
  console.log("CATEGORY:", values?.category);
  console.log("BASE PRICE:", values?.basePrice);
  console.log("================================");
    // Normalize + de-duplicate (case-insensitive) while preserving original casing from input.
    const normalizeUnique = (arr) => {
      const seen = new Set()
      const out = []
      ;(arr || []).forEach((raw) => {
        const clean = String(raw ?? '').trim()
        if (!clean) return
        const key = clean.toLowerCase()
        if (seen.has(key)) return
        seen.add(key)
        out.push(clean)
      })
      return out
    }

    const sizes = normalizeUnique(values.sizes)
    const finishes = normalizeUnique(values.finishes)
    const minQty = values.minQty ?? ''
    
    // Category value is sent directly from dropdown as category ID (Firestore document ID)
    const categoryId = values.category || prefillCategory || ''
    
    const payload = {
      ...values,
      category: categoryId,  // Save as category ID
      // Ensure we ONLY write arrays (no comma-separated strings)
      sizes,
      finishes,
      quantities: minQty ? [minQty] : [],
      minQty: minQty || undefined,
      tags,
      featured,
      isNew: newArrival,
      publishDate,
      imageFile: imageFile || undefined,
      imageUrl: !imageFile ? selected?.imageUrl || imagePreview || 'https://picsum.photos/seed/new-product/400/300' : undefined,
      sku: selected?.sku || `SKU-${Date.now()}`,
      stock: selected?.stock || 'in_stock',
      // For update operations, pass old category for productCount adjustment
      ...(isEdit && { _previousCategory: selected?.category }),
    }

    try {
      if (isEdit) {
        const oldCategoryId = selected?.category
        await updateProduct(selected.id, payload)
        toast.success('Product updated')
        // Refresh both old and new categories
        if (oldCategoryId) await refreshCategory(oldCategoryId)
        if (categoryId && categoryId !== oldCategoryId) await refreshCategory(categoryId)
      } else {
        await addProduct(payload)
        toast.success('Product created')
        // Refresh the category
        if (categoryId) await refreshCategory(categoryId)
        // Reload products from Firestore to ensure fresh data
        await loadProducts()
      }
      navigate('/products')
    } catch (error) {
      toast.error(error?.message || 'Failed to save product')
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader title={isEdit ? `Edit Product: ${selected.name}` : 'Add Product'} subtitle="Products > Add/Edit" />

      <form onSubmit={handleSubmit(onSubmit)} className="grid gap-6 xl:grid-cols-3">
        <div className="space-y-6 xl:col-span-2">
          <Card>
            <h3 className="mb-4 font-semibold">Product Information</h3>
            <div className="grid gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium">Product Name</label>
                <Input {...register('name')} />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium">Description</label>
                <Controller name="description" control={control} render={({ field }) => <RichTextEditor value={field.value} onChange={field.onChange} />} />
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div>
                  <label className="mb-1 block text-sm font-medium">Category</label>
                  <Select {...register('category')}>
                    <option value="">Select category</option>
                    {categories.map((item) => (
                      <option key={item.id} value={item.id}>
                        {item.name}
                      </option>
                    ))}
                  </Select>
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium">Price per unit</label>
                  <Input type="text" {...register('basePrice')} />
                </div>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <div>
                  <label className="mb-1 block text-sm font-medium">Quantity</label>
                  <Input type="text" {...register('minQty')} />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium">Sizes</label>
                  <Controller
                    name="sizes"
                    control={control}
                    render={({ field }) => (
                      <TagInput
                        value={field.value || []}
                        placeholder="Type and press Enter (e.g. A4)"
                        onChange={(next) => {
                          const normalizeUnique = (arr) => {
                            const seen = new Set()
                            const out = []
                            ;(arr || []).forEach((raw) => {
                              const clean = String(raw ?? '').trim()
                              if (!clean) return
                              const key = clean.toLowerCase()
                              if (seen.has(key)) return
                              seen.add(key)
                              out.push(clean)
                            })
                            return out
                          }

                          field.onChange(normalizeUnique(next))
                        }}
                      />
                    )}
                  />
                </div>
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium">Finishes</label>
                <Controller
                  name="finishes"
                  control={control}
                  render={({ field }) => (
                    <TagInput
                      value={field.value || []}
                      placeholder="Type and press Enter (e.g. Matte)"
                      onChange={(next) => {
                        const normalizeUnique = (arr) => {
                          const seen = new Set()
                          const out = []
                          ;(arr || []).forEach((raw) => {
                            const clean = String(raw ?? '').trim()
                            if (!clean) return
                            const key = clean.toLowerCase()
                            if (seen.has(key)) return
                            seen.add(key)
                            out.push(clean)
                          })
                          return out
                        }

                        field.onChange(normalizeUnique(next))
                      }}
                    />
                  )}
                />
              </div>

              <div>
                <label className="mb-1 block text-sm font-medium">Tags</label>
                <TagInput value={tags} onChange={setTags} />
              </div>
            </div>
          </Card>

          <Card>
            <h3 className="mb-4 font-semibold">Status & Scheduling</h3>
            <div className="grid gap-4 md:grid-cols-2">
              <div>
                <label className="mb-1 block text-sm font-medium">Status</label>
                <Select {...register('status')}>
                  <option value="active">Active</option>
                  <option value="draft">Draft</option>
                  <option value="paused">Paused</option>
                </Select>
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium">Publish Window</label>
                <DateRangePicker value={publishDate} onChange={setPublishDate} />
              </div>
            </div>
            <div className="mt-4 flex items-center gap-6">
              <div className="flex items-center gap-2 text-sm"><Toggle checked={featured} onChange={setFeatured} /> Featured</div>
              <div className="flex items-center gap-2 text-sm"><Toggle checked={newArrival} onChange={setNewArrival} /> New arrival</div>
            </div>
          </Card>
        </div>

        <div className="space-y-6">
          <Card>
            <h3 className="mb-4 font-semibold">Product Images</h3>
            <ImageUploadBox
              label="Main image"
              hint="Recommended 1200x1200"
              currentImage={imagePreview || selected?.imageUrl}
              onFile={handleFile}
            />
          </Card>

          <Card>
            <div className="space-y-2">
              <Button type="button" variant="secondary" className="w-full">Save as Draft</Button>
              <Button type="submit" className="w-full" loading={isSubmitting}>{isEdit ? 'Update Product' : 'Publish Product'}</Button>
            </div>
          </Card>
        </div>
      </form>
    </div>
  )
}
