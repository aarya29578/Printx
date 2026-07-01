import 'package:animate_do/animate_do.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../features/cart/cart_cubit.dart';
import '../../features/products/products_cubit.dart';
import '../../data/models/app_models.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const _HomeShimmer();
            }
            if (state is HomeLoaded) {
              return _HomeContent(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final HomeLoaded state;
  const _HomeContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('P',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('PrintX',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => context.push('/search'),
            ),
            BlocBuilder<CartCubit, CartState>(
              builder: (context, cartState) {
                final count =
                    cartState is CartLoaded ? cartState.items.length : 0;
                return badges.Badge(
                  showBadge: count > 0,
                  badgeContent: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () => context.push('/cart'),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Carousel
              _BannerCarousel(banners: state.banners),
              const SizedBox(height: AppSpacing.lg),

              // Categories section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Categories',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => context.go('/categories'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 100,
                child: StreamBuilder<List<Category>>(
                  stream: FirestoreService.watchCategories(),
                  initialData: state.categories,
                  builder: (context, snapshot) {
                    final categories = snapshot.data ?? state.categories;
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: CategoryChip(
                            label: cat.name,
                            icon: _iconFromName(cat.icon),
                            color: AppColors.categoryColors[cat.colorIndex %
                                AppColors.categoryColors.length],
                            isSelected: false,
                            onTap: () => context.push('/products/${cat.id}'),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Trending
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('Trending Now 🔥',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: ProductCard(
                        product: state.trending[index],
                        onTap: () => context
                            .push('/product/${state.trending[index].id}'),
                      ),
                    ),
                  ),
                );
              },
              childCount: state.trending.length,
            ),
          ),
        ),
        // Coupons strip
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('Offers & Coupons 🎁',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: state.coupons.length,
                  itemBuilder: (context, i) =>
                      _CouponCard(coupon: state.coupons[i]),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerCarousel extends StatelessWidget {
  final List<BannerModel> banners;
  const _BannerCarousel({required this.banners});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        viewportFraction: 0.92,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 4),
        enlargeCenterPage: true,
        enableInfiniteScroll: true,
      ),
      items: banners.map((banner) {
        return FadeInUp(
          child: GestureDetector(
            onTap: () {},
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: banner.primaryColor.withOpacity(0.5),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          banner.subtitle,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppColors.gradientSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            coupon.code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            coupon.description,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 60),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: ShimmerLoader(width: double.infinity, height: 180),
          ),
          SizedBox(height: AppSpacing.md),
          ShimmerList(count: 2),
        ],
      ),
    );
  }
}

IconData _iconFromName(String name) {
  switch (name) {
    case 'credit_card':
      return Icons.credit_card_rounded;
    case 'checkroom':
      return Icons.checkroom_rounded;
    case 'campaign':
      return Icons.campaign_rounded;
    case 'description':
      return Icons.description_rounded;
    case 'local_cafe':
      return Icons.local_cafe_rounded;
    case 'label':
      return Icons.label_rounded;
    case 'inventory_2':
      return Icons.inventory_2_rounded;
    case 'menu_book':
      return Icons.menu_book_rounded;
    case 'approval':
      return Icons.approval_rounded;
    case 'photo_camera':
      return Icons.photo_camera_rounded;
    case 'umbrella':
      return Icons.umbrella_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    default:
      return Icons.category_rounded;
  }
}
