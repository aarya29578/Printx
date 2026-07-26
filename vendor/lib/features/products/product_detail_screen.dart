import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/category_chip.dart';
import '../../data/models/app_models.dart';
import '../../data/mock_data/mock_reviews.dart';
import '../../features/products/products_cubit.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductDetailCubit>().loadProductById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ProductDetailCubit, ProductDetailState>(
      builder: (context, state) {
        if (state is! ProductDetailLoaded) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final product = state.product;
        final reviews = MockReviews.getByProduct(product.id);

        return Scaffold(
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'product_${product.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: product.imageUrls[state.currentImageIndex],
                          fit: BoxFit.cover,
                        ),
                        if (product.badge != null)
                          Positioned(
                            top: 60,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.badge!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail strip
                      if (product.imageUrls.length > 1)
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: product.imageUrls.length,
                            itemBuilder: (_, i) {
                              final isSelected = i == state.currentImageIndex;
                              return GestureDetector(
                                onTap: () => context
                                    .read<ProductDetailCubit>()
                                    .setImageIndex(i),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.primary, width: 2)
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: product.imageUrls[i],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: AppSpacing.md),

                      // Product name
                      Text(
                        product.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Price
                      Text(
                        CurrencyFormatter.format(product.basePrice),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Quantities
                      if (product.quantities.isNotEmpty) ...[
                        Text('Order Quantities',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: product.quantities.map((qty) {
                            final isSelected = qty == state.selectedQty;
                            return FilterChipWidget(
                              label: '$qty pcs',
                              isSelected: isSelected,
                              onTap: () => context
                                  .read<ProductDetailCubit>()
                                  .selectQty(qty),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Sizes
                      if (product.sizes.isNotEmpty) ...[
                        Text('Available Sizes',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: product.sizes.map((size) {
                            final isSelected = size == state.selectedSize;
                            return FilterChipWidget(
                              label: size,
                              isSelected: isSelected,
                              onTap: () => context
                                  .read<ProductDetailCubit>()
                                  .selectSize(size),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Finishes
                      if (product.finishes.isNotEmpty) ...[
                        Text('Available Finishes',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: product.finishes.map((f) {
                            final isSelected = f == state.selectedFinish;
                            return FilterChipWidget(
                              label: f,
                              isSelected: isSelected,
                              onTap: () => context
                                  .read<ProductDetailCubit>()
                                  .selectFinish(f),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Description
                      Text('Description',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        product.description,
                        style: const TextStyle(
                            color: AppColors.textMuted, height: 1.6),
                      ),

                      // Tags
                      if (product.tags.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('Tags',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: product.tags
                              .map((tag) => Chip(
                                    label: Text(tag,
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    labelStyle: const TextStyle(
                                        color: AppColors.primary),
                                    side: BorderSide.none,
                                  ))
                              .toList(),
                        ),
                      ],

                      const Divider(height: AppSpacing.xl),

                      // Reviews
                      if (reviews.isNotEmpty) ...[
                        Text('Customer Reviews',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.sm),
                        ...reviews.map((r) => _ReviewTile(review: r)),
                      ],

                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: review.userAvatar != null
                ? CachedNetworkImageProvider(review.userAvatar!)
                : null,
            child: review.userAvatar == null
                ? const Icon(Icons.person_rounded)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review.userName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                RatingBarIndicator(
                  rating: review.rating,
                  itemBuilder: (_, __) => const Icon(
                    Icons.star_rounded,
                    color: AppColors.warning,
                  ),
                  itemCount: 5,
                  itemSize: 14,
                ),
                Text(review.comment,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
