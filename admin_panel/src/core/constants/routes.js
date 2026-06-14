export const routeItems = [
  { group: 'MAIN', items: [
    { label: 'Dashboard', path: '/dashboard', icon: 'LayoutDashboard' },
    { label: 'Products', path: '/products', icon: 'Package' },
    { label: 'Categories', path: '/categories', icon: 'Grid3x3' },
    { label: 'Hero Banners', path: '/banners', icon: 'Image' },
    { label: 'Templates', path: '/templates', icon: 'Palette' },
  ] },
  { group: 'COMMERCE', items: [
    { label: 'Orders', path: '/orders', icon: 'ShoppingBag', badge: 'pendingOrders' },
    { label: 'Customers', path: '/customers', icon: 'Users' },
    { label: 'Coupons & Offers', path: '/coupons', icon: 'Tag' },
    { label: 'Reviews', path: '/reviews', icon: 'Star', badge: 'pendingReviews' },
  ] },
  { group: 'SETTINGS', items: [
    { label: 'Push Notifications', path: '/notifications', icon: 'Bell' },
    { label: 'Delivery Settings', path: '/delivery', icon: 'Truck' },
    { label: 'Pricing Rules', path: '/pricing', icon: 'Calculator' },
    { label: 'Admin Users', path: '/admin-users', icon: 'ShieldCheck' },
    { label: 'General Settings', path: '/settings', icon: 'Settings' },
  ] },
]
