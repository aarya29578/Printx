import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/widgets/category_chip.dart';
import '../../data/models/category_model.dart';
import '../../features/products/products_cubit.dart';
import '../../services/firestore_service.dart';

class ProductListingScreen extends StatefulWidget {
  final Category category;
  const ProductListingScreen({super.key, required this.category});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  String _selectedSort = 'popular';
  late Category _displayCategory;

  @override
  void initState() {
    super.initState();
    _displayCategory = widget.category;

    // Load full category details from Firestore
    _loadCategoryDetails();

    // Load products filtered by category ID
    context.read<ProductsCubit>().loadByCategory(widget.category.id);
  }

  void _loadCategoryDetails() async {
    try {
      print('\n📖 [PRODUCT_LISTING_SCREEN] _loadCategoryDetails()');
      print('  widget.category.id=${widget.category.id}');
      final categories = await FirestoreService.fetchCategories();
      print('  Fetched ${categories.length} categories from Firestore');
      final categoryNames = categories.map((c) => '${c.id}:${c.name}').toList();
      print('    Categories: $categoryNames');
      final category = categories.firstWhere(
        (cat) => cat.id == widget.category.id,
        orElse: () => widget.category,
      );
      print('  Found category: id=${category.id}, name=${category.name}');
      if (mounted) {
        setState(() => _displayCategory = category);
      }
    } catch (e) {
      print('  ❌ Error loading category: $e');
      // Ignore errors, use default category
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Hero(
          tag: 'category_${widget.category.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              _displayCategory.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (val) {
              setState(() => _selectedSort = val);
              context.read<ProductsCubit>().sortProducts(val);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'popular', child: Text('Popular')),
              PopupMenuItem(
                  value: 'price_low', child: Text('Price: Low to High')),
              PopupMenuItem(
                  value: 'price_high', child: Text('Price: High to Low')),
              PopupMenuItem(value: 'rating', child: Text('Top Rated')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<ProductsCubit, ProductsState>(
        builder: (context, state) {
          if (state is ProductsLoading) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: ShimmerList(count: 4),
            );
          }
          if (state is ProductsLoaded) {
            print(
                '\n✅ [UI] ProductsLoaded state: ${state.products.length} products');
            if (state.products.isEmpty) {
              print(
                  '  ❌ Displaying "No products found" - categoryId=${state.categoryId}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.md),
                    Text('No products found',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              );
            }
            return AnimationLimiter(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                ),
                itemCount: state.products.length,
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: ProductCard(
                          product: product,
                          onTap: () => context.push('/product/${product.id}'),
                          onDesignNow: () => context.push('/editor'),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
