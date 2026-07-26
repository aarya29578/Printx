import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../data/models/order_model.dart';
import '../../features/auth/auth_cubit.dart';
import '../../services/firestore_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final riderId = authState.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: const Text('Delivery History',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Order>>(
        stream: FirestoreService.watchRiderOrders(riderId: riderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ShimmerList(count: 6, itemHeight: 90),
            );
          }

          final all = snap.data ?? [];
          final history = all
              .where((o) =>
                  o.status == OrderStatus.delivered ||
                  o.status == OrderStatus.cancelled)
              .toList();

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 80,
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No history yet',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Your completed and cancelled deliveries will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final grouped = _groupByDate(history);

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final entry = grouped[i];
              if (entry is String) {
                // Date header
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm),
                  child: Text(
                    entry,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textMuted),
                  ),
                );
              }
              final order = entry as Order;
              return _HistoryCard(order: order);
            },
          );
        },
      ),
    );
  }

  List<dynamic> _groupByDate(List<Order> orders) {
    final result = <dynamic>[];
    String? lastLabel;

    for (final order in orders) {
      final label = order.createdAt.isToday
          ? 'Today'
          : order.createdAt.isYesterday
              ? 'Yesterday'
              : order.createdAt.formatted;

      if (label != lastLabel) {
        result.add(label);
        lastLabel = label;
      }
      result.add(order);
    }
    return result;
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final Order order;
  const _HistoryCard({required this.order});

  bool get _isDelivered => order.status == OrderStatus.delivered;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _isDelivered ? AppColors.success : AppColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push('/delivery/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isDelivered
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.userName.isNotEmpty
                          ? order.userName
                          : 'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      order.createdAt.formatted,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                    Text(
                      '${order.items.length} item(s)',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _isDelivered ? 'Delivered' : 'Cancelled',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(order.total),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
