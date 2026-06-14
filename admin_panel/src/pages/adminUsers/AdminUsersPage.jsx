import { useState } from 'react'
import { createColumnHelper } from '@tanstack/react-table'
import toast from 'react-hot-toast'
import PageHeader from '../../components/ui/PageHeader'
import DataTable from '../../components/data/DataTable'
import Button from '../../components/ui/Button'
import StatusBadge from '../../components/ui/Badge'
import Modal from '../../components/ui/Modal'
import Input from '../../components/ui/Input'
import Select from '../../components/ui/Select'
import ConfirmDialog from '../../components/ui/ConfirmDialog'
import { useAdminUsersStore } from '../../store/adminUsersStore'

const columnHelper = createColumnHelper()

export default function AdminUsersPage() {
  const { adminUsers, addAdmin, updateAdmin, deactivateAdmin, deleteAdmin } = useAdminUsersStore()
  const [open, setOpen] = useState(false)
  const [deleteId, setDeleteId] = useState(null)
  const [form, setForm] = useState({ name: '', email: '', role: 'support' })

  const columns = [
    columnHelper.accessor('name', { header: 'Admin' }),
    columnHelper.accessor('email', { header: 'Email' }),
    columnHelper.accessor('role', {
      header: 'Role',
      cell: ({ row }) => (
        <Select
          className="w-36"
          value={row.original.role}
          onChange={(e) => {
            updateAdmin(row.original.id, { role: e.target.value })
            toast.success('Role updated')
          }}
        >
          <option value="super_admin">Super Admin</option>
          <option value="operations">Operations</option>
          <option value="support">Support</option>
          <option value="marketing">Marketing</option>
        </Select>
      ),
    }),
    columnHelper.accessor('lastLogin', { header: 'Last Login' }),
    columnHelper.accessor('status', {
      header: 'Status',
      cell: ({ row }) => (
        <div className="flex items-center gap-2">
          <StatusBadge status={row.original.status} />
          <Button
            size="sm"
            variant="secondary"
            onClick={() => {
              if (row.original.status === 'active') {
                deactivateAdmin(row.original.id)
                toast.success('Admin deactivated')
              } else {
                updateAdmin(row.original.id, { status: 'active' })
                toast.success('Admin activated')
              }
            }}
          >
            {row.original.status === 'active' ? 'Disable' : 'Enable'}
          </Button>
        </div>
      ),
    }),
    columnHelper.display({
      id: 'actions',
      header: 'Actions',
      cell: ({ row }) => (
        <Button size="sm" variant="danger" onClick={() => setDeleteId(row.original.id)}>Delete</Button>
      ),
    }),
  ]

  const invite = () => {
    if (!form.name.trim() || !form.email.trim()) {
      toast.error('Name and email are required')
      return
    }

    addAdmin({
      id: `admin-${Date.now()}`,
      name: form.name,
      email: form.email,
      role: form.role,
      lastLogin: 'Never',
      status: 'active',
    })
    setOpen(false)
    setForm({ name: '', email: '', role: 'support' })
    toast.success('Admin invited')
  }

  return (
    <div className="space-y-4">
      <PageHeader title="Admin Users" actions={<Button onClick={() => setOpen(true)}>Invite Admin</Button>} />
      <DataTable data={adminUsers} columns={columns} />

      <Modal
        isOpen={open}
        onClose={() => setOpen(false)}
        title="Invite Admin User"
        footer={(
          <div className="flex justify-end gap-2">
            <Button variant="secondary" onClick={() => setOpen(false)}>Cancel</Button>
            <Button onClick={invite}>Send Invite</Button>
          </div>
        )}
      >
        <div className="grid gap-3">
          <Input placeholder="Full name" value={form.name} onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))} />
          <Input placeholder="Email" value={form.email} onChange={(e) => setForm((prev) => ({ ...prev, email: e.target.value }))} />
          <Select value={form.role} onChange={(e) => setForm((prev) => ({ ...prev, role: e.target.value }))}>
            <option value="super_admin">Super Admin</option>
            <option value="operations">Operations</option>
            <option value="support">Support</option>
            <option value="marketing">Marketing</option>
          </Select>
        </div>
      </Modal>

      <ConfirmDialog
        isOpen={Boolean(deleteId)}
        onClose={() => setDeleteId(null)}
        onConfirm={() => {
          deleteAdmin(deleteId)
          toast.success('Admin deleted')
        }}
        title="Delete Admin"
        description="This action removes access for the selected admin user."
      />
    </div>
  )
}
