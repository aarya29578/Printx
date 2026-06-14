import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/category_model.dart';
import '../../services/firestore_service.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        title: const Text('All Categories',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: StreamBuilder<List<Category>>(
        stream: FirestoreService.watchCategories(),
        initialData: const [],
        builder: (context, snapshot) {
          final categories = snapshot.data ?? const <Category>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: _CategoryCard(
                        category: categories[index],
                        onTap: () =>
                            context.push('/products/${categories[index].id}'),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppColors
        .categoryColors[category.colorIndex % AppColors.categoryColors.length];
    final icon = _iconFromName(category.icon);

    return Hero(
      tag: 'category_${category.id}',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: category.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: color.withOpacity(0.3)),
                errorWidget: (_, __, ___) =>
                    Container(color: color.withOpacity(0.3)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      color.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
              ),
              Positioned(
                bottom: AppSpacing.md,
                left: AppSpacing.md,
                right: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${category.productCount} products',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFromName(String name) {
  switch (name) {
    case 'credit-card':
      return Icons.credit_card_rounded;
    case 'shirt':
      return Icons.checkroom_rounded;
    case 'image':
      return Icons.image_rounded;
    case 'coffee':
      return Icons.local_cafe_rounded;
    case 'file':
      return Icons.description_rounded;
    case 'book-open':
      return Icons.menu_book_rounded;
    case 'stamp':
      return Icons.sticky_note_2_rounded;
    case 'tag':
      return Icons.local_offer_rounded;
    case 'mail':
      return Icons.mail_rounded;
    case 'briefcase':
      return Icons.work_rounded;
    case 'gift':
      return Icons.card_giftcard_rounded;
    default:
      return Icons.category_rounded;
  }
}
