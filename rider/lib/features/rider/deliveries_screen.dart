import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../data/models/order_model.dart';
import '../../features/auth/auth_cubit.dart';
import '../../services/firestore_service.dart';

class DeliveriesScreen extends StatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  State<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }
    final riderId = authState.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: const Text('My Deliveries',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Assigned'),
            Tab(text: 'Picked Up'),
            Tab(text: 'En Route'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: StreamBuilder<List<Order>>(
        stream: FirestoreService.watchRiderOrders(riderId: riderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ShimmerList(count: 5, itemHeight: 130),
            );
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final all = snap.data ?? [];

          final assigned = all
              .where((o) =>
                  o.status == OrderStatus.assigned ||
                  o.status == OrderStatus.dispatched ||
                  o.status == OrderStatus.pending)
              .toList();
          final pickedUp =
              all.where((o) => o.status == OrderStatus.pickedUp).toList();
          final enRoute = all
              .where((o) => o.status == OrderStatus.outForDelivery)
              .toList();
          final delivered =
              all.where((o) => o.status == OrderStatus.delivered).toList();
          final cancelled =
              all.where((o) => o.status == OrderStatus.cancelled).toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _OrderList(orders: assigned, emptyMsg: 'No assigned deliveries'),
              _OrderList(orders: pickedUp, emptyMsg: 'No picked up orders'),
              _OrderList(orders: enRoute, emptyMsg: 'No orders en route'),
              _OrderList(orders: delivered, emptyMsg: 'No delivered orders yet'),
              _OrderList(orders: cancelled, emptyMsg: 'No cancelled orders'),
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
  final String emptyMsg;
  const _OrderList({required this.orders, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: AppSpacing.md),
            Text(emptyMsg,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (context, i) => _DeliveryCard(order: orders[i]),
    );
  }
}

// ─── Delivery Card ────────────────────────────────────────────────────────────

class _DeliveryCard extends StatelessWidget {
  final Order order;
  const _DeliveryCard({required this.order});

  Color get _statusColor => switch (order.status) {
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.error,
        OrderStatus.outForDelivery => AppColors.primary,
        OrderStatus.pickedUp => AppColors.info,
        OrderStatus.assigned => AppColors.warning,
        _ => AppColors.textMuted,
      };

  String get _statusLabel => switch (order.status) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push('/delivery/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        Text(
                          order.createdAt.formatted,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Customer info
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.userName.isNotEmpty ? order.userName : 'Customer',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (order.deliveryAddress.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.deliveryAddress,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 16),

              // Products strip
              if (order.items.isNotEmpty) ...[
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      ...order.items.take(3).map((item) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item.productImage,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  width: 44,
                                  height: 44,
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  child: const Icon(Icons.image,
                                      size: 18,
                                      color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          )),
                      if (order.items.length > 3)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '+${order.items.length - 3}',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    CurrencyFormatter.format(order.total),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => context.push('/delivery/${order.id}'),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            foregroundColor: AppColors.primary),
                        child: const Text('Details'),
                      ),
                      if (order.status == OrderStatus.assigned ||
                          order.status == OrderStatus.dispatched)
                        _QuickActionButton(
                          label: 'Mark Picked Up',
                          color: AppColors.info,
                          onTap: () => _markPickedUp(context, order),
                        ),
                      if (order.status == OrderStatus.pickedUp)
                        _QuickActionButton(
                          label: 'Out for Delivery',
                          color: AppColors.primary,
                          onTap: () => _markOutForDelivery(context, order),
                        ),
                      if (order.status == OrderStatus.outForDelivery)
                        _QuickActionButton(
                          label: 'Mark Delivered',
                          color: AppColors.success,
                          onTap: () => _markDelivered(context, order),
                        ),
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

  Future<void> _markPickedUp(BuildContext context, Order order) async {
    try {
      await FirestoreService.markPickedUp(orderId: order.id);
      if (!context.mounted) return;
      AppToast.show(context, 'Marked as Picked Up!', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }

  Future<void> _markOutForDelivery(BuildContext context, Order order) async {
    try {
      await FirestoreService.markOutForDelivery(orderId: order.id);
      if (!context.mounted) return;
      AppToast.show(context, 'Out for Delivery!', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }

  Future<void> _markDelivered(BuildContext context, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Delivery',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure the order has been delivered to the customer?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await FirestoreService.markDelivered(orderId: order.id);
      if (!context.mounted) return;
      AppToast.show(context, 'Delivered successfully! 🎉',
          type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
        ),
      ),
    );
  }
}
