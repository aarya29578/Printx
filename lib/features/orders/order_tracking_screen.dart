import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/order_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  final Order order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    print(
        'ORDER TRACKING SCREEN order.id=${order.id} order.orderNumber=${order.orderNumber} items=${order.items.length}');
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
        title: Text('Order #${order.id.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(order.status),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                      if (order.estimatedDelivery != null)
                        Text(
                          'Est. delivery: ${_formatDate(order.estimatedDelivery!)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('Tracking Timeline',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),

          ...order.trackingSteps.asMap().entries.map((e) {
            final step = e.value;
            final isLast = e.key == order.trackingSteps.length - 1;
            return TimelineTile(
              alignment: TimelineAlign.manual,
              lineXY: 0.1,
              isFirst: e.key == 0,
              isLast: isLast,
              indicatorStyle: IndicatorStyle(
                width: 24,
                height: 24,
                color: step.isCompleted
                    ? AppColors.primary
                    : AppColors.textMuted.withOpacity(0.3),
                iconStyle: step.isCompleted
                    ? IconStyle(
                        iconData: Icons.check_rounded,
                        color: Colors.white,
                        fontSize: 14,
                      )
                    : null,
              ),
              beforeLineStyle: LineStyle(
                color: step.isCompleted
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.textMuted.withOpacity(0.2),
                thickness: 2,
              ),
              endChild: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: step.isCompleted ? null : AppColors.textMuted,
                      ),
                    ),
                    if (step.description != null)
                      Text(step.description!,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    if (step.timestamp != null)
                      Text(_formatDate(step.timestamp!),
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _statusLabel(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => 'Order Pending',
      OrderStatus.confirmed => 'Order Confirmed',
      OrderStatus.designApproved => 'Design Approved',
      OrderStatus.printing => 'Being Printed',
      OrderStatus.qualityCheck => 'Quality Check',
      OrderStatus.dispatched => 'Dispatched',
      OrderStatus.outForDelivery => 'Out for Delivery',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
