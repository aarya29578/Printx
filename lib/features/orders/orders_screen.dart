import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/extensions.dart';
import '../../core/widgets/app_button.dart';
import '../../data/models/order_model.dart';
import '../../features/orders/orders_cubit.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<OrdersCubit>().load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: const Text('My Orders',
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
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OrdersLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _OrderList(orders: state.active),
                _OrderList(orders: state.completed),
                _OrderList(orders: state.cancelled),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text('No orders here',
                style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: index * 80),
          child: _OrderCard(order: orders[index]),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  Color _statusColor() {
    return switch (order.status) {
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled => AppColors.error,
      OrderStatus.outForDelivery => AppColors.info,
      _ => AppColors.warning,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${order.id.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    order.status.name
                        .replaceAllMapped(RegExp(r'[A-Z]'),
                            (m) => ' ${m.group(0)}')
                        .trim()
                        .capitalize,
                    style: TextStyle(
                        color: _statusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${order.items.length} item${order.items.length > 1 ? 's' : ''} · ${CurrencyFormatter.format(order.total)}',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            Text(
              order.createdAt.formatted,
              style:
                  TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const Divider(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.items.first.productName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                TextButton(
                  onPressed: () =>
                      context.push('/order/${order.id}/track'),
                  child: const Text('Track'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
