import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../auth_cubit.dart';

class OTPScreen extends StatefulWidget {
  final String phone;
  const OTPScreen({super.key, required this.phone});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _pinController = TextEditingController();
  Timer? _timer;
  int _seconds = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _resend() {
    setState(() => _seconds = 60);
    _startTimer();
  }

  void _verify() {
    if (_pinController.text.length == 6) {
      context.read<AuthCubit>().verifyOtp(_pinController.text);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 60,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppColors.textDark,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
          _pinController.clear();
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  FadeInDown(
                    child: Text(
                      'Verify OTP 🔐',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'We sent a 6-digit code to +91 ${widget.phone}',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Center(
                      child: Pinput(
                        controller: _pinController,
                        length: 6,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        onCompleted: (_) => _verify(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: LinearPercentIndicator(
                      percent: _seconds / 60,
                      progressColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      barRadius: const Radius.circular(8),
                      lineHeight: 6,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: Text(
                      _seconds > 0
                          ? 'Resend in ${_seconds}s'
                          : 'Didn\'t get the code?',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                  if (_seconds == 0) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Center(
                      child: TextButton(
                        onPressed: _resend,
                        child: const Text('Resend OTP'),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      return FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: AppButton(
                          label: 'Verify & Continue',
                          onPressed: _verify,
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.fullWidth,
                          isLoading: state is AuthLoading,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
