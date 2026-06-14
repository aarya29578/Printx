# PrintX Admin Panel

Production-ready React Web Admin Panel for PrintX (custom printing and branded merchandise platform), built as a separate project under `D:\app\printx\admin_panel`.

## Tech Stack

- React 18 + Vite
- JavaScript (JSX)
- Tailwind CSS v3
- React Router v6
- Zustand
- TanStack Table v8
- Recharts + React ApexCharts
- React Hook Form + Zod
- React Hot Toast
- React Dropzone
- React DatePicker
- React Quill
- jsPDF + jsPDF-AutoTable
- PapaParse
- Framer Motion
- dnd-kit (sortable)

## Getting Started

1. Install dependencies:

```bash
npm install
```

2. Start dev server:

```bash
npm run dev
```

3. Open:

- `http://localhost:5173`

## Demo Login

- Email: `admin@printx.in`
- Password: `Admin@123`

## Production Build

```bash
npm run build
npm run preview
```

Build output is generated in `dist/`.

## Key Features

- Protected admin routing with persisted auth
- Responsive admin shell (sidebar + topbar + breadcrumb)
- Dark mode toggle persisted in localStorage
- Dashboard with stats, charts, and recent data blocks
- Product management with add/edit form validation (RHF + Zod)
- Orders table + order detail + invoice PDF export
- Customers, coupons, templates, reviews, notifications modules
- Category and banner drag-reorder (dnd-kit)
- Shared reusable component system (buttons, modal, badge, table, etc.)
- CSV export support for tables
- Typed confirmation flow for destructive actions
- Mock-data-first architecture using Zustand stores (no real backend calls)

## Project Structure

The implementation follows the requested modular folder architecture:

- `src/core` for constants/theme/utils
- `src/components` for layout/ui/data/forms/charts
- `src/pages` for route-level feature pages
- `src/store` for Zustand domain stores
- `src/data/mockData.js` for all mock datasets

## Notes

- All amounts use INR formatting helpers.
- All date displays use Indian-style date formatting helpers.
- No real API dependency is required; state is in-memory via stores.
