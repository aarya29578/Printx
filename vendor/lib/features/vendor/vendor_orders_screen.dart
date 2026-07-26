import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/order_model.dart';
import '../../features/auth/auth_cubit.dart';
import '../../services/firestore_service.dart';

class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view orders.')),
      );
    }
    final vendorId = authState.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: const Text('Orders',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      // Server-side query — only orders containing this vendor's products
      body: StreamBuilder<List<Order>>(
        stream: FirestoreService.watchVendorOrders(vendorId: vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allOrders = snapshot.data ?? [];

          final active = allOrders
              .where((o) =>
                  o.status != OrderStatus.delivered &&
                  o.status != OrderStatus.cancelled)
              .toList();
          final completed = allOrders
              .where((o) => o.status == OrderStatus.delivered)
              .toList();
          final cancelled = allOrders
              .where((o) => o.status == OrderStatus.cancelled)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _OrderList(orders: active),
              _OrderList(orders: completed),
              _OrderList(orders: cancelled),
            ],
          );
        },
      ),
    );
  }
}

// ─── Order list ───────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text('No orders here',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  Color _statusColor() {
    return switch (order.status) {
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled || OrderStatus.rejected => AppColors.error,
      OrderStatus.outForDelivery => AppColors.info,
      OrderStatus.assigned || OrderStatus.pickedUp => AppColors.primary,
      OrderStatus.accepted => AppColors.success,
      _ => AppColors.warning,
    };
  }

  String _statusLabel() {
    return switch (order.status) {
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
  }

  @override
  Widget build(BuildContext context) {
    final customerName =
        order.userName.isNotEmpty ? order.userName : 'Customer';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/vendor/order/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          customerName,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(
                      label: _statusLabel(), color: _statusColor()),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.createdAt.formatted,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
              ),
              const Divider(height: 16),

              // Items summary
              ...order.items.take(2).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            CurrencyFormatter.format(item.totalPrice),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (order.items.length > 2)
                Text(
                  '+${order.items.length - 2} more item(s)',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),

              const Divider(height: 16),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${CurrencyFormatter.format(order.total)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () =>
                            context.push('/vendor/order/${order.id}'),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.primary),
                        child: const Text('View Details'),
                      ),
                      if (order.status == OrderStatus.pending) ...[
                        _QuickButton(
                          label: 'Accept',
                          color: AppColors.success,
                          onTap: () => _acceptOrder(context),
                        ),
                        const SizedBox(width: 4),
                        _QuickButton(
                          label: 'Reject',
                          color: AppColors.error,
                          onTap: () => _rejectOrder(context),
                        ),
                      ] else if (order.status != OrderStatus.delivered &&
                          order.status != OrderStatus.cancelled &&
                          order.status != OrderStatus.rejected &&
                          order.status != OrderStatus.assigned &&
                          order.status != OrderStatus.pickedUp &&
                          order.status != OrderStatus.outForDelivery)
                        _UpdateStatusButton(order: order),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptOrder(BuildContext context) async {
    try {
      await FirestoreService.acceptOrder(orderId: order.id);
      if (!context.mounted) return;
      AppToast.show(context, 'Order accepted', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }

  Future<void> _rejectOrder(BuildContext context) async {
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
      await FirestoreService.rejectOrder(orderId: order.id);
      if (!context.mounted) return;
      AppToast.show(context, 'Order rejected', type: ToastType.error);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }
}

// ─── Quick action button ──────────────────────────────────────────────────────

class _QuickButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11)),
    );
  }
}

// ─── Update status button ─────────────────────────────────────────────────────

class _UpdateStatusButton extends StatelessWidget {
  final Order order;
  const _UpdateStatusButton({required this.order});

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

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showStatusPicker(context),
      icon: const Icon(Icons.update_rounded, size: 16),
      label: const Text('Update'),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Future<void> _showStatusPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
          orderId: order.id, status: picked);
      if (!context.mounted) return;
      AppToast.show(context, 'Status updated', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }
}
