# DataTable / ProductsPage visibility issue (TEST123 not visible)

## Goal
Determine why a product that is present in `filtered` is not visible in the rendered table rows.

## What we found
- `ProductsPage.jsx` renders `DataTable data={filtered}`.
- `DataTable.jsx` uses TanStack Table with:
  - `getCoreRowModel()`, `getSortedRowModel()`, `getFilteredRowModel()`, `getPaginationRowModel()`
  - `globalFilterFn` that filters on `row.original`.
  - It renders `table.getRowModel().rows` (which is affected by pagination and filtering).

## DataTable to instrument
- File: `printx/admin_panel/src/components/data/DataTable.jsx`

Add logs around where rows are determined, e.g.:
- `const rowModelRows = table.getRowModel().rows`
- `const visibleRows = table.getVisibleRowModel().rows`
- log `globalFilter`, `table.getState().pagination`, `table.getState().sorting`, and the first few row ids.

## ProductsPage to instrument further (if needed)
- File: `printx/admin_panel/src/pages/products/ProductsPage.jsx`

Add logs for current filter UI state and whether target ids are in `filtered`.

## Pagination code reference (current)
- `DataTable.jsx` initializes:
  - `const [pagination, setPagination] = useState({ pageIndex: 0, pageSize })`
  - and `useReactTable({ state: { ..., pagination, ... }, onPaginationChange: setPagination, getPaginationRowModel() })`
- Pagination UI calls:
  - `onChange={(page) => table.setPageIndex(page - 1)}`

## Why TEST123 might be missing
Likely causes to verify with logs:
1. TanStack `globalFilter` inside DataTable (separate from ProductsPage query/category/status) excludes TEST123.
2. `table` pagination hides it on another page (pageIndex not 0).
3. Sorting or row key mismatch (less likely).

## What to paste back
After adding logs and reproducing the issue, paste:
- `[TABLE_DEBUG]` output including:
  - `globalFilter`
  - `pagination` state
  - `rowModelRows.length`
  - ids of the rendered rows (up to ~30)
- `filtered` length from ProductsPage

