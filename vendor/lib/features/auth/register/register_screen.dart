import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../auth_cubit.dart';
import '../../../services/upload_service.dart';
import '../../auth/auth_cubit.dart';

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
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  PasswordStrength _strength = PasswordStrength.none;

  final _picker = ImagePicker();
  File? _pickedImage;
  bool _uploading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFrom(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 85);
    if (xfile == null) return;
    setState(() => _pickedImage = File(xfile.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _uploading = true);
    try {
      // 1) Register auth + initial profile doc (with address)
      context.read<AuthCubit>().register(
            _nameCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _phoneCtrl.text.trim(),
            _passwordCtrl.text,
            address: _addressCtrl.text.trim(),
          );

      // Wait until auth finishes (either authenticated or unauthenticated).
      final authState = await context.read<AuthCubit>().stream.firstWhere(
            (s) =>
                s is AuthAuthenticated ||
                s is AuthUnauthenticated ||
                s is AuthError,
          );

      if (!mounted) return;

      if (authState is AuthAuthenticated) {
        final uid = authState.userId;

        // 2) Upload profile image (optional) and update user doc
        if (_pickedImage != null) {
          final url = await UploadService.uploadProfileImage(
            imageFile: _pickedImage!,
          );
          if (url == null) throw Exception('Profile image upload failed');

          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'profileImage': url,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
          context.go('/home');
        }
        return;
      }

      if (authState is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authState.message)),
        );
        return;
      }

      // AuthUnauthenticated or any other state: treat as failure.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up failed. Please try again.')),
      );
      return;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // We handle navigation after upload in _submit().
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
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
                      child: Center(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 52,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _pickedImage != null
                                      ? FileImage(_pickedImage!)
                                      : null,
                                  child: _pickedImage == null
                                      ? const Icon(Icons.person, size: 40)
                                      : null,
                                ),
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: InkWell(
                                    onTap: () => _pickFrom(ImageSource.gallery),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 18,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Profile image',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // This section is inside a scrollable Column. Avoid letting
                            // OutlinedButton receive infinite width constraints.
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickFrom(ImageSource.gallery),
                                    icon: const Icon(
                                        Icons.photo_library_outlined),
                                    label: const Text('Gallery'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickFrom(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: const Text('Camera'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeInUp(
                      delay: const Duration(milliseconds: 150),
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
                      delay: const Duration(milliseconds: 200),
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
                      delay: const Duration(milliseconds: 250),
                      child: AppTextField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        hint: '9876543210',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: AppTextField(
                        controller: _addressCtrl,
                        label: 'Address',
                        hint: 'House / Street / City',
                        prefixIcon: Icons.location_on_outlined,
                        validator: (v) =>
                            Validators.required(v, field: 'Address'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FadeInUp(
                      delay: const Duration(milliseconds: 350),
                      child: AppTextField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        hint: 'Min 6 characters',
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
                    FadeInUp(
                      delay: const Duration(milliseconds: 380),
                      child: AppTextField(
                        controller: _confirmPasswordCtrl,
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.isEmpty)
                            return 'Confirm password is required';
                          if (val != _passwordCtrl.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_strength != PasswordStrength.none)
                      FadeInUp(
                        child: _PasswordStrengthBar(strength: _strength),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    FadeInUp(
                      delay: const Duration(milliseconds: 450),
                      child: SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: _uploading ? 'Creating...' : 'Create Account',
                          onPressed: _uploading ? null : _submit,
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.fullWidth,
                          isLoading: _uploading,
                        ),
                      ),
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
                  color:
                      i < fill ? color : AppColors.textMuted.withOpacity(0.2),
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
