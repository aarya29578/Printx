import { useForm } from 'react-hook-form'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import Card from '../../components/ui/Card'
import Input from '../../components/ui/Input'
import Textarea from '../../components/ui/Textarea'
import Select from '../../components/ui/Select'
import Button from '../../components/ui/Button'
import { useNotificationsStore } from '../../store/notificationsStore'
import DataTable from '../../components/data/DataTable'
import { createColumnHelper } from '@tanstack/react-table'

const columnHelper = createColumnHelper()

export default function PushNotificationsPage() {
  const { notifications, sendNotification } = useNotificationsStore()
  const { register, handleSubmit, watch, reset } = useForm({
    defaultValues: { title: '', message: '', target: 'all', type: 'promotional' },
  })

  const onSubmit = (values) => {
    sendNotification(values)
    toast.success('Notification sent')
    reset()
  }

  const columns = [
    columnHelper.accessor('title', { header: 'Title' }),
    columnHelper.accessor('sentTo', { header: 'Sent To' }),
    columnHelper.accessor('delivered', { header: 'Delivered' }),
    columnHelper.accessor('opened', { header: 'Opened' }),
    columnHelper.accessor('sentAt', { header: 'Date' }),
  ]

  return (
    <div className="grid gap-6 xl:grid-cols-3">
      <div className="space-y-6 xl:col-span-2">
        <PageHeader title="Push Notifications" />
        <Card>
          <h3 className="mb-4 font-semibold">Compose Notification</h3>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-3">
            <Input {...register('title')} placeholder="Title" maxLength={50} />
            <Textarea {...register('message')} rows={4} placeholder="Message" maxLength={150} />
            <div className="grid gap-3 md:grid-cols-2">
              <Select {...register('target')}>
                <option value="all">All Users</option>
                <option value="segment">Segment</option>
                <option value="specific">Specific Users</option>
              </Select>
              <Select {...register('type')}>
                <option value="promotional">Promotional</option>
                <option value="order_update">Order Update</option>
                <option value="offer">Offer</option>
                <option value="general">General</option>
              </Select>
            </div>
            <div className="flex justify-end gap-2">
              <Button type="button" variant="secondary">Preview</Button>
              <Button type="submit">Send Notification</Button>
            </div>
          </form>
        </Card>
        <Card>
          <h3 className="mb-3 font-semibold">Notification History</h3>
          <DataTable data={notifications} columns={columns} pageSize={5} />
        </Card>
      </div>
      <div className="space-y-6">
        <Card>
          <h3 className="mb-3 font-semibold">Phone Preview</h3>
          <div className="rounded-3xl bg-gray-800 p-4">
            <div className="rounded-xl bg-white p-3 shadow">
              <p className="text-xs text-gray-500">PrintX · now</p>
              <p className="text-sm font-medium">{watch('title') || 'Notification title'}</p>
              <p className="text-xs text-gray-500">{watch('message') || 'Your message will appear here'}</p>
            </div>
          </div>
        </Card>
      </div>
    </div>
  )
}
