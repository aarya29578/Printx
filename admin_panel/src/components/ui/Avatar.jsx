export default function Avatar({ name = 'User', size = 'md' }) {
  const dims = { sm: 'h-8 w-8 text-xs', md: 'h-10 w-10 text-sm', lg: 'h-14 w-14 text-lg' }
  const initials = name.split(' ').map((n) => n[0]).join('').slice(0, 2)
  return <div className={`grid ${dims[size]} place-items-center rounded-full bg-primary-600 font-semibold text-white`}>{initials}</div>
}
