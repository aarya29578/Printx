import { useEffect, useMemo, useState } from 'react'
import {
  createColumnHelper,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  useReactTable,
} from '@tanstack/react-table'
import { Download } from 'lucide-react'
import Input from '../ui/Input'
import EmptyState from '../ui/EmptyState'
import Skeleton from '../ui/Skeleton'
import Pagination from '../ui/Pagination'
import Button from '../ui/Button'
import { exportToCSV } from '../../core/utils/exportCSV'

const columnHelper = createColumnHelper()

export default function DataTable({
  data,
  columns,
  searchable = true,
  exportable = true,
  pageSize = 10,
  loading = false,
  selectable = false,
  onSelectionChange,
  onRowClick,
  emptyTitle,
  emptySubtitle,
}) {
  const [globalFilter, setGlobalFilter] = useState('')
  const [pagination, setPagination] = useState({ pageIndex: 0, pageSize })
  const [rowSelection, setRowSelection] = useState({})

  const mergedColumns = useMemo(() => {
    if (!selectable) return columns
    return [
      columnHelper.display({
        id: 'select',
        header: ({ table }) => (
          <input
            type="checkbox"
            checked={table.getIsAllPageRowsSelected()}
            onChange={table.getToggleAllPageRowsSelectedHandler()}
            aria-label="Select all rows"
          />
        ),
        cell: ({ row }) => (
          <input
            type="checkbox"
            checked={row.getIsSelected()}
            disabled={!row.getCanSelect()}
            onChange={row.getToggleSelectedHandler()}
            aria-label="Select row"
          />
        ),
      }),
      ...columns,
    ]
  }, [columns, selectable])

  const table = useReactTable({
    data,
    columns: mergedColumns,
    state: { globalFilter, pagination, rowSelection },
    onGlobalFilterChange: setGlobalFilter,
    onPaginationChange: setPagination,
    onRowSelectionChange: setRowSelection,
    enableRowSelection: selectable,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    globalFilterFn: (row, _columnId, filterValue) => {
      return Object.values(row.original).join(' ').toLowerCase().includes(String(filterValue).toLowerCase())
    },
  })

  useEffect(() => {
    if (!onSelectionChange) return
    const selected = table.getSelectedRowModel().rows.map((row) => row.original)
    onSelectionChange(selected)
  }, [rowSelection, table, onSelectionChange])

  const csvRows = useMemo(() => data.map((item) => JSON.parse(JSON.stringify(item))), [data])

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-2">
        {searchable ? (
          <Input value={globalFilter ?? ''} onChange={(e) => setGlobalFilter(e.target.value)} placeholder="Search..." className="w-72" />
        ) : <span />}
        {exportable && (
          <Button variant="secondary" icon={Download} onClick={() => exportToCSV(csvRows, 'table-export')}>Export CSV</Button>
        )}
      </div>

      <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-slate-700">
        <table className="min-w-[800px] w-full">
          <thead className="bg-gray-50 dark:bg-slate-800">
            {table.getHeaderGroups().map((headerGroup) => (
              <tr key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <th
                    key={header.id}
                    className="cursor-pointer px-4 py-3 text-left text-xs uppercase tracking-wider text-gray-500"
                    onClick={header.column.getToggleSortingHandler()}
                  >
                    {flexRender(header.column.columnDef.header, header.getContext())}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody>
            {loading && Array.from({ length: 5 }).map((_, idx) => (
              <tr key={idx} className="border-b border-gray-100">
                <td colSpan={mergedColumns.length} className="px-4 py-3"><Skeleton className="h-6 w-full" /></td>
              </tr>
            ))}
            {!loading && table.getRowModel().rows.length === 0 && (
              <tr>
                <td colSpan={mergedColumns.length} className="p-6">
                  <EmptyState title={emptyTitle} description={emptySubtitle} />
                </td>
              </tr>
            )}
            {!loading && table.getRowModel().rows.map((row) => (
              <tr
                key={row.id}
                className="border-b border-gray-100 transition hover:bg-gray-50 dark:hover:bg-slate-800/60"
                onClick={() => onRowClick?.(row.original)}
                style={{ cursor: onRowClick ? 'pointer' : 'default' }}
              >
                {row.getVisibleCells().map((cell) => (
                  <td key={cell.id} className="px-4 py-3 text-sm text-gray-700 dark:text-gray-200">
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex items-center justify-between">
        <select
          value={table.getState().pagination.pageSize}
          onChange={(e) => table.setPageSize(Number(e.target.value))}
          className="h-9 rounded-lg border border-gray-200 px-2 text-sm"
        >
          {[10, 25, 50, 100].map((size) => <option key={size} value={size}>{size} / page</option>)}
        </select>
        <Pagination
          page={table.getState().pagination.pageIndex + 1}
          totalPages={table.getPageCount() || 1}
          onChange={(page) => table.setPageIndex(page - 1)}
        />
      </div>
    </div>
  )
}
