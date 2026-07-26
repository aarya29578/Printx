import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../features/auth/auth_cubit.dart';
import '../../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.gradientDelivery),
                child: SafeArea(
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _userStream(),
                    builder: (context, snap) {
                      final data = snap.data?.data();
                      final name = (data?['fullName'] as String?) ?? '';
                      final email = (data?['email'] as String?) ?? '';
                      final imageUrl =
                          (data?['profileImage'] as String?) ?? '';
                      final partnerId =
                          (data?['deliveryPartnerId'] as String?) ??
                              (data?['partnerId'] as String?) ??
                              FirebaseAuth.instance.currentUser?.uid
                                  .substring(0, 8)
                                  .toUpperCase() ??
                              '';

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeInDown(
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: imageUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(imageUrl)
                                      : null,
                                  child: imageUrl.isEmpty
                                      ? const Icon(Icons.person_rounded,
                                          color: Colors.white, size: 40)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.delivery_dining_rounded,
                                      size: 14,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeInUp(
                            child: Text(
                              name.isNotEmpty ? name : 'Rider',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          FadeInUp(
                            delay: const Duration(milliseconds: 100),
                            child: Text(
                              email,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FadeInUp(
                            delay: const Duration(milliseconds: 150),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'Partner ID: $partnerId',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
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
                stream: _userStream(),
                builder: (context, snap) {
                  final data = snap.data?.data();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Rider Info ─────────────────────────────────────
                      _SectionHeader('Rider Information'),
                      _InfoCard(children: [
                        _InfoTile(
                          icon: Icons.badge_rounded,
                          label: 'Full Name',
                          value: (data?['fullName'] as String?) ?? '—',
                        ),
                        _InfoTile(
                          icon: Icons.phone_rounded,
                          label: 'Phone',
                          value: (data?['phoneNumber'] as String?) ??
                              (data?['phone'] as String?) ??
                              '—',
                        ),
                        _InfoTile(
                          icon: Icons.email_rounded,
                          label: 'Email',
                          value: (data?['email'] as String?) ?? '—',
                        ),
                      ]),

                      const SizedBox(height: AppSpacing.md),

                      // ── Vehicle Info ───────────────────────────────────
                      _SectionHeader('Vehicle Information'),
                      _InfoCard(children: [
                        _InfoTile(
                          icon: Icons.two_wheeler_rounded,
                          label: 'Vehicle Type',
                          value: (data?['vehicleType'] as String?) ?? '—',
                        ),
                        _InfoTile(
                          icon: Icons.confirmation_number_rounded,
                          label: 'Vehicle Number',
                          value: (data?['vehicleNumber'] as String?) ?? '—',
                        ),
                        _InfoTile(
                          icon: Icons.card_membership_rounded,
                          label: 'Partner ID',
                          value: (data?['deliveryPartnerId'] as String?) ??
                              (data?['partnerId'] as String?) ??
                              FirebaseAuth.instance.currentUser?.uid
                                  .substring(0, 8)
                                  .toUpperCase() ??
                              '—',
                        ),
                      ]),

                      const SizedBox(height: AppSpacing.md),

                      // ── Settings ───────────────────────────────────────
                      _SectionHeader('Settings'),
                      _InfoCard(children: [
                        // Online / Offline toggle
                        _ToggleTile(
                          icon: (data?['online'] == true)
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          label: 'Available for Deliveries',
                          value: (data?['online'] as bool?) ?? false,
                          onChanged: (val) async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) return;
                            try {
                              await FirestoreService.setOnlineStatus(
                                  riderId: uid, online: val);
                              if (!context.mounted) return;
                              AppToast.show(
                                context,
                                val ? 'You are now Online' : 'You are now Offline',
                                type: val ? ToastType.success : ToastType.info,
                              );
                            } catch (_) {}
                          },
                        ),
                        BlocBuilder<ThemeCubit, ThemeMode>(
                          builder: (context, mode) => _ToggleTile(
                            icon: mode == ThemeMode.dark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            label: 'Dark Mode',
                            value: mode == ThemeMode.dark,
                            onChanged: (_) =>
                                context.read<ThemeCubit>().toggle(),
                          ),
                        ),
                      ]),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Logout ─────────────────────────────────────────
                      AppButton(
                        label: 'Logout',
                        variant: AppButtonVariant.danger,
                        prefixIcon: Icons.logout_rounded,
                        onPressed: () => _confirmLogout(context),
                      ),

                      const SizedBox(height: AppSpacing.xxl),
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

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AuthCubit>().logout();
    if (!context.mounted) return;
    context.go('/auth/login');
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 4),
      child: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: AppColors.primary),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(label,
          style:
              const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      subtitle: Text(value,
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      dense: true,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      value: value,
      activeThumbColor: AppColors.primary,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
      onChanged: onChanged,
    );
  }
}
