const productBlueprints = [
  ['Premium Matte Visiting Cards', 'Visiting Cards', 'VC-MATTE-001'],
  ['Glossy Business Cards', 'Visiting Cards', 'VC-GLOSS-002'],
  ['Custom T-Shirt', 'T-Shirts & Apparel', 'APP-TSHIRT-003'],
  ['Standee Banner', 'Banners & Signage', 'BAN-STANDEE-004'],
  ['Coffee Mug', 'Drinkware', 'MUG-PRINT-005'],
  ['Tote Bag', 'Bags & Accessories', 'BAG-TOTE-006'],
  ['A4 Flyer', 'Flyers & Brochures', 'FLY-A4-007'],
  ['Notebook', 'Stationery', 'STN-NOTE-008'],
  ['Rubber Stamp', 'Office Essentials', 'OFF-STAMP-009'],
  ['Spot UV Cards', 'Visiting Cards', 'VC-SPOTUV-010'],
  ['Sticker Sheet', 'Stickers & Labels', 'LBL-STICK-011'],
  ['Foam Board', 'Banners & Signage', 'BAN-FOAM-012'],
  ['Custom Cap', 'T-Shirts & Apparel', 'APP-CAP-013'],
  ['Water Bottle', 'Drinkware', 'MUG-BOTTLE-014'],
  ['Wedding Card', 'Invitations', 'INV-WED-015'],
  ['Letterhead', 'Stationery', 'STN-LHEAD-016'],
  ['Envelope', 'Stationery', 'STN-ENV-017'],
  ['Lanyard', 'Bags & Accessories', 'ACC-LANYARD-018'],
  ['Photo Frame', 'Gifts', 'GFT-FRAME-019'],
  ['Umbrella', 'Gifts', 'GFT-UMBRELLA-020'],
]

const statuses = ['pending', 'design_review', 'printing', 'shipped', 'delivered', 'cancelled']
const cities = ['Mumbai', 'Delhi', 'Pune', 'Bengaluru', 'Hyderabad', 'Chennai', 'Ahmedabad']
const names = [
  'Rahul Sharma', 'Priya Patel', 'Amit Singh', 'Neha Joshi', 'Kiran Rao',
  'Suresh Kumar', 'Anjali Mehta', 'Vikram Nair', 'Rohan Desai', 'Sneha Iyer',
  'Arjun Kapoor', 'Pooja Verma', 'Deepak Yadav', 'Meera Nanda', 'Aditya Jain',
]
const payments = ['UPI', 'Card', 'COD', 'NetBanking']

// Category name to ID mapping
const categoryNameToId = {
  'Visiting Cards': 'CAT001',
  'T-Shirts & Apparel': 'CAT002',
  'Banners & Signage': 'CAT003',
  'Drinkware': 'CAT004',
  'Flyers & Brochures': 'CAT005',
  'Stationery': 'CAT006',
  'Office Essentials': 'CAT007',
  'Stickers & Labels': 'CAT008',
  'Invitations': 'CAT009',
  'Bags & Accessories': 'CAT010',
  'Gifts': 'CAT011',
  'Photo Prints': 'CAT012',
}

export const mockProducts = productBlueprints.map((item, index) => ({
  id: `PRD${String(index + 1).padStart(3, '0')}`,
  name: item[0],
  category: categoryNameToId[item[1]] || 'CAT001',
  sku: item[2],
  imageUrl: `https://picsum.photos/seed/printx-${index + 1}/400/300`,
  basePrice: 149 + index * 20,
  originalPrice: 299 + index * 35,
  discount: [10, 15, 20, 25, 30][index % 5],
  rating: Number((4.1 + (index % 9) * 0.1).toFixed(1)),
  reviewCount: 200 + index * 107,
  sales: 350 + index * 181,
  stock: ['in_stock', 'low_stock', 'out_of_stock'][index % 3],
  status: ['active', 'active', 'draft'][index % 3],
  isBestseller: index % 4 === 0,
  isNew: index % 5 === 0,
  finishes: ['Matte', 'Glossy', 'Spot UV'].slice(0, (index % 3) + 1),
  sizes: ['Standard', 'Square', 'Slim'].slice(0, (index % 3) + 1),
  gst: 18,
  createdAt: `2024-${String((index % 12) + 1).padStart(2, '0')}-15`,
  description: `${item[0]} crafted for professional branding with premium finish and durable print quality.`,
}))

export const mockCategories = [
  { id: 'CAT001', name: 'Visiting Cards', icon: 'credit-card', productCount: 48, color: '#4F46E5', status: 'active', order: 1 },
  { id: 'CAT002', name: 'T-Shirts & Apparel', icon: 'shirt', productCount: 36, color: '#06B6D4', status: 'active', order: 2 },
  { id: 'CAT003', name: 'Banners & Signage', icon: 'image', productCount: 20, color: '#F59E0B', status: 'active', order: 3 },
  { id: 'CAT004', name: 'Drinkware', icon: 'coffee', productCount: 18, color: '#EF4444', status: 'active', order: 4 },
  { id: 'CAT005', name: 'Flyers & Brochures', icon: 'file', productCount: 14, color: '#8B5CF6', status: 'active', order: 5 },
  { id: 'CAT006', name: 'Stationery', icon: 'book-open', productCount: 30, color: '#10B981', status: 'active', order: 6 },
  { id: 'CAT007', name: 'Office Essentials', icon: 'stamp', productCount: 12, color: '#EC4899', status: 'active', order: 7 },
  { id: 'CAT008', name: 'Stickers & Labels', icon: 'tag', productCount: 16, color: '#14B8A6', status: 'active', order: 8 },
  { id: 'CAT009', name: 'Invitations', icon: 'mail', productCount: 10, color: '#7C3AED', status: 'active', order: 9 },
  { id: 'CAT010', name: 'Bags & Accessories', icon: 'briefcase', productCount: 22, color: '#0EA5E9', status: 'active', order: 10 },
  { id: 'CAT011', name: 'Gifts', icon: 'gift', productCount: 17, color: '#F97316', status: 'active', order: 11 },
  { id: 'CAT012', name: 'Photo Prints', icon: 'image', productCount: 9, color: '#64748B', status: 'active', order: 12 },
]

export const mockOrders = Array.from({ length: 50 }, (_, index) => {
  const customerName = names[index % names.length]
  const city = cities[index % cities.length]
  const product = mockProducts[index % mockProducts.length]
  const status = statuses[index % statuses.length]
  const qty = [50, 100, 250, 500][index % 4]
  const amount = Math.round((product.basePrice * qty) / 100)

  return {
    id: `VPX-${20492 + index}`,
    customer: {
      name: customerName,
      email: `${customerName.toLowerCase().replace(' ', '.')}@email.com`,
      phone: `+91 98${String(76500000 + index).slice(-8)}`,
      city,
    },
    product: {
      name: product.name,
      specs: `${product.finishes[0]} · ${qty} qty · ${product.sizes[0]}`,
      thumbnail: product.imageUrl.replace('/400/300', '/80/80'),
    },
    qty,
    amount,
    payment: payments[index % payments.length],
    status,
    date: `2024-05-${String((index % 28) + 1).padStart(2, '0')}T${String((10 + index) % 24).padStart(2, '0')}:30:00`,
    deliveryType: ['Standard', 'Express', 'Same Day'][index % 3],
    address: `${101 + index}, Sector ${(index % 24) + 1}, ${city}`,
    trackingNumber: status === 'shipped' || status === 'delivered' ? `TRK${204920 + index}` : null,
    designFile: `design_VPX${20492 + index}.png`,
    adminNotes: [],
    timeline: [
      { step: 'Order Confirmed', done: true, time: `2024-05-${String((index % 28) + 1).padStart(2, '0')}T10:30:00` },
      { step: 'Design Approved', done: status !== 'pending', time: status !== 'pending' ? `2024-05-${String((index % 28) + 1).padStart(2, '0')}T11:00:00` : null },
      { step: 'Printing', done: ['printing', 'shipped', 'delivered'].includes(status), time: ['printing', 'shipped', 'delivered'].includes(status) ? `2024-05-${String((index % 28) + 1).padStart(2, '0')}T12:00:00` : null },
      { step: 'Quality Check', done: ['shipped', 'delivered'].includes(status), time: ['shipped', 'delivered'].includes(status) ? `2024-05-${String((index % 28) + 1).padStart(2, '0')}T13:00:00` : null },
      { step: 'Dispatched', done: ['shipped', 'delivered'].includes(status), time: ['shipped', 'delivered'].includes(status) ? `2024-05-${String((index % 28) + 1).padStart(2, '0')}T15:00:00` : null },
      { step: 'Delivered', done: status === 'delivered', time: status === 'delivered' ? `2024-05-${String((index % 28) + 1).padStart(2, '0')}T18:00:00` : null },
    ],
  }
})

export const mockCustomers = Array.from({ length: 30 }, (_, index) => ({
  id: `CUS${String(index + 1).padStart(3, '0')}`,
  name: names[index % names.length],
  email: `${names[index % names.length].toLowerCase().replace(' ', '.')}@gmail.com`,
  phone: `+91 98${String(76543210 + index).slice(-8)}`,
  city: cities[index % cities.length],
  avatar: null,
  orders: 2 + (index % 14),
  totalSpend: 2500 + index * 860,
  lastOrder: `2024-05-${String((index % 27) + 1).padStart(2, '0')}`,
  joinedAt: `2023-${String((index % 12) + 1).padStart(2, '0')}-10`,
  status: index % 8 === 0 ? 'blocked' : 'active',
  addresses: 1 + (index % 3),
}))

export const mockBanners = [
  {
    id: 'BAN001',
    title: 'Visiting Cards ₹149',
    subtitle: 'Premium matte finish, 100 cards',
    ctaText: 'Order Now',
    linkType: 'category',
    linkTarget: 'CAT001',
    gradientFrom: '#4F46E5',
    gradientTo: '#7C3AED',
    imageUrl: null,
    position: 1,
    status: 'active',
    schedule: { always: true, from: null, to: null },
  },
  {
    id: 'BAN002',
    title: 'Corporate Combo Deals',
    subtitle: 'Cards + Letterheads + Envelopes',
    ctaText: 'Explore',
    linkType: 'category',
    linkTarget: 'CAT006',
    gradientFrom: '#0EA5E9',
    gradientTo: '#14B8A6',
    imageUrl: null,
    position: 2,
    status: 'active',
    schedule: { always: true, from: null, to: null },
  },
  {
    id: 'BAN003',
    title: 'Wedding Season Specials',
    subtitle: 'Invitations from ₹999',
    ctaText: 'Shop Now',
    linkType: 'category',
    linkTarget: 'CAT009',
    gradientFrom: '#EC4899',
    gradientTo: '#F97316',
    imageUrl: null,
    position: 3,
    status: 'active',
    schedule: { always: false, from: '2024-05-25', to: '2024-06-30' },
  },
]

export const mockCoupons = [
  { id: 'CPN001', code: 'FIRST100', type: 'flat', value: 100, minOrder: 499, maxDiscount: null, usedCount: 234, usageLimit: 1000, perCustomer: 1, categories: [], newCustomersOnly: true, status: 'active', startsAt: '2024-01-01', expiresAt: '2024-12-31' },
  { id: 'CPN002', code: 'SAVE20', type: 'percentage', value: 20, minOrder: 999, maxDiscount: 500, usedCount: 780, usageLimit: 2000, perCustomer: 3, categories: ['CAT001'], newCustomersOnly: false, status: 'active', startsAt: '2024-01-01', expiresAt: '2024-12-31' },
  { id: 'CPN003', code: 'SHIPFREE', type: 'free_shipping', value: 0, minOrder: 799, maxDiscount: null, usedCount: 350, usageLimit: 1500, perCustomer: 2, categories: [], newCustomersOnly: false, status: 'active', startsAt: '2024-01-01', expiresAt: '2024-10-31' },
  { id: 'CPN004', code: 'FESTIVE30', type: 'percentage', value: 30, minOrder: 1499, maxDiscount: 700, usedCount: 1290, usageLimit: 1300, perCustomer: 1, categories: ['CAT009'], newCustomersOnly: false, status: 'paused', startsAt: '2024-05-01', expiresAt: '2024-06-01' },
  { id: 'CPN005', code: 'CORP250', type: 'flat', value: 250, minOrder: 2999, maxDiscount: null, usedCount: 110, usageLimit: 300, perCustomer: 2, categories: ['CAT006'], newCustomersOnly: false, status: 'scheduled', startsAt: '2024-06-01', expiresAt: '2024-09-01' },
  { id: 'CPN006', code: 'WELCOME15', type: 'percentage', value: 15, minOrder: 699, maxDiscount: 250, usedCount: 500, usageLimit: 5000, perCustomer: 1, categories: [], newCustomersOnly: true, status: 'active', startsAt: '2024-01-01', expiresAt: '2024-12-31' },
  { id: 'CPN007', code: 'PRINT50', type: 'flat', value: 50, minOrder: 399, maxDiscount: null, usedCount: 480, usageLimit: 480, perCustomer: 1, categories: [], newCustomersOnly: false, status: 'expired', startsAt: '2023-01-01', expiresAt: '2024-01-31' },
  { id: 'CPN008', code: 'BIGBULK', type: 'percentage', value: 25, minOrder: 4999, maxDiscount: 1500, usedCount: 90, usageLimit: 500, perCustomer: 5, categories: ['CAT001', 'CAT006'], newCustomersOnly: false, status: 'active', startsAt: '2024-02-15', expiresAt: '2024-12-31' },
]

export const mockTemplates = Array.from({ length: 15 }, (_, index) => ({
  id: `TPL${String(index + 1).padStart(3, '0')}`,
  name: ['Corporate Minimal', 'Festive Bold', 'Elegant Serif', 'Playful Pop'][index % 4],
  category: ['Visiting Cards', 'T-Shirts & Apparel', 'Drinkware', 'Banners & Signage'][index % 4],
  style: ['minimal', 'bold', 'elegant', 'playful', 'festive', 'corporate'][index % 6],
  thumbnail: `https://picsum.photos/seed/tpl-${index + 1}/300/180`,
  usageCount: 200 + index * 140,
  isPremium: index % 4 === 0,
  status: index % 7 === 0 ? 'draft' : 'active',
  tags: ['corporate', 'clean', 'professional'].slice(0, (index % 3) + 1),
  uploadedAt: `2024-${String((index % 12) + 1).padStart(2, '0')}-10`,
}))

export const mockReviews = Array.from({ length: 40 }, (_, index) => ({
  id: `REV${String(index + 1).padStart(3, '0')}`,
  customer: { name: names[index % names.length], avatar: null },
  product: { name: mockProducts[index % mockProducts.length].name, id: mockProducts[index % mockProducts.length].id },
  rating: [5, 4, 5, 3, 4][index % 5],
  text: 'Absolutely loved the print quality and finishing. Delivery was fast and packaging was secure.',
  photos: [],
  status: ['pending', 'approved', 'rejected', 'flagged'][index % 4],
  date: `2024-05-${String((index % 28) + 1).padStart(2, '0')}`,
}))

export const mockNotifications = Array.from({ length: 10 }, (_, index) => ({
  id: `NOT${String(index + 1).padStart(3, '0')}`,
  title: index === 0 ? 'Flash Sale Alert! 🔥' : `Campaign ${index + 1}`,
  message: 'Get amazing discounts on custom printing and branded merchandise.',
  target: 'all',
  sentTo: 8920,
  delivered: 8200 - index * 110,
  opened: 3200 - index * 180,
  sentAt: `2024-05-${String((index % 28) + 1).padStart(2, '0')}T09:00:00`,
  type: ['promotional', 'order_update', 'offer', 'general'][index % 4],
}))

export const mockAdminUsers = [
  { id: 'ADM001', name: 'Rahul Sharma', email: 'rahul@printx.in', role: 'superadmin', avatar: null, lastLogin: '2024-05-25T11:44:00', status: 'active', permissions: ['all'] },
  { id: 'ADM002', name: 'Priya Mehta', email: 'priya@printx.in', role: 'manager', avatar: null, lastLogin: '2024-05-24T10:20:00', status: 'active', permissions: ['orders', 'products'] },
  { id: 'ADM003', name: 'Amit Singh', email: 'amit@printx.in', role: 'support', avatar: null, lastLogin: '2024-05-25T09:00:00', status: 'active', permissions: ['orders', 'customers'] },
  { id: 'ADM004', name: 'Neha Joshi', email: 'neha@printx.in', role: 'finance', avatar: null, lastLogin: '2024-05-23T15:40:00', status: 'active', permissions: ['orders', 'refunds'] },
  { id: 'ADM005', name: 'Kiran Rao', email: 'kiran@printx.in', role: 'manager', avatar: null, lastLogin: '2024-05-20T12:20:00', status: 'inactive', permissions: ['products'] },
]

export const mockDashboardStats = {
  revenue: { value: 1284390, growth: 18.2 },
  orders: { value: 2847, growth: 12.5 },
  products: { value: 364, growth: 4 },
  customers: { value: 8920, growth: 321 },
  revenueChart: [
    { month: 'Jun', thisYear: 84000, lastYear: 62000 },
    { month: 'Jul', thisYear: 96000, lastYear: 71000 },
    { month: 'Aug', thisYear: 88000, lastYear: 65000 },
    { month: 'Sep', thisYear: 112000, lastYear: 79000 },
    { month: 'Oct', thisYear: 134000, lastYear: 91000 },
    { month: 'Nov', thisYear: 158000, lastYear: 108000 },
    { month: 'Dec', thisYear: 182000, lastYear: 124000 },
    { month: 'Jan', thisYear: 143000, lastYear: 98000 },
    { month: 'Feb', thisYear: 121000, lastYear: 87000 },
    { month: 'Mar', thisYear: 139000, lastYear: 103000 },
    { month: 'Apr', thisYear: 167000, lastYear: 118000 },
    { month: 'May', thisYear: 198000, lastYear: 142000 },
  ],
  ordersByStatus: [
    { name: 'Delivered', value: 1076, color: '#10B981' },
    { name: 'Printing', value: 892, color: '#4F46E5' },
    { name: 'Shipped', value: 634, color: '#3B82F6' },
    { name: 'Pending', value: 245, color: '#F59E0B' },
  ],
  topProducts: [
    { name: 'Matte Visiting Cards', revenue: 284390, orders: 1420 },
    { name: 'Custom T-Shirt', revenue: 198240, orders: 567 },
    { name: 'Coffee Mug', revenue: 156780, orders: 524 },
    { name: 'Standee Banner', revenue: 134200, orders: 149 },
    { name: 'Glossy Business Card', revenue: 98450, orders: 661 },
  ],
  categoryBreakdown: [
    { category: 'Visiting Cards', orders: 1420 },
    { category: 'Apparel', orders: 567 },
    { category: 'Drinkware', orders: 524 },
    { category: 'Banners', orders: 312 },
    { category: 'Stationery', orders: 289 },
    { category: 'Gifts', orders: 198 },
  ],
}
