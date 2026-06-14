import { z } from 'zod'

export const loginSchema = z.object({
  email: z.string().email('Enter a valid email'),
  password: z.string().min(6, 'Password is required'),
})

export const productSchema = z.object({
}).passthrough()

export const couponSchema = z.object({
  code: z.string().min(4, 'Coupon code is required'),
  type: z.enum(['flat', 'percentage', 'free_shipping']),
  value: z.coerce.number().min(0),
  minOrder: z.coerce.number().min(0),
})
