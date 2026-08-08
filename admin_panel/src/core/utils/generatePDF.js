import jsPDF from 'jspdf'
import autoTable from 'jspdf-autotable'

export function generateInvoicePDF(order) {
  // Normalize order shape: support both Firestore-style and store-style objects.
  const normalizedOrder = Object.assign({}, order)
  if (!normalizedOrder.id) normalizedOrder.id = order.orderId || order.id || (order.name && order.name.split('/').pop())
  normalizedOrder.customer = normalizedOrder.customer || {
    name: order.userName || order.userEmail || '—',
    email: order.userEmail || '',
    phone: order.userPhone || '',
  }
  normalizedOrder.address = normalizedOrder.address || order.deliveryAddress || order.address || ''
  normalizedOrder.date = normalizedOrder.date || order.createdAt || order.date || new Date().toISOString()
  normalizedOrder.items = Array.isArray(order.items) ? order.items : (order.items && order.items.arrayValue ? (order.items.arrayValue.values || []).map(v => v.mapValue.fields) : order.items || [])
  order = normalizedOrder
  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' })

  doc.setFillColor(79, 70, 229)
  doc.rect(0, 0, 210, 40, 'F')

  doc.setTextColor(255, 255, 255)
  doc.setFontSize(24)
  doc.setFont('helvetica', 'bold')
  doc.text('PrintX', 20, 18)

  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.text('admin@printx.in  |  support.printx.in  |  +91 1800-PRINTX', 20, 27)
  doc.text('Mumbai, Maharashtra, India — 400001', 20, 33)

  doc.setFontSize(28)
  doc.setFont('helvetica', 'bold')
  doc.text('INVOICE', 210, 18, { align: 'right' })
  doc.setFontSize(11)
  doc.setFont('helvetica', 'normal')
  doc.text(`#${order.id}`, 190, 27, { align: 'right' })

  doc.setTextColor(17, 24, 39)

  doc.setFontSize(9)
  doc.setTextColor(107, 114, 128)
  doc.text('BILL TO', 20, 52)
  doc.text('INVOICE DATE', 120, 52)
  doc.text('DUE DATE', 165, 52)

  doc.setTextColor(17, 24, 39)
  doc.setFont('helvetica', 'bold')
  doc.setFontSize(11)
  doc.text(order.customer.name, 20, 59)

  doc.setFont('helvetica', 'normal')
  doc.setFontSize(10)
  doc.text(order.customer.phone || '', 20, 65)
  doc.text(order.customer.email || '', 20, 71)
  doc.text(order.address || 'Mumbai, Maharashtra', 20, 77)

  const dateText = new Date(order.date).toLocaleDateString('en-IN')
  doc.setFont('helvetica', 'bold')
  doc.text(dateText, 120, 59)
  doc.text(dateText, 165, 59)

  // Build table rows from order.items when available
  const rows = []
  if (Array.isArray(order.items) && order.items.length > 0) {
    for (let i = 0; i < order.items.length; i++) {
      const it = order.items[i]
      const qty = Number(it.quantity || it.qty || 1)
      const basePrice = Number(it.price || it.basePrice || 0)
      // basePrice is charged per 100 units (group). Minimum 1 group.
      const groups = Math.max(1, Math.floor(qty / 100))
      const lineTotal = basePrice * groups
      const specs = [it.size || '', it.finish || ''].filter(Boolean).join(' · ')
      rows.push([String(i + 1), it.productName || it.name || '—', specs, String(qty), `Rs. ${basePrice}`, `Rs. ${lineTotal}`])
    }
  } else {
    // Fallback to previous single-product layout
    const qty = Number(order.qty || 1)
    const unit = Number((order.amount || 0) * 0.82 / Math.max(qty, 1))
    rows.push(['1', order.product?.name || '—', order.product?.specs || '', String(qty), `Rs. ${unit}`, `Rs. ${(order.amount || 0) * 0.82}`])
  }

  autoTable(doc, {
    startY: 90,
    head: [['#', 'Product', 'Specifications', 'Qty', 'Unit Price', 'Total']],
    body: rows,
    styles: { fontSize: 10, cellPadding: 6 },
    headStyles: {
      fillColor: [79, 70, 229],
      textColor: [255, 255, 255],
      fontSize: 10,
      fontStyle: 'bold',
    },
    columnStyles: {
      0: { cellWidth: 10 },
      1: { cellWidth: 55 },
      2: { cellWidth: 55 },
      3: { cellWidth: 15, halign: 'center' },
      4: { cellWidth: 28, halign: 'right' },
      5: { cellWidth: 28, halign: 'right' },
    },
    alternateRowStyles: { fillColor: [248, 247, 255] },
  })

  const finalY = doc.lastAutoTable.finalY + 8
  // Calculate totals from items when present, else fallback
  let subtotal = 0
  if (Array.isArray(order.items) && order.items.length > 0) {
    subtotal = order.items.reduce((s, it) => {
      const qty = Number(it.quantity || it.qty || 1)
      const basePrice = Number(it.price || it.basePrice || 0)
      const groups = Math.max(1, Math.floor(qty / 100))
      return s + basePrice * groups
    }, 0)
  } else {
    subtotal = Number(order.amount || 0) * 0.82
  }
  const gst = Math.round(subtotal * 0.18)
  const total = subtotal + gst

  doc.setFontSize(10)
  doc.setTextColor(107, 114, 128)
  doc.text('Subtotal:', 145, finalY)
  doc.text('GST (18%):', 145, finalY + 7)
  doc.text('Shipping:', 145, finalY + 14)

  doc.setTextColor(17, 24, 39)
  doc.text(`Rs. ${subtotal.toFixed(0)}`, 190, finalY, { align: 'right' })
  doc.text(`Rs. ${gst.toFixed(0)}`, 190, finalY + 7, { align: 'right' })
  doc.text('Free', 190, finalY + 14, { align: 'right' })

  doc.setFillColor(79, 70, 229)
  doc.rect(130, finalY + 18, 65, 12, 'F')
  doc.setTextColor(255, 255, 255)
  doc.setFont('helvetica', 'bold')
  doc.setFontSize(11)
  doc.text('TOTAL:', 135, finalY + 26)
  doc.text(`Rs. ${total}`, 190, finalY + 26, { align: 'right' })

  doc.setTextColor(17, 24, 39)
  doc.setFont('helvetica', 'normal')
  doc.setFontSize(10)
  doc.text(`Payment Method: ${order.payment}`, 20, finalY + 10)
  doc.text('Payment Status: PAID', 20, finalY + 17)

  doc.setFontSize(9)
  doc.setTextColor(107, 114, 128)
  doc.text('Thank you for your business with PrintX!', 105, 275, { align: 'center' })
  doc.text('For support: admin@printx.in | support.printx.in', 105, 280, { align: 'center' })
  doc.text('This is a computer-generated invoice.', 105, 285, { align: 'center' })
  // Expose base64 PDF for automated tests and then trigger save as normal.
  try {
    // datauristring is like 'data:application/pdf;base64,JVBERi0x...'
    // Save base64 portion to window for test harness to pick up.
    // eslint-disable-next-line no-undef
    if (typeof window !== 'undefined') {
      // eslint-disable-next-line no-undef
      window.__LAST_PDF_B64 = doc.output('datauristring').split(',')[1]
    }
  } catch (err) {
    // ignore test hook failures
  }

  doc.save(`Invoice-${order.id}.pdf`)
}
