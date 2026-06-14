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
  PasswordStrength _strength = PasswordStrength.none;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
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
        if (state is AuthOtpSent) {
          context.go('/auth/otp?phone=${_phoneCtrl.text.trim()}');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
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
                    const SizedBox(height: AppSpacing.xxl),
                    FadeInDown(
                      child: Text(
                        'Create Account ✨',
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
                        'Join PrintX and start printing today',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: AppTextField(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        hint: 'Raj Kumar',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: Validators.fullName,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeInUp(
                      delay: const Duration(milliseconds: 250),
                      child: AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'you@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: AppTextField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        hint: '9876543210',
                        prefixIcon: Icons.phone_outlined,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12, right: 8),
                          child: Icon(Icons.phone_outlined,
                              size: 20, color: AppColors.textMuted),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeInUp(
                      delay: const Duration(milliseconds: 350),
                      child: AppTextField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        hint: 'Min 8 characters',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: Validators.password,
                        onChanged: (val) {
                          setState(() {
                            _strength = Validators.passwordStrength(val);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_strength != PasswordStrength.none)
                      FadeInUp(
                        child: _PasswordStrengthBar(strength: _strength),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        return FadeInUp(
                          delay: const Duration(milliseconds: 450),
                          child: AppButton(
                            label: 'Create Account',
                            onPressed: _submit,
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.fullWidth,
                            isLoading: state is AuthLoading,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/auth/login'),
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final (color, label, fill) = switch (strength) {
      PasswordStrength.none => (Colors.grey, 'None', 0),
      PasswordStrength.weak => (AppColors.error, 'Weak', 1),
      PasswordStrength.fair => (AppColors.warning, 'Fair', 2),
      PasswordStrength.good => (AppColors.info, 'Good', 3),
      PasswordStrength.strong => (AppColors.success, 'Strong', 4),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < fill ? color : AppColors.textMuted.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $label',
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
