import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/category_chip.dart';
import '../../data/models/app_models.dart';
import '../../data/mock_data/mock_reviews.dart';
import '../../features/cart/cart_cubit.dart';
import '../../features/products/products_cubit.dart';
import '../../services/upload_service.dart';
import '../../features/misc_cubits.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _instructionsController = TextEditingController();

  bool _isCustomizeExpanded = false;

  // Selected customer design file (optional)
  File? _selectedDesignFile;
  String? _selectedDesignFileName;
  String? _selectedDesignUrl; // returned after upload

  @override
  void initState() {
    super.initState();
    print('\n🔍 [ProductDetailScreen] initState productId=${widget.productId}');
    context.read<ProductDetailCubit>().loadProductById(widget.productId);
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  bool get _hasSelectedDesign =>
      _selectedDesignUrl != null && (_selectedDesignFileName ?? '').isNotEmpty;

  bool get _isSelectedDesignPdf =>
      (_selectedDesignFileName ?? '').toLowerCase().endsWith('.pdf');

  Future<void> _pickAndUploadDesign() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.first;
      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected file is not accessible.')),
        );
        return;
      }

      final localFile = File(file.path!);
      final uploadRes =
          await UploadService.uploadCustomerDesign(file: localFile);

      setState(() {
        _selectedDesignFile = localFile;
        _selectedDesignFileName = uploadRes['filename'];
        _selectedDesignUrl = uploadRes['url'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _addToCart(ProductDetailLoaded state) async {
    // Customized flow add (uploads only if a file is selected).
    if (_selectedDesignFile != null &&
        (_selectedDesignUrl == null || _selectedDesignFileName == null)) {
      final uploadRes =
          await UploadService.uploadCustomerDesign(file: _selectedDesignFile!);
      setState(() {
        _selectedDesignFileName = uploadRes['filename'];
        _selectedDesignUrl = uploadRes['url'];
      });
    }

    final instructions = _instructionsController.text;
    final customDesignUrlToAdd = _selectedDesignUrl;
    final customDesignFileNameToAdd = _selectedDesignFileName;

    context.read<CartCubit>().addProduct(
          state.product,
          quantity: state.selectedQty,
          size: state.selectedSize,
          finish: state.selectedFinish,
          customDesignUrl: customDesignUrlToAdd,
          customDesignFileName: customDesignFileNameToAdd,
          customerInstructions: instructions,
        );

    // Reset ONLY temporary customization UI state AFTER success.
    setState(() {
      _isCustomizeExpanded = false;

      _selectedDesignFile = null;
      _selectedDesignFileName = null;
      _selectedDesignUrl = null;

      _instructionsController.clear();
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart!')),
    );
  }

  Future<void> _addToCartNormal(ProductDetailLoaded state) async {
    // Normal flow add: never upload any design and always clear custom fields.
    context.read<CartCubit>().addProduct(
          state.product,
          quantity: state.selectedQty,
          size: state.selectedSize,
          finish: state.selectedFinish,
          customDesignUrl: null,
          customDesignFileName: null,
          customerInstructions: "",
        );

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart!')),
    );
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
                    decoration: BoxDecoration(
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
                                horizontal: 10,
                                vertical: 4,
                              ),
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
                                            color: AppColors.primary,
                                            width: 2,
                                          )
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

                      // REQUIRED NEW LAYOUT
                      Text('Product Information',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.sm),

                      Text('Price',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        CurrencyFormatter.format(product.basePrice),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Text('Quantity',
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

                      if (product.sizes.isNotEmpty) ...[
                        Text('Size',
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

                      if (product.finishes.isNotEmpty) ...[
                        Text('Finish',
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

                      Text('Description',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        product.description,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Customize button (optional)
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _isCustomizeExpanded = true),
                            child: Text(
                              'Customize',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // NORMAL Add To Cart button (always visible; never uploads designs)
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          label: 'Add To Cart',
                          onPressed: () => _addToCartNormal(state),
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.large,
                        ),
                      ),

                      if (_isCustomizeExpanded) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),
                        Text('Upload Your Design',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: _pickAndUploadDesign,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.upload_file_rounded,
                                        color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Select file',
                                      style:
                                          TextStyle(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (_hasSelectedDesign)
                                  Text(
                                    'Selected: $_selectedDesignFileName',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (_selectedDesignUrl != null &&
                                    !_isSelectedDesignPdf)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _selectedDesignUrl!,
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, _, __) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                if (_selectedDesignUrl != null &&
                                    _isSelectedDesignPdf)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.picture_as_pdf_rounded,
                                            color: AppColors.error),
                                        const SizedBox(width: 10),
                                        Flexible(
                                          child: Text(
                                            _selectedDesignFileName ?? 'PDF',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Customer Instructions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: _instructionsController,
                          minLines: 3,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText: 'Enter printing instructions',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Back',
                                onPressed: () => setState(
                                    () => _isCustomizeExpanded = false),
                                variant: AppButtonVariant.outline,
                                size: AppButtonSize.large,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButton(
                                label: 'Add To Cart',
                                onPressed: () => _addToCart(state),
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.large,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      const Divider(),
                      const SizedBox(height: AppSpacing.md),

                      if (reviews.isNotEmpty) ...[
                        const Divider(height: AppSpacing.xl),
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
          bottomNavigationBar: const SizedBox.shrink(),
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
                Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                RatingBarIndicator(
                  rating: review.rating,
                  itemBuilder: (_, __) => const Icon(
                    Icons.star_rounded,
                    color: AppColors.warning,
                  ),
                  itemCount: 5,
                  itemSize: 14,
                ),
                Text(
                  review.comment,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
