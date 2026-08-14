import { useState } from 'react'
import { useForm } from 'react-hook-form'
import toast from 'react-hot-toast'
import { useAuthStore } from '../../store/authStore'
import Input from '../../components/ui/Input'
import Button from '../../components/ui/Button'

export default function ProfilePage() {
  const admin = useAuthStore((s) => s.admin)
  const changeEmail = useAuthStore((s) => s.changeEmail)
  const changePassword = useAuthStore((s) => s.changePassword)

  const { register: regEmail, handleSubmit: submitEmail, formState: { isSubmitting: isEmailSubmitting } } = useForm({ defaultValues: { email: admin?.email || '' } })
  const { register: regPwd, handleSubmit: submitPwd, formState: { isSubmitting: isPwdSubmitting } } = useForm()

  const onEmail = async (values) => {
    try {
      await changeEmail(values.email, values.currentPassword)
      toast.success('Email updated')
    } catch (err) {
      toast.error(err?.message || 'Failed to change email')
    }
  }

  const onPassword = async (values) => {
    if (values.newPassword !== values.confirmPassword) {
      toast.error('New password and confirmation do not match')
      return
    }
    if ((values.newPassword || '').length < 8) {
      toast.error('Password must be at least 8 characters')
      return
    }
    try {
      await changePassword(values.currentPassword, values.newPassword)
      toast.success('Password updated')
    } catch (err) {
      toast.error(err?.message || 'Failed to change password')
    }
  }

  return (
    <div className="p-6">
      <h1 className="font-display text-2xl font-bold">Profile Settings</h1>
      <p className="text-sm text-gray-500">Manage your account email and password</p>

      <section className="mt-6 max-w-md">
        <h3 className="font-semibold">Change email</h3>
        <form onSubmit={submitEmail(onEmail)} className="space-y-3 mt-2">
          <label className="block text-xs text-gray-600">Current email</label>
          <Input value={admin?.email || ''} disabled />
          <label className="block text-xs text-gray-600">New email</label>
          <Input {...regEmail('email', { required: true })} />
          <label className="block text-xs text-gray-600">Current password</label>
          <Input type="password" {...regEmail('currentPassword', { required: true })} />
          <div className="flex justify-end">
            <Button type="submit" loading={isEmailSubmitting}>Update email</Button>
          </div>
        </form>
      </section>

      <section className="mt-8 max-w-md">
        <h3 className="font-semibold">Change password</h3>
        <form onSubmit={submitPwd(onPassword)} className="space-y-3 mt-2">
          <label className="block text-xs text-gray-600">Current password</label>
          <Input type="password" {...regPwd('currentPassword', { required: true })} />
          <label className="block text-xs text-gray-600">New password</label>
          <Input type="password" {...regPwd('newPassword', { required: true })} />
          <label className="block text-xs text-gray-600">Confirm new password</label>
          <Input type="password" {...regPwd('confirmPassword', { required: true })} />
          <div className="flex justify-end">
            <Button type="submit" loading={isPwdSubmitting}>Change password</Button>
          </div>
        </form>
      </section>
    </div>
  )
}
