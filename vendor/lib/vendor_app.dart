import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/auth_cubit.dart';
import 'data/models/category_model.dart';

import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/register/register_screen.dart';
import 'features/auth/otp/otp_screen.dart';
import 'features/home/home_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/products/product_listing_screen.dart';
import 'features/products/product_detail_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/search/search_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/orders/order_details_screen.dart';
import 'features/orders/order_tracking_screen.dart';
import 'features/vendor/add_product_screen.dart';
import 'features/vendor/my_products_screen.dart';
import 'features/vendor/vendor_order_detail_screen.dart';
import 'features/vendor/vendor_orders_screen.dart';
import 'core/auth/auth_route_guard.dart';
import 'services/firestore_service.dart';
import 'data/models/order_model.dart';

// ─── Vendor Shell ─────────────────────────────────────────────────────────────

class VendorShell extends StatefulWidget {
  final Widget child;
  const VendorShell({super.key, required this.child});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  int _currentIndex = 0;

  static const _routes = [
    '/home',
    '/vendor/my-products',
    '/vendor/add-product',
    '/vendor/orders',
    '/profile',
  ];

  void _onTabTap(int i) {
    setState(() => _currentIndex = i);
    context.go(_routes[i]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _VendorBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

class _VendorBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _VendorBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _tab(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _tab(1, Icons.inventory_2_outlined, Icons.inventory_2_rounded,
                  'Products'),
              _addProductTab(),
              _tab(2, Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded, 'Orders',
                  navIndex: 3),
              _tab(3, Icons.person_outline_rounded, Icons.person_rounded,
                  'Profile',
                  navIndex: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int displaySlot, IconData icon, IconData activeIcon, String label,
      {int? navIndex}) {
    final idx = navIndex ?? displaySlot;
    final isActive = currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color:
                    isActive ? AppColors.primary.withValues(alpha: 0.12) : null,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addProductTab() {
    final isActive = currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 36,
              decoration: BoxDecoration(
                gradient: isActive
                    ? AppColors.gradientPrimary
                    : const LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 9,
                color: isActive ? AppColors.primary : AppColors.textMuted,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Router ───────────────────────────────────────────────────────────────────

Page<dynamic> _fadeSlide(
    BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

final _vendorRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (c, s) => _fadeSlide(c, s, const SplashScreen()),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (c, s) => _fadeSlide(c, s, const OnboardingScreen()),
      redirect: AuthRouteGuard.redirect,
    ),
    GoRoute(
      path: '/auth/register',
      pageBuilder: (c, s) => _fadeSlide(c, s, const RegisterScreen()),
      redirect: AuthRouteGuard.redirect,
    ),
    GoRoute(
      path: '/auth/login',
      pageBuilder: (c, s) => _fadeSlide(c, s, const LoginScreen()),
      redirect: AuthRouteGuard.redirect,
    ),
    GoRoute(
      path: '/auth/otp',
      pageBuilder: (c, s) {
        final phone = s.uri.queryParameters['phone'] ?? '';
        return _fadeSlide(c, s, OTPScreen(phone: phone));
      },
    ),

    // ── Vendor shell (bottom nav) ─────────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => VendorShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (c, s) => _fadeSlide(c, s, const HomeScreen()),
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (c, s) => _fadeSlide(c, s, const CategoriesScreen()),
        ),
        GoRoute(
          path: '/vendor/my-products',
          redirect: AuthRouteGuard.redirect,
          pageBuilder: (c, s) =>
              _fadeSlide(c, s, const MyProductsScreen()),
        ),
        GoRoute(
          path: '/vendor/add-product',
          redirect: AuthRouteGuard.redirect,
          pageBuilder: (c, s) =>
              _fadeSlide(c, s, const AddProductScreen()),
        ),
        GoRoute(
          path: '/vendor/orders',
          redirect: AuthRouteGuard.redirect,
          pageBuilder: (c, s) =>
              _fadeSlide(c, s, const VendorOrdersScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (c, s) => _fadeSlide(c, s, const ProfileScreen()),
        ),
        GoRoute(
          path: '/profile/edit-profile',
          redirect: AuthRouteGuard.redirect,
          pageBuilder: (c, s) =>
              _fadeSlide(c, s, const EditProfileScreen()),
        ),
      ],
    ),

    // ── Vendor full-screen routes (no shell) ─────────────────────────────
    GoRoute(
      path: '/vendor/order/:orderId',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) {
        final orderId = s.pathParameters['orderId'] ?? '';
        return _fadeSlide(
          c,
          s,
          StreamBuilder<Order>(
            stream: FirestoreService.watchOrderById(orderId: orderId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError || !snap.hasData) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Order Details')),
                  body: const Center(child: Text('Order not found')),
                );
              }
              return VendorOrderDetailScreen(order: snap.data!);
            },
          ),
        );
      },
    ),
    GoRoute(
      path: '/vendor/edit-product/:productId',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) {
        final productId = s.pathParameters['productId'] ?? '';
        return _fadeSlide(c, s, AddProductScreen(productId: productId));
      },
    ),

    // ── Full-screen routes (no shell) ─────────────────────────────────────
    GoRoute(
      path: '/products/:categoryId',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) {
        final catId = s.pathParameters['categoryId'] ?? '';
        final category = Category(
          id: catId,
          name: catId,
          icon: 'tag',
          productCount: 0,
          colorIndex: 0,
          imageUrl: '',
          description: '',
        );
        return _fadeSlide(c, s, ProductListingScreen(category: category));
      },
    ),
    GoRoute(
      path: '/product/:productId',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) {
        final pid = s.pathParameters['productId'] ?? '';
        return _fadeSlide(c, s, ProductDetailScreen(productId: pid));
      },
    ),
    GoRoute(
      path: '/search',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) => _fadeSlide(c, s, const SearchScreen()),
    ),
    GoRoute(
      path: '/notifications',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) =>
          _fadeSlide(c, s, const NotificationsScreen()),
    ),
    GoRoute(
      path: '/order/:orderId/details',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) {
        final orderId = s.pathParameters['orderId'] ?? '';
        return _fadeSlide(
          c,
          s,
          StreamBuilder<Order>(
            stream: FirestoreService.watchOrderById(orderId: orderId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError || !snap.hasData) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Order Details')),
                  body: const Center(child: Text('Order not found')),
                );
              }
              return OrderDetailsScreen(order: snap.data!);
            },
          ),
        );
      },
    ),
    GoRoute(
      path: '/order/:orderId/track',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) {
        final orderId = s.pathParameters['orderId'] ?? '';
        return _fadeSlide(
          c,
          s,
          StreamBuilder<Order>(
            stream: FirestoreService.watchOrderById(orderId: orderId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError || !snap.hasData) {
                return Scaffold(
                  appBar: AppBar(title: const Text('Order Tracking')),
                  body: const Center(child: Text('Order not found')),
                );
              }
              return OrderTrackingScreen(order: snap.data!);
            },
          ),
        );
      },
    ),
  ],
);

// ─── App ──────────────────────────────────────────────────────────────────────

class PrintXVendorApp extends StatelessWidget {
  const PrintXVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'PrintX Vendor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: _vendorRouter,
        );
      },
    );
  }
}
