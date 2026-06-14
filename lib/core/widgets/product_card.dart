import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../../data/models/product_model.dart';
import '../utils/currency_formatter.dart';
import 'shimmer_loader.dart';
import 'app_button.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onDesignNow;
  final int animationDelay;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onDesignNow,
    this.animationDelay = 0,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      delay: Duration(milliseconds: widget.animationDelay),
      duration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: widget.onTap,
        splashColor: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: AppSpacing.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area (60%)
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    // Product image
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: widget.product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const ShimmerLoader(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: BorderRadius.zero,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    // Badge top-left
                    if (widget.product.badge != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.product.badge == 'BESTSELLER'
                                ? AppColors.accent
                                : widget.product.badge == 'NEW'
                                    ? AppColors.success
                                    : AppColors.error,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusPill),
                          ),
                          child: Text(
                            widget.product.badge!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // Heart icon top-right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isFavorite = !_isFavorite);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppSpacing.cardShadow,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey(_isFavorite),
                              size: 16,
                              color: _isFavorite
                                  ? AppColors.error
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info area (40%)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product name
                      Text(
                        widget.product.name,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Rating row
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: widget.product.rating,
                            itemSize: 12,
                            itemBuilder: (_, __) => const Icon(
                              Icons.star_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${widget.product.reviewCount})',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CurrencyFormatter.format(
                                      widget.product.basePrice),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                                if (widget.product.originalPrice >
                                    widget.product.basePrice)
                                  Text(
                                    CurrencyFormatter.format(
                                        widget.product.originalPrice),
                                    style: AppTextStyles.strikethrough
                                        .copyWith(fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
                          // Design now button
                          AppButton.small(
                            label: 'Design',
                            onPressed: widget.onDesignNow,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
