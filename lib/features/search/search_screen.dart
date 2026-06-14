import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/widgets/product_card.dart';
import '../../data/models/product_model.dart';
import '../../features/misc_cubits.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  List<Product> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      FirestoreService.fetchProducts().then((products) {
        final normalized = query.toLowerCase();
        final results = products.where((item) {
          return item.name.toLowerCase().contains(normalized) ||
              item.category.toLowerCase().contains(normalized) ||
              item.description.toLowerCase().contains(normalized);
        }).toList();
        setState(() {
          _results = results;
          _isSearching = false;
        });
        StorageService.addRecentSearch(query.trim());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recents = StorageService.recentSearches;

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
          tag: 'search_bar',
          child: Material(
            color: Colors.transparent,
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search products...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchCtrl.clear();
                _onSearch('');
              },
              icon: const Icon(Icons.clear_rounded),
            ),
        ],
      ),
      body: _buildBody(recents, isDark),
    );
  }

  Widget _buildBody(List<String> recents, bool isDark) {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: ShimmerList(count: 3),
      );
    }

    if (_searchCtrl.text.isEmpty) {
      // Show recent searches
      if (recents.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_rounded, size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text('Search for products, categories...',
                  style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                TextButton(
                  onPressed: () {
                    StorageService.clearRecentSearches();
                    setState(() {});
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            ...recents.map((r) => ListTile(
                  leading: const Icon(Icons.history_rounded,
                      color: AppColors.textMuted),
                  title: Text(r),
                  onTap: () {
                    _searchCtrl.text = r;
                    _onSearch(r);
                  },
                )),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text('No results for "${_searchCtrl.text}"',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: index * 60),
          child: ProductCard(
            product: _results[index],
            onTap: () => context.push('/product/${_results[index].id}'),
            onDesignNow: () => context.push('/editor'),
          ),
        );
      },
    );
  }
}
