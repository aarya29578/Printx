import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../features/cart/cart_cubit.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state is CheckoutSuccess) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _OrderSuccessDialog(
              orderNumber: state.orderNumber,
              onGoToOrders: () {
                Navigator.of(context).pop();
                context.go('/orders');
              },
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const Text('Checkout',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, state) {
            if (state is CheckoutInitial) {
              context.read<CheckoutCubit>().start();
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CheckoutInProgress) {
              return _CheckoutForm(state: state);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _CheckoutForm extends StatelessWidget {
  final CheckoutInProgress state;
  const _CheckoutForm({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Step indicators
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _StepDot(step: 1, current: state.step + 1, label: 'Address'),
              const Expanded(child: Divider()),
              _StepDot(step: 2, current: state.step + 1, label: 'Delivery'),
              const Expanded(child: Divider()),
              _StepDot(step: 3, current: state.step + 1, label: 'Payment'),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: [
              const _AddressStep(),
              const _DeliveryStep(),
              const _PaymentStep(),
            ][state.step],
          ),
        ),

        BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            final total = cartState is CartLoaded ? cartState.total : 0.0;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  if (state.step < 2)
                    AppButton(
                      label: 'Continue',
                      onPressed: () =>
                          context.read<CheckoutCubit>().nextStep(),
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.fullWidth,
                    )
                  else
                    BlocBuilder<CheckoutCubit, CheckoutState>(
                      builder: (context, s) {
                        return AppButton(
                          label:
                              'Place Order · ${CurrencyFormatter.format(total)}',
                          onPressed: () =>
                              context.read<CheckoutCubit>().placeOrder(),
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.fullWidth,
                          isLoading: false,
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AddressStep extends StatelessWidget {
  const _AddressStep();

  static const _addresses = [
    '🏠 Home — 42, Nehru Street, Andheri West, Mumbai - 400053',
    '🏢 Office — 301, Tech Park, Whitefield, Bengaluru - 560066',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Delivery Address',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        ..._addresses.asMap().entries.map((e) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Radio<int>(
                value: e.key,
                groupValue: 0,
                onChanged: (_) {},
                activeColor: AppColors.primary,
              ),
              title: Text(e.value,
                  style: const TextStyle(fontSize: 13)),
              selected: e.key == 0,
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: '+ Add New Address',
          onPressed: () {},
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.fullWidth,
        ),
      ],
    );
  }
}

class _DeliveryStep extends StatefulWidget {
  const _DeliveryStep();

  @override
  State<_DeliveryStep> createState() => _DeliveryStepState();
}

class _DeliveryStepState extends State<_DeliveryStep> {
  DeliveryType _selected = DeliveryType.standard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Options',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        ...DeliveryType.values.map((type) {
          final (label, days, price) = switch (type) {
            DeliveryType.standard => ('Standard', '5-7 days', '₹49'),
            DeliveryType.express => ('Express', '2-3 days', '₹99'),
            DeliveryType.sameDay => ('Same Day', 'Today', '₹149'),
          };
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: _selected == type
                    ? BorderSide(color: AppColors.primary, width: 2)
                    : BorderSide.none),
            child: ListTile(
              onTap: () {
                setState(() => _selected = type);
                context.read<CheckoutCubit>().selectDelivery(type);
              },
              leading: Radio<DeliveryType>(
                value: type,
                groupValue: _selected,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selected = v);
                    context.read<CheckoutCubit>().selectDelivery(v);
                  }
                },
                activeColor: AppColors.primary,
              ),
              title: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(days),
              trailing: Text(price,
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
          );
        }),
      ],
    );
  }
}

class _PaymentStep extends StatefulWidget {
  const _PaymentStep();

  @override
  State<_PaymentStep> createState() => _PaymentStepState();
}

class _PaymentStepState extends State<_PaymentStep> {
  String _selected = 'upi';

  static const _methods = [
    ('upi', 'UPI / GPay / PhonePe', Icons.account_balance_wallet_rounded),
    ('card', 'Credit / Debit Card', Icons.credit_card_rounded),
    ('cod', 'Cash on Delivery', Icons.payments_outlined),
    ('netbanking', 'Net Banking', Icons.account_balance_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        ..._methods.map((m) {
          final (key, label, icon) = m;
          final isSelected = _selected == key;
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? BorderSide(color: AppColors.primary, width: 2)
                    : BorderSide.none),
            child: ListTile(
              onTap: () {
                setState(() => _selected = key);
                context.read<CheckoutCubit>().selectPayment(key);
              },
              leading: Icon(icon,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textMuted),
              title: Text(label),
              trailing: Radio<String>(
                value: key,
                groupValue: _selected,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selected = v);
                    context.read<CheckoutCubit>().selectPayment(v);
                  }
                },
                activeColor: AppColors.primary,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int step;
  final int current;
  final String label;

  const _StepDot(
      {required this.step, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final isActive = step <= current;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.textMuted.withOpacity(0.3),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                  color: isActive ? Colors.white : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ),
        ),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.primary : AppColors.textMuted)),
      ],
    );
  }
}

class _OrderSuccessDialog extends StatelessWidget {
  final String orderNumber;
  final VoidCallback onGoToOrders;

  const _OrderSuccessDialog(
      {required this.orderNumber, required this.onGoToOrders});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 48),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Order Placed! 🎉',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Order #$orderNumber',
                style: TextStyle(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'We\'ll send you updates on your print order. Estimated delivery in 5-7 business days.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Track Order',
              onPressed: onGoToOrders,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.fullWidth,
            ),
          ],
        ),
      ),
    );
  }
}
