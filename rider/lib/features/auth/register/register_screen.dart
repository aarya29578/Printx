import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().register(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _phoneCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Header
                    FadeInDown(
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientDelivery,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delivery_dining_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PrintX Rider',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary),
                              ),
                              const Text(
                                'Delivery Partner Portal',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    FadeInDown(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'Create Account',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                                fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FadeInDown(
                      delay: const Duration(milliseconds: 150),
                      child: const Text(
                        'Register as a delivery partner to start earning.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Full Name
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: AppTextField(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        hint: 'Raj Kumar',
                        prefixIcon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.required(v, fieldName: 'Full Name'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Email
                    FadeInUp(
                      delay: const Duration(milliseconds: 250),
                      child: AppTextField(
                        controller: _emailCtrl,
                        label: 'Email Address',
                        hint: 'rider@printx.in',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Phone
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: AppTextField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        hint: '9876543210',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: Validators.phone,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password
                    FadeInUp(
                      delay: const Duration(milliseconds: 350),
                      child: AppTextField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        hint: 'Min 6 characters',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: Validators.password,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Confirm Password
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: AppTextField(
                        controller: _confirmPasswordCtrl,
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (val != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Submit button
                    FadeInUp(
                      delay: const Duration(milliseconds: 450),
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) => AppButton(
                          label: 'Create Account',
                          isLoading: state is AuthLoading,
                          onPressed: _submit,
                          prefixIcon: Icons.person_add_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Already have account
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/auth/login'),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
