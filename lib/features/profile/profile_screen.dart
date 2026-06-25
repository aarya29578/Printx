import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../features/auth/auth_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.gradientPrimary),
                child: SafeArea(
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _userDocStream(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data();

                      final fullName = (data?['fullName'] as String?) ?? '';
                      final email = (data?['email'] as String?) ?? '';
                      final imageUrl = (data?['profileImage'] as String?) ?? '';

                      final hasAnyField =
                          fullName.isNotEmpty || email.isNotEmpty;

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !hasAnyField) {
                        return const SizedBox.shrink();
                      }

                      if (!hasAnyField) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Profile not available',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeInDown(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: imageUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(imageUrl)
                                  : null,
                              child: imageUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 40,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeInUp(
                            child: Text(
                              fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          FadeInUp(
                            delay: const Duration(milliseconds: 100),
                            child: Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _userDocStream(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact Information Section
                      if (data != null &&
                          (data.containsKey('email') ||
                              data.containsKey('phoneNumber')))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (((data['email'] as String?) ?? '').isNotEmpty)
                              _KeyValueCard(
                                title: 'Email',
                                value: (data['email'] as String?) ?? '',
                              ),
                            if (((data['email'] as String?) ?? '').isNotEmpty &&
                                ((data['phoneNumber'] as String?) ?? '')
                                    .isNotEmpty)
                              const SizedBox(height: AppSpacing.sm),
                            if ((data['phoneNumber'] as String?)?.isNotEmpty ??
                                false)
                              _KeyValueCard(
                                title: 'Phone Number',
                                value: (data['phoneNumber'] as String?) ?? '',
                              ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),

                      // Address Information Section
                      if (data != null && (data.containsKey('address')))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Address',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (((data['address'] as String?) ?? '').isNotEmpty)
                              _KeyValueCard(
                                title: 'Address',
                                value: (data['address'] as String?) ?? '',
                              ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),

                      // Account Information Section
                      if (data != null && (data.containsKey('createdAt')))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Information',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (data['createdAt'] != null)
                              _KeyValueCard(
                                title: 'Date Joined',
                                value: _formatTimestamp(
                                    data['createdAt'] as Timestamp?),
                              ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),

                      _buildMenus(context, isDark),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not available';
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Widget _buildMenus(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ProfileMenuItem(
          icon: Icons.person_outline_rounded,
          label: 'Edit Profile',
          onTap: () => context.push('/profile/edit-profile'),
        ),
        _ProfileMenuItem(
          icon: Icons.location_on_outlined,
          label: 'Saved Addresses',
          onTap: () => context.push('/profile/saved-addresses'),
        ),
        _ProfileMenuItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Preferences',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ProfileMenuItemWithToggle(
          icon: Icons.dark_mode_outlined,
          label: 'Dark Mode',
          value: isDark,
          onChanged: (_) => context.read<ThemeCubit>().toggle(),
        ),
        _ProfileMenuItem(
          icon: Icons.language_rounded,
          label: 'Language',
          trailing: 'English',
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'More',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ProfileMenuItem(
          icon: Icons.share_outlined,
          label: 'Share App',
          onTap: () => Share.share(
            'Check out PrintX - Your premium printing partner!',
          ),
        ),
        _ProfileMenuItem(
          icon: Icons.star_outline_rounded,
          label: 'Rate Us',
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Sign Out',
          onPressed: () async {
            await context.read<AuthCubit>().logout();
            // Replace stack so back button can't return to authenticated screens.
            if (context.mounted) {
              context.go('/auth/login');
            }
          },
          variant: AppButtonVariant.danger,
          size: AppButtonSize.fullWidth,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _ProfileEmptyState extends StatelessWidget {
  final bool isDark;

  const _ProfileEmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'No profile details found.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Menus (preferences/signout) are still shown.
        // We reuse the original widget tree by rendering menus-only block.
        // To avoid duplication, keep it simple here.
        // NOTE: profileImage/name/email/phone/address are intentionally empty.
        // Sign out still works.
        const SizedBox.shrink(),
      ],
    );
  }
}

class _KeyValueCard extends StatelessWidget {
  final String title;
  final String value;

  const _KeyValueCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: trailing != null
            ? Text(trailing!, style: TextStyle(color: AppColors.textMuted))
            : const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ProfileMenuItemWithToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProfileMenuItemWithToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
