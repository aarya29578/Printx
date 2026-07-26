import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/order_model.dart';
import '../../services/firestore_service.dart';

class VendorOrderDetailScreen extends StatefulWidget {
  final Order order;
  const VendorOrderDetailScreen({super.key, required this.order});

  @override
  State<VendorOrderDetailScreen> createState() =>
      _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState extends State<VendorOrderDetailScreen> {
  String? _customerPhone;

  @override
  void initState() {
    super.initState();
    _loadCustomerPhone();
  }

  Future<void> _loadCustomerPhone() async {
    if (widget.order.userId.isEmpty) return;
    try {
      final userData =
          await FirestoreService.fetchUser(userId: widget.order.userId);
      if (!mounted) return;
      setState(() {
        _customerPhone = (userData?['phoneNumber'] as String?) ??
            (userData?['phone'] as String?);
      });
    } catch (_) {}
  }

  // Statuses the vendor can set
  static const _statuses = [
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('design_review', 'Design Review'),
    ('printing', 'Printing'),
    ('quality_check', 'Quality Check'),
    ('shipped', 'Shipped'),
    ('out_for_delivery', 'Out for Delivery'),
    ('delivered', 'Delivered'),
    ('cancelled', 'Cancelled'),
  ];

  String _statusLabel(OrderStatus s) => switch (s) {
        OrderStatus.pending => 'Pending',
        OrderStatus.accepted => 'Accepted',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.designApproved => 'Design Review',
        OrderStatus.printing => 'Printing',
        OrderStatus.qualityCheck => 'Quality Check',
        OrderStatus.dispatched => 'Shipped',
        OrderStatus.assigned => 'Rider Assigned',
        OrderStatus.pickedUp => 'Picked Up',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        OrderStatus.rejected => 'Rejected',
      };

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled || OrderStatus.rejected => AppColors.error,
        OrderStatus.outForDelivery => AppColors.info,
        OrderStatus.assigned || OrderStatus.pickedUp => AppColors.primary,
        OrderStatus.accepted => AppColors.success,
        _ => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFinal = order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.rejected;

    return StreamBuilder<Order>(
      // Keep screen in sync with live Firestore updates
      stream: FirestoreService.watchOrderById(orderId: order.id),
      initialData: order,
      builder: (context, snap) {
        final live = snap.data ?? order;
        return Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              '#${live.id.length > 10 ? live.id.substring(0, 10).toUpperCase() : live.id.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (!isFinal)
                TextButton.icon(
                  onPressed: () => _showStatusPicker(context, live),
                  icon: const Icon(Icons.update_rounded, size: 16),
                  label: const Text('Update Status'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ── Status card
              _SectionCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order Status',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            _statusLabel(live.status),
                            style: TextStyle(
                                color: _statusColor(live.status),
                                fontWeight: FontWeight.w700,
                                fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(live.status)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _statusLabel(live.status),
                        style: TextStyle(
                            color: _statusColor(live.status),
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Accept / Reject (only for pending orders)
              if (live.status == OrderStatus.pending) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text('Accept Order', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () => _acceptOrder(context, live),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () => _rejectOrder(context, live),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Assigned rider info
              if (live.assignedRiderId != null && live.assignedRiderId!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _SectionCard(
                  title: 'Assigned Rider',
                  child: _InfoRow(
                    label: 'Rider',
                    value: live.assignedRiderName ?? live.assignedRiderId!,
                  ),
                ),
              ],

              // ── Order info
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Order Date',
                      value: DateFormat('dd MMM yyyy, hh:mm a')
                          .format(live.createdAt),
                    ),
                    _InfoRow(
                      label: 'Order Total',
                      value: CurrencyFormatter.format(live.total),
                      valueStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    _InfoRow(
                        label: 'Items',
                        value: '${live.items.length} item(s)'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Customer info
              _SectionCard(
                title: 'Customer',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Name',
                      value: live.userName.isNotEmpty
                          ? live.userName
                          : 'N/A',
                    ),
                    _InfoRow(
                      label: 'Email',
                      value: live.userEmail.isNotEmpty
                          ? live.userEmail
                          : 'N/A',
                    ),
                    if (_customerPhone != null && _customerPhone!.isNotEmpty)
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          _InfoRow(
                              label: 'Phone', value: _customerPhone!),
                          IconButton(
                            icon: const Icon(Icons.call_rounded,
                                color: AppColors.success, size: 20),
                            onPressed: () => launchUrl(
                              Uri.parse('tel:$_customerPhone'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Delivery address
              _SectionCard(
                title: 'Delivery Address',
                child: Text(
                  live.deliveryAddress.isNotEmpty
                      ? live.deliveryAddress
                      : 'No address provided',
                  style: const TextStyle(
                      color: AppColors.textMuted, height: 1.5),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Ordered items
              _SectionCard(
                title: 'Ordered Items (${live.items.length})',
                child: Column(
                  children: live.items
                      .map((item) => _OrderItemTile(item: item))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Payment summary
              _SectionCard(
                title: 'Payment Summary',
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Subtotal',
                        value: CurrencyFormatter.format(live.subtotal)),
                    if (live.discount > 0)
                      _InfoRow(
                          label: 'Discount',
                          value:
                              '- ${CurrencyFormatter.format(live.discount)}'),
                    _InfoRow(
                        label: 'Total',
                        value: CurrencyFormatter.format(live.total),
                        valueStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }

  Future<void> _acceptOrder(BuildContext context, Order live) async {
    try {
      await FirestoreService.acceptOrder(orderId: live.id);
      if (!context.mounted) return;
      AppToast.show(context, 'Order accepted', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }

  Future<void> _rejectOrder(BuildContext context, Order live) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Order', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to reject this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await FirestoreService.rejectOrder(orderId: live.id);
      if (!context.mounted) return;
      AppToast.show(context, 'Order rejected', type: ToastType.error);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }

  Future<void> _showStatusPicker(BuildContext context, Order live) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('Update Order Status',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            ..._statuses.map((s) => ListTile(
                  title: Text(s.$2),
                  leading: const Icon(Icons.circle,
                      size: 10, color: AppColors.primary),
                  onTap: () => Navigator.pop(ctx, s.$1),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;

    try {
      await FirestoreService.updateOrderStatus(
          orderId: live.id, status: picked);
      if (!context.mounted) return;
      AppToast.show(context, 'Status updated to $picked',
          type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }
}

// ─── Order item tile ──────────────────────────────────────────────────────────

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;
  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.productImage,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.image_not_supported,
                    color: AppColors.textMuted, size: 20),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (item.specs != null && item.specs!.isNotEmpty)
                  Text(item.specs!,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Qty: ${item.quantity}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text(
                      '× ${CurrencyFormatter.format(item.unitPrice)}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(item.totalPrice),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ],
                ),
                // Custom design
                if (item.customDesignUrl != null &&
                    item.customDesignUrl!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => launchUrl(
                        Uri.parse(item.customDesignUrl!),
                        mode: LaunchMode.externalApplication),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.design_services_outlined,
                              size: 12, color: AppColors.info),
                          SizedBox(width: 4),
                          Text('View Custom Design',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
                // Customer instructions
                if (item.customerInstructions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Note: ${item.customerInstructions}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
          ],
          child,
        ],
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: valueStyle ??
                    const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
