import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Order Details',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _OrderSummaryHeader(order: order),
          const SizedBox(height: AppSpacing.md),
          ...order.items.asMap().entries.map((e) {
            return _OrderItemCard(
              index: e.key + 1,
              item: e.value,
            );
          }),
          const SizedBox(height: AppSpacing.md),
          _MetaSection(order: order),
        ],
      ),
    );
  }
}

class _OrderSummaryHeader extends StatelessWidget {
  final Order order;
  const _OrderSummaryHeader({required this.order});

  Color _statusColor(BuildContext context) {
    return switch (order.status) {
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled => AppColors.error,
      OrderStatus.outForDelivery => AppColors.info,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    order.status.name
                        .replaceAllMapped(
                            RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}')
                        .trim()
                        .toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Total Amount: ${CurrencyFormatter.format(order.total)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  // specs is expected to be like: "Matte · 100 cards · Double-sided" or
  // "Mat · Size · Finish" depending on how it was stored.
  // Firestore parsing creates: "size · finish" from map['size'] and map['finish'].
  // That yields: "<size> · <finish>".

  final int index;
  final OrderItem item;
  const _OrderItemCard({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item $index',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted.withOpacity(0.9))),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.productImage,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (c, _, __) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.surface,
                      child: const Icon(Icons.image_not_supported_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 8),
                      _SpecRow(
                          label: 'Finish', value: _getSpecPart(item.specs, 1)),
                      _SpecRow(
                          label: 'Size', value: _getSpecPart(item.specs, 0)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _FieldRow(label: 'Quantity', value: '${item.quantity}'),
            _FieldRow(
                label: 'Price',
                value: CurrencyFormatter.format(item.unitPrice)),
            _FieldRow(
                label: 'Subtotal',
                value: CurrencyFormatter.format(item.totalPrice)),
          ],
        ),
      ),
    );
  }

  // specs is expected to be like: "Matte · 100 cards · Double-sided" or
  // "Mat · Size · Finish" depending on how it was stored.
  // Firestore parsing creates: "size · finish" from map['size'] and map['finish'].
  // That yields: "<size> · <finish>".
  String? _getSpecPart(String? specs, int partIndex) {
    if (specs == null) return null;
    final parts = specs
        .split('·')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    if (partIndex < 0 || partIndex >= parts.length) return parts.first;
    return parts[partIndex];
  }
}

class _MetaSection extends StatelessWidget {
  final Order order;
  const _MetaSection({required this.order});

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Information',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted.withOpacity(0.9))),
            const SizedBox(height: AppSpacing.md),
            _FieldRow(label: 'Status', value: order.status.name.toUpperCase()),
            _FieldRow(label: 'Order Date', value: _formatDate(order.createdAt)),
            _FieldRow(
                label: 'Total Amount',
                value: CurrencyFormatter.format(order.total)),
            const SizedBox(height: AppSpacing.sm),
            Text('Delivery Address',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted.withOpacity(0.9))),
            const SizedBox(height: AppSpacing.sm),
            Text(order.deliveryAddress.isEmpty ? '—' : order.deliveryAddress),
          ],
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  const _FieldRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String? value;
  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label:',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value == null || value!.isEmpty ? '—' : value!,
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
