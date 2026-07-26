import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../data/models/order_model.dart';
import '../../features/auth/auth_cubit.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final riderId = authState.userId;
    final riderName = authState.name;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: StreamBuilder<List<Order>>(
        stream: FirestoreService.watchRiderOrders(riderId: riderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return _DashboardShimmer();
          }
          final orders = snap.data ?? [];
          final stats = FirestoreService.computeDailyStats(orders);
          final recent = orders.take(5).toList();

          return CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientDelivery,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delivery_dining_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${riderName.split(' ').first}!',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const Text('Ready to deliver?',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Date banner ──────────────────────────────────────
                      FadeInDown(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientDelivery,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Today's Summary",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    ),
                                    Text(
                                      DateFormat('EEEE, d MMM y')
                                          .format(DateTime.now()),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Total Deliveries',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                  Text(
                                    '${stats['total'] ?? 0}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Stat cards ───────────────────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: _StatsGrid(stats: stats),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Earnings placeholder ─────────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: _EarningsCard(),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // ── Recent deliveries ─────────────────────────────────
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent Deliveries',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            TextButton(
                              onPressed: () => context.go('/deliveries'),
                              child: const Text('View all'),
                            ),
                          ],
                        ),
                      ),

                      if (recent.isEmpty)
                        _EmptyDashboard()
                      else
                        ...recent.asMap().entries.map((e) => FadeInUp(
                              delay: Duration(
                                  milliseconds: 350 + e.key * 80),
                              child: _RecentOrderCard(order: e.value),
                            )),

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.1,
      children: [
        _StatCard('Assigned', stats['assigned'] ?? 0, AppColors.warning,
            Icons.assignment_rounded),
        _StatCard('Picked Up', stats['pickedUp'] ?? 0, AppColors.info,
            Icons.inventory_2_rounded),
        _StatCard('En Route', stats['outForDelivery'] ?? 0, AppColors.primary,
            Icons.local_shipping_rounded),
        _StatCard('Delivered', stats['delivered'] ?? 0, AppColors.success,
            Icons.check_circle_rounded),
        _StatCard('Cancelled', stats['cancelled'] ?? 0, AppColors.error,
            Icons.cancel_rounded),
        _StatCard('Total Today', stats['total'] ?? 0, const Color(0xFF8B5CF6),
            Icons.bar_chart_rounded),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatCard(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppSpacing.cardShadow,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 20, color: color),
          ),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Earnings Card (future-ready) ─────────────────────────────────────────────

class _EarningsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_rupee_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Today's Earnings",
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Coming Soon',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
                Text('Earnings tracking will be enabled soon',
                    style:
                        TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white54, size: 16),
        ],
      ),
    );
  }
}

// ─── Recent Order Card ────────────────────────────────────────────────────────

class _RecentOrderCard extends StatelessWidget {
  final Order order;
  const _RecentOrderCard({required this.order});

  Color get _statusColor => switch (order.status) {
        OrderStatus.delivered => AppColors.success,
        OrderStatus.cancelled => AppColors.error,
        OrderStatus.outForDelivery => AppColors.primary,
        OrderStatus.pickedUp => AppColors.info,
        _ => AppColors.warning,
      };

  String get _statusLabel => switch (order.status) {
        OrderStatus.assigned => 'Assigned',
        OrderStatus.pickedUp => 'Picked Up',
        OrderStatus.outForDelivery => 'En Route',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
        _ => 'Pending',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push('/delivery/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_shipping_rounded,
                    color: _statusColor, size: 22),
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
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.delivery_dining_rounded,
              size: 72,
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No deliveries assigned yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Admin will assign orders to you. Check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _DashboardShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xxl),
          ShimmerLoader(width: double.infinity, height: 90,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.1,
            children: List.generate(6, (_) => ShimmerLoader(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            )),
          ),
          const SizedBox(height: AppSpacing.md),
          ShimmerList(count: 3, itemHeight: 70),
        ],
      ),
    );
  }
}
