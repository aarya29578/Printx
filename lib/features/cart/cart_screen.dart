import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../features/cart/cart_cubit.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _couponCtrl = TextEditingController();

  @override
  void dispose() {
    _couponCtrl.dispose();
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
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('My Cart',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.items.isNotEmpty) {
                return TextButton(
                  onPressed: () => context.read<CartCubit>().clearCart(),
                  child: const Text('Clear',
                      style: TextStyle(color: AppColors.error)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state is! CartLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 80, color: AppColors.textMuted),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Your cart is empty',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Add items to get started',
                      style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Browse Products',
                    onPressed: () => context.go('/home'),
                    variant: AppButtonVariant.primary,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return FadeInLeft(
                      delay: Duration(milliseconds: index * 80),
                      child: Slidable(
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) =>
                                  context.read<CartCubit>().removeItem(item.id),
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_outline_rounded,
                              label: 'Remove',
                            ),
                          ],
                        ),
                        child: _CartItemTile(item: item),
                      ),
                    );
                  },
                ),
              ),

              // Coupon input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          prefixIcon: const Icon(Icons.local_offer_outlined),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      label:
                          state.appliedCouponCode != null ? 'Remove' : 'Apply',
                      onPressed: () {
                        if (state.appliedCouponCode != null) {
                          context.read<CartCubit>().removeCoupon();
                          _couponCtrl.clear();
                        } else {
                          context
                              .read<CartCubit>()
                              .applyCoupon(_couponCtrl.text.trim());
                        }
                      },
                      variant: AppButtonVariant.outline,
                    ),
                  ],
                ),
              ),

              if (state.appliedCouponCode != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${state.appliedCouponCode!} applied! You save ${CurrencyFormatter.format(state.discount)}',
                          style:
                              TextStyle(color: AppColors.success, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

              // Order summary
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                        'Subtotal', CurrencyFormatter.format(state.subtotal)),
                    if (state.discount > 0)
                      _SummaryRow('Discount',
                          '-${CurrencyFormatter.format(state.discount)}',
                          color: AppColors.success),
                    _SummaryRow(
                        'GST (18%)', CurrencyFormatter.format(state.gst)),
                    const Divider(),
                    _SummaryRow('Total', CurrencyFormatter.format(state.total),
                        isBold: true),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label:
                          'Proceed to Checkout · ${CurrencyFormatter.format(state.total)}',
                      onPressed: () => context.push('/checkout'),
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.fullWidth,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.productImage,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (item.size != null)
                    Text('Size: ${item.size}',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  if (item.finish != null)
                    Text('Finish: ${item.finish}',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  Text(CurrencyFormatter.format(item.totalPrice),
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (item.quantity > 1) {
                          context
                              .read<CartCubit>()
                              .updateQty(item.id, item.quantity - 1);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      iconSize: 20,
                    ),
                    Text('${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      onPressed: () => context
                          .read<CartCubit>()
                          .updateQty(item.id, item.quantity + 1),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _SummaryRow(this.label, this.value, {this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                  color: color,
                  fontSize: isBold ? 16 : 14)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? (isBold ? AppColors.primary : null),
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
