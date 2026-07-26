import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_toast.dart';
import '../../data/models/product_model.dart';
import '../../features/auth/auth_cubit.dart';
import '../../services/firestore_service.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Please log in.')),
      );
    }
    final vendorId = authState.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: const Text('My Products',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/vendor/add-product'),
            tooltip: 'Add Product',
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: FirestoreService.watchVendorProducts(vendorId: vendorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final products = snapshot.data ?? [];
          if (products.isEmpty) {
            return _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: products.length,
            itemBuilder: (context, index) =>
                _ProductTile(product: products[index], vendorId: vendorId),
          );
        },
      ),
    );
  }
}

// ─── Product tile ─────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final Product product;
  final String vendorId;

  const _ProductTile({required this.product, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/product/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.image_not_supported,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(product.basePrice),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    _LiveStatusChip(productId: product.id),
                  ],
                ),
              ),
              // Actions menu
              _ProductMenu(product: product, vendorId: vendorId),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Live status chip ─────────────────────────────────────────────────────────

class _LiveStatusChip extends StatelessWidget {
  final String productId;
  const _LiveStatusChip({required this.productId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .snapshots(),
      builder: (context, snap) {
        final status =
            (snap.data?.data()?['status'] as String?) ?? 'active';
        final isActive = status == 'active';
        final isPaused = status == 'paused';

        Color color;
        String label;
        if (isActive) {
          color = AppColors.success;
          label = 'Active';
        } else if (isPaused) {
          color = AppColors.warning;
          label = 'Paused';
        } else if (status == 'draft') {
          color = AppColors.textMuted;
          label = 'Draft';
        } else {
          color = AppColors.textMuted;
          label = status;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }
}

// ─── Product actions menu ─────────────────────────────────────────────────────

class _ProductMenu extends StatelessWidget {
  final Product product;
  final String vendorId;

  const _ProductMenu({required this.product, required this.vendorId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _handleAction(context, value),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined, size: 18),
            title: Text('Edit Product'),
          ),
        ),
        PopupMenuItem(
          value: product.status == 'paused' ? 'resume' : 'pause',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              product.status == 'paused'
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              size: 18,
            ),
            title: Text(product.status == 'paused'
                ? 'Resume Listing'
                : 'Pause Listing'),
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.copy_outlined, size: 18),
            title: Text('Duplicate'),
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.share_outlined, size: 18),
            title: Text('Share'),
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.error),
            title: Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'edit':
        context.push('/vendor/edit-product/${product.id}');
        break;
      case 'pause':
        await _toggleStatus(context, 'paused');
        break;
      case 'resume':
        await _toggleStatus(context, 'active');
        break;
      case 'duplicate':
        await _duplicateProduct(context);
        break;
      case 'share':
        Share.share(
            'Check out ${product.name} on PrintX!\n${product.imageUrl}');
        break;
      case 'delete':
        await _confirmDelete(context);
        break;
    }
  }

  Future<void> _toggleStatus(BuildContext context, String newStatus) async {
    try {
      await FirestoreService.updateProductStatus(
          productId: product.id, status: newStatus);
      if (!context.mounted) return;
      AppToast.show(
        context,
        newStatus == 'paused' ? 'Product paused' : 'Product resumed',
        type: ToastType.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }

  Future<void> _duplicateProduct(BuildContext context) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .get();
      if (!snap.exists || !context.mounted) return;

      final data = Map<String, dynamic>.from(snap.data()!);
      final newId = 'PRD${DateTime.now().millisecondsSinceEpoch}';
      data['name'] = 'Copy of ${data['name'] ?? product.name}';
      data['id'] = newId;
      data['status'] = 'draft';
      data['sku'] = 'SKU-$newId';
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('products')
          .doc(newId)
          .set(data);

      if (!context.mounted) return;
      AppToast.show(context, 'Duplicated as draft',
          type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Permanently remove "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .doc(product.id)
          .get();
      final categoryId =
          (snap.data()?['category'] as String?) ?? '';

      await FirestoreService.deleteProduct(
          productId: product.id, categoryId: categoryId);

      if (!context.mounted) return;
      AppToast.show(context, 'Product deleted', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, 'Failed: $e', type: ToastType.error);
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          const Text('No products yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Start selling by adding your first product.',
            style: TextStyle(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () => context.go('/vendor/add-product'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
