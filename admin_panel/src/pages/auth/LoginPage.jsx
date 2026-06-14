import { useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { AlertCircle, Copy, Eye, EyeOff, Lock, Mail } from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import { AnimatePresence, motion } from 'framer-motion'
import toast from 'react-hot-toast'
import { useAuthStore } from '../../store/authStore'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'

export default function LoginPage() {
  const navigate = useNavigate()
  const login = useAuthStore((state) => state.login)
  const [showPass, setShowPass] = useState(false)
  const [error, setError] = useState('')
  const [rememberMe, setRememberMe] = useState(Boolean(localStorage.getItem('printx-remember-email')))

  const rememberedEmail = localStorage.getItem('printx-remember-email') || 'admin@printx.in'

  const {
    register,
    handleSubmit,
    setValue,
    formState: { isSubmitting },
    watch,
  } = useForm({
    defaultValues: { email: rememberedEmail, password: 'Admin@123' },
  })

  useEffect(() => {
    if (rememberMe) {
      localStorage.setItem('printx-remember-email', watch('email') || '')
    }
  }, [rememberMe, watch])

  const onSubmit = async (values) => {
    setError('')
    if (rememberMe) {
      localStorage.setItem('printx-remember-email', values.email)
    } else {
      localStorage.removeItem('printx-remember-email')
    }
    const ok = login(values.email, values.password)
    if (!ok) {
      setError('Invalid credentials')
      return
    }
    toast.success('Welcome back, Rahul! 👋')
    navigate('/dashboard')
  }

  const copyText = async (text) => {
    await navigator.clipboard.writeText(text)
    toast.success('Copied!')
  }

  return (
    <div className="grid min-h-screen lg:grid-cols-2">
      <div className="relative hidden overflow-hidden bg-gradient-to-br from-indigo-600 to-purple-700 p-12 text-white lg:block">
        <div className="relative z-10 flex h-full flex-col justify-between">
          <div>
            <h1 className="font-display text-5xl font-bold">PrintX</h1>
            <p className="mt-2 text-white/80">Admin Panel</p>
            <h2 className="mt-6 max-w-md font-display text-3xl font-semibold">Manage your entire printing business from one place</h2>
          </div>
          <p className="text-sm text-white/60">Powering 10,000+ businesses across India</p>
        </div>

        <div className="absolute right-16 top-20 h-52 w-64 rotate-[-6deg] rounded-2xl bg-white/10 shadow-2xl" />
        <div className="absolute left-12 top-52 h-40 w-56 rotate-[3deg] rounded-2xl bg-white/10 shadow-xl" />
        <div className="absolute bottom-20 right-24 h-44 w-60 rotate-[12deg] rounded-2xl bg-white/10 shadow-xl" />
      </div>

      <div className="flex items-center justify-center bg-white p-6 dark:bg-gray-900">
        <motion.div className="w-full max-w-md rounded-2xl border border-gray-100 p-8 shadow-card dark:border-gray-700 dark:bg-gray-800" initial={{ opacity: 0, y: 16 }} animate={{ opacity: 1, y: 0 }}>
          <h2 className="font-display text-3xl font-bold dark:text-white">Welcome back 👋</h2>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Sign in to continue</p>

          <form onSubmit={handleSubmit(onSubmit)} className="mt-6 space-y-4">
            <div>
              <label className="mb-1 block text-sm font-medium">Email</label>
              <div className="relative">
                <Mail className="pointer-events-none absolute left-3 top-3.5 h-4 w-4 text-gray-400" />
                <Input {...register('email')} className="pl-9" onChange={(e) => setValue('email', e.target.value)} />
              </div>
            </div>

            <div>
              <label className="mb-1 block text-sm font-medium">Password</label>
              <div className="relative">
                <Lock className="pointer-events-none absolute left-3 top-3.5 h-4 w-4 text-gray-400" />
                <Input {...register('password')} type={showPass ? 'text' : 'password'} className="pl-9 pr-9" />
                <button type="button" className="absolute right-3 top-3" onClick={() => setShowPass((v) => !v)}>
                  {showPass ? <EyeOff className="h-4 w-4 text-gray-400" /> : <Eye className="h-4 w-4 text-gray-400" />}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between text-sm">
              <label className="flex items-center gap-2">
                <input type="checkbox" checked={rememberMe} onChange={(e) => setRememberMe(e.target.checked)} />
                Remember me
              </label>
              <button type="button" className="text-primary-600">Forgot password?</button>
            </div>

            <AnimatePresence>
              {error && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: 'auto', opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  className="overflow-hidden"
                >
                  <div className="flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700">
                    <AlertCircle className="mt-0.5 h-4 w-4" />
                    <p>{error}</p>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>

            <Button type="submit" className="w-full" loading={isSubmitting}>Sign in</Button>
          </form>

          <div className="mt-4 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
            <p className="font-medium">Demo credentials</p>
            <button type="button" className="mt-1 flex items-center gap-2" onClick={() => copyText('admin@printx.in')}>
              Email: admin@printx.in <Copy className="h-3.5 w-3.5" />
            </button>
            <button type="button" className="mt-1 flex items-center gap-2" onClick={() => copyText('Admin@123')}>
              Password: Admin@123 <Copy className="h-3.5 w-3.5" />
            </button>
          </div>
        </motion.div>
      </div>
    </div>
  )
}
