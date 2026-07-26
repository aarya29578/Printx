import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/order_model.dart';
import '../../services/firestore_service.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final Order initialOrder;
  const DeliveryDetailScreen({super.key, required this.initialOrder});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  String? _customerPhone;

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  Future<void> _loadPhone() async {
    if (widget.initialOrder.customerPhone.isNotEmpty) {
      setState(() => _customerPhone = widget.initialOrder.customerPhone);
      return;
    }
    if (widget.initialOrder.userId.isEmpty) return;
    try {
      final data = await FirestoreService.fetchUser(
          userId: widget.initialOrder.userId);
      if (!mounted) return;
      setState(() {
        _customerPhone = (data?['phoneNumber'] as String?) ??
            (data?['phone'] as String?);
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Order>(
      stream: FirestoreService.watchOrderById(
          orderId: widget.initialOrder.id),
      initialData: widget.initialOrder,
      builder: (context, snap) {
        final order = snap.data ?? widget.initialOrder;
        final isFinal = order.status == OrderStatus.delivered ||
            order.status == OrderStatus.cancelled;

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppColors.bgDark : AppColors.bgLight,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(
              '#${order.id.length > 10 ? order.id.substring(0, 10).toUpperCase() : order.id.toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (!isFinal)
                TextButton.icon(
                  onPressed: () => _showStatusPicker(context, order),
                  icon: const Icon(Icons.update_rounded, size: 16),
                  label: const Text('Update'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // ── Status card ──────────────────────────────────────────
              _StatusCard(order: order),
              const SizedBox(height: AppSpacing.sm),

              // ── Status Timeline ──────────────────────────────────────
              _StatusTimeline(order: order),
              const SizedBox(height: AppSpacing.sm),

              // ── Customer ─────────────────────────────────────────────
              _SectionCard(
                title: 'Customer',
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Name',
                        value: order.userName.isNotEmpty
                            ? order.userName
                            : 'N/A'),
                    _InfoRow(
                        label: 'Email',
                        value: order.userEmail.isNotEmpty
                            ? order.userEmail
                            : 'N/A'),
                    if (_customerPhone != null &&
                        _customerPhone!.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: _InfoRow(
                                label: 'Phone',
                                value: _customerPhone!),
                          ),
                          Row(
                            children: [
                              _CallButton(phone: _customerPhone!),
                              const SizedBox(width: 8),
                              _NavigateButton(
                                  address: order.deliveryAddress),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Delivery Address ──────────────────────────────────────
              _SectionCard(
                title: 'Delivery Address',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.deliveryAddress.isNotEmpty
                            ? order.deliveryAddress
                            : 'No address provided',
                        style: const TextStyle(
                            color: AppColors.textMuted, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Order Items ───────────────────────────────────────────
              _SectionCard(
                title: 'Items (${order.items.length})',
                child: Column(
                  children: order.items
                      .map((item) => _OrderItemRow(item: item))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── Vendor ────────────────────────────────────────────────
              if (order.vendorName != null && order.vendorName!.isNotEmpty)
                _SectionCard(
                  title: 'Vendor',
                  child: Column(
                    children: [
                      _InfoRow(label: 'Name', value: order.vendorName!),
                      if (order.vendorAddress != null &&
                          order.vendorAddress!.isNotEmpty)
                        _InfoRow(
                            label: 'Pickup Address',
                            value: order.vendorAddress!),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.sm),

              // ── Payment Summary ───────────────────────────────────────
              _SectionCard(
                title: 'Payment',
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Order Total',
                        value: CurrencyFormatter.format(order.total),
                        highlight: true),
                    _InfoRow(
                        label: 'Payment',
                        value: 'COD / Online',
                        highlight: false),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Action buttons ────────────────────────────────────────
              if (!isFinal) _ActionButtons(order: order),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStatusPicker(BuildContext context, Order order) async {
    final statuses = _validNextStatuses(order.status);
    if (statuses.isEmpty) return;

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
            const Text('Update Status',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            ...statuses.map((s) => ListTile(
                  title: Text(s.$2),
                  leading: Icon(s.$3, color: AppColors.primary, size: 20),
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
          orderId: order.id, status: picked);
      if (!context.mounted) return;
      AppToast.show(context, 'Status updated!', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }

  List<(String, String, IconData)> _validNextStatuses(OrderStatus current) {
    return switch (current) {
      OrderStatus.assigned || OrderStatus.dispatched => [
          ('picked_up', 'Mark Picked Up', Icons.inventory_2_rounded),
        ],
      OrderStatus.pickedUp => [
          ('out_for_delivery', 'Out for Delivery', Icons.local_shipping_rounded),
        ],
      OrderStatus.outForDelivery => [
          ('delivered', 'Mark Delivered', Icons.check_circle_rounded),
        ],
      _ => [],
    };
  }
}

// ─── Status Card ──────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final Order order;
  const _StatusCard({required this.order});

  Color get _color => switch (order.status) {
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.error,
        OrderStatus.outForDelivery => AppColors.primary,
        OrderStatus.pickedUp => AppColors.info,
        OrderStatus.assigned => AppColors.warning,
        _ => AppColors.textMuted,
      };

  String get _label => switch (order.status) {
        OrderStatus.assigned => 'Assigned',
        OrderStatus.dispatched => 'Ready for Pickup',
        OrderStatus.pickedUp => 'Picked Up',
        OrderStatus.outForDelivery => 'Out for Delivery',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        _ => 'Pending',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping_rounded, color: _color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Status',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                Text(
                  _label,
                  style: TextStyle(
                      color: _color,
                      fontWeight: FontWeight.w700,
                      fontSize: 18),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(_label,
                style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── Status Timeline ──────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final Order order;
  const _StatusTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = [
      (
        OrderStatus.assigned,
        'Assigned',
        'Order assigned to you',
        Icons.assignment_rounded
      ),
      (
        OrderStatus.pickedUp,
        'Picked Up',
        'Picked up from vendor',
        Icons.inventory_2_rounded
      ),
      (
        OrderStatus.outForDelivery,
        'Out for Delivery',
        'On the way to customer',
        Icons.local_shipping_rounded
      ),
      (
        OrderStatus.delivered,
        'Delivered',
        'Successfully delivered',
        Icons.check_circle_rounded
      ),
    ];

    final currentIndex = _statusIndex(order.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Progress',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: AppSpacing.md),
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final step = e.value;
            final isDone = i <= currentIndex;
            final isCurrent = i == currentIndex;
            final isLast = i == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success
                            : AppColors.textMuted.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Icon(
                        step.$4,
                        size: 16,
                        color:
                            isDone ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 36,
                        color: isDone && i < currentIndex
                            ? AppColors.success
                            : AppColors.textMuted.withValues(alpha: 0.2),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: isLast ? 0 : AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          step.$2,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 13,
                            color: isDone
                                ? null
                                : AppColors.textMuted,
                          ),
                        ),
                        Text(
                          step.$3,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  int _statusIndex(OrderStatus status) {
    return switch (status) {
      OrderStatus.assigned || OrderStatus.dispatched => 0,
      OrderStatus.pickedUp => 1,
      OrderStatus.outForDelivery => 2,
      OrderStatus.delivered => 3,
      _ => -1,
    };
  }
}

// ─── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final Order order;
  const _ActionButtons({required this.order});

  @override
  Widget build(BuildContext context) {
    return switch (order.status) {
      OrderStatus.assigned || OrderStatus.dispatched => _ActionBtn(
          label: 'Mark as Picked Up',
          icon: Icons.inventory_2_rounded,
          color: AppColors.info,
          onTap: () => _doAction(context, 'picked_up'),
        ),
      OrderStatus.pickedUp => _ActionBtn(
          label: 'Out for Delivery',
          icon: Icons.local_shipping_rounded,
          color: AppColors.primary,
          onTap: () => _doAction(context, 'out_for_delivery'),
        ),
      OrderStatus.outForDelivery => _ActionBtn(
          label: 'Mark as Delivered',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          onTap: () => _confirmDelivered(context),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<void> _doAction(BuildContext context, String status) async {
    try {
      await FirestoreService.updateOrderStatus(
          orderId: order.id, status: status);
      if (!context.mounted) return;
      AppToast.show(context, 'Status updated!', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }

  Future<void> _confirmDelivered(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delivery',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('Confirm that this order has been delivered?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delivered'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _doAction(context, 'delivered');
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ─── Order Item Row ───────────────────────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.productImage,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.image,
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
                Text('Qty: ${item.quantity}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(item.totalPrice),
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Call & Navigate Buttons ──────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  final String phone;
  const _CallButton({required this.phone});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('tel:$phone')),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.call_rounded,
            color: AppColors.success, size: 18),
      ),
    );
  }
}

class _NavigateButton extends StatelessWidget {
  final String address;
  const _NavigateButton({required this.address});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Maps integration placeholder — launch maps with address
        final encoded = Uri.encodeComponent(address);
        launchUrl(Uri.parse('https://maps.google.com/?q=$encoded'));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.navigation_rounded, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text('Navigate',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _InfoRow(
      {required this.label,
      required this.value,
      this.highlight = false});

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
            child: Text(
              value,
              style: TextStyle(
                fontWeight:
                    highlight ? FontWeight.w700 : FontWeight.w600,
                fontSize: highlight ? 15 : 13,
                color: highlight ? AppColors.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
