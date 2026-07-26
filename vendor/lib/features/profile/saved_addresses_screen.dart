import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.bgDark
            : AppColors.bgLight,
        appBar: AppBar(title: const Text('Saved Addresses')),
        body: const Center(child: Text('No logged-in user found.')),
      );
    }

    final mainAddressStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => (snap.data()?['address'] as String?) ?? '');

    final listStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.bgDark
          : AppColors.bgLight,
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: StreamBuilder<String>(
        stream: mainAddressStream,
        builder: (context, mainSnap) {
          final mainAddress = mainSnap.data ?? '';

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: listStream,
            builder: (context, listSnap) {
              if (listSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (listSnap.hasError) {
                return Center(
                    child: Text('Failed to load addresses: ${listSnap.error}'));
              }

              final docs = listSnap.data?.docs ?? [];

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (mainAddress.isNotEmpty) ...[
                    _SectionTitle(title: 'Main Address'),
                    _AddressCard(title: 'Address', value: mainAddress),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  _SectionTitle(title: 'Other Saved Addresses'),
                  const SizedBox(height: AppSpacing.sm),
                  if (docs.isEmpty)
                    Text(
                      'No saved addresses yet. Add one below.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                          ),
                    )
                  else
                    ...docs.map((d) {
                      final value = (d.data()['address'] as String?) ?? '';
                      if (value.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _AddressCard(
                          title: 'Address',
                          value: value,
                        ),
                      );
                    }),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Add Address',
                    onPressed: () {
                      context.push('/profile/saved-addresses/add');
                    },
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.fullWidth,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class AddSavedAddressScreen extends StatefulWidget {
  const AddSavedAddressScreen({super.key});

  @override
  State<AddSavedAddressScreen> createState() => _AddSavedAddressScreenState();
}

class _AddSavedAddressScreenState extends State<AddSavedAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text('Add Address')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'House / Street / City',
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Address is required';
                    return null;
                  },
                  minLines: 3,
                  maxLines: 5,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: _saving ? 'Saving...' : 'Save Address',
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == null) return;

                          setState(() => _saving = true);
                          try {
                            final address = _addressCtrl.text.trim();
                            final now = FieldValue.serverTimestamp();

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('addresses')
                                .add({
                              'address': address,
                              'createdAt': now,
                            });

                            if (context.mounted) context.pop();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _saving = false);
                          }
                        },
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.fullWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String title;
  final String value;

  const _AddressCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
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
          ),
        ],
      ),
    );
  }
}
