import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/auth_cubit.dart';
import 'data/models/category_model.dart';

// ─── Router ───────────────────────────────────────────────────────────────────

import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/register/register_screen.dart';
import 'features/auth/otp/otp_screen.dart';
import 'features/home/home_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/products/product_listing_screen.dart';
import 'features/products/product_detail_screen.dart';
import 'features/design_editor/design_editor_screen.dart';
import 'features/design_editor/design_preview_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/checkout/checkout_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/orders/order_tracking_screen.dart';
import 'features/orders/order_details_screen.dart';

import 'features/my_designs/my_designs_screen.dart';
import 'data/models/order_model.dart';

import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/edit_profile_screen.dart' as profile_edit;
import 'features/profile/saved_addresses_screen.dart';
import 'core/auth/auth_route_guard.dart';
import 'features/search/search_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'data/mock_data/mock_categories.dart';
import 'data/models/order_model.dart';
import 'services/firestore_service.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _routes = [
    '/home',
    '/categories',
    '/designs',
    '/orders',
    '/profile'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          context.go(_routes[i]);
        },
      ),
    );
  }
}

class _AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppBottomNavBar({required this.currentIndex, required this.onTap});

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
            color: Colors.black.withOpacity(0.08),
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
              _tab(1, Icons.grid_view_outlined, Icons.grid_view_rounded,
                  'Categories'),
              _centerTab(),
              _tab(3, Icons.receipt_long_outlined, Icons.receipt_long_rounded,
                  'Orders'),
              _tab(4, Icons.person_outline_rounded, Icons.person_rounded,
                  'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int idx, IconData icon, IconData activeIcon, String label) {
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
              // Avoid overshoot curves here; they can interpolate to negative padding.
              curve: Curves.easeOutCubic,
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                  : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withOpacity(0.12) : null,
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
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerTab() {
    final isActive = currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(2),
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isActive ? Icons.palette_rounded : Icons.palette_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── App ──────────────────────────────────────────────────────────────────────

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

final _router = GoRouter(
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
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
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
          path: '/designs',
          pageBuilder: (c, s) => _fadeSlide(c, s, const MyDesignsScreen()),
          redirect: AuthRouteGuard.redirect,
        ),
        GoRoute(
          path: '/orders',
          pageBuilder: (c, s) => _fadeSlide(c, s, const OrdersScreen()),
          redirect: AuthRouteGuard.redirect,
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (c, s) => _fadeSlide(c, s, const ProfileScreen()),
        ),
        GoRoute(
          path: '/profile/edit-profile',
          redirect: AuthRouteGuard.redirect,
          pageBuilder: (c, s) => _fadeSlide(c, s, const EditProfileScreen()),
        ),
        GoRoute(
          path: '/profile/saved-addresses',
          redirect: AuthRouteGuard.redirect,
          pageBuilder: (c, s) => _fadeSlide(
            c,
            s,
            const SavedAddressesScreen(),
          ),
        ),
        GoRoute(
          path: '/profile/saved-addresses/add',
          redirect: AuthRouteGuard.redirect,
          pageBuilder: (c, s) => _fadeSlide(
            c,
            s,
            const AddSavedAddressScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/products/:categoryId',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) {
        final catId = s.pathParameters['categoryId'] ?? '';
        print('🔍 [ROUTE] Category clicked: categoryId=$catId');
        // Create a minimal category object; ProductListingScreen will load full details from Firestore
        final category = Category(
          id: catId,
          name: catId, // Will be updated when Firestore data loads
          icon: 'tag',
          productCount: 0,
          colorIndex: 0,
          imageUrl: '',
          description: '',
        );
        print(
            '  ↓ Passing to ProductListingScreen: category.id=${category.id}');
        return _fadeSlide(
          c,
          s,
          ProductListingScreen(category: category),
        );
      },
    ),
    GoRoute(
      path: '/product/:productId',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) {
        final pid = s.pathParameters['productId'] ?? '';
        return _fadeSlide(
          c,
          s,
          ProductDetailScreen(productId: pid),
        );
      },
    ),
    GoRoute(
      path: '/editor',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) => _fadeSlide(c, s, const DesignEditorScreen()),
    ),
    GoRoute(
      path: '/preview',
      pageBuilder: (c, s) => _fadeSlide(c, s, const DesignPreviewScreen()),
    ),
    GoRoute(
      path: '/cart',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) => _fadeSlide(c, s, const CartScreen()),
    ),
    GoRoute(
      path: '/checkout',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) => _fadeSlide(c, s, const CheckoutScreen()),
    ),
    GoRoute(
      path: '/order/:orderId/details',
      pageBuilder: (c, s) {
        final orderId = s.pathParameters['orderId'] ?? '';

        return _fadeSlide(
          c,
          s,
          FutureBuilder<Order>(
            future: FirestoreService.fetchOrderById(orderId: orderId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snap.hasData) {
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
      pageBuilder: (c, s) {
        // Use the order document id (orderId) to load the real order.
        final orderId = s.pathParameters['orderId'] ?? '';

        print('ROUTER ENTER orderId=$orderId route=/order/:orderId/track');

        return _fadeSlide(
          c,
          s,
          FutureBuilder<Order>(
            future: FirestoreService.fetchOrderById(orderId: orderId),
            builder: (context, snap) {
              print(
                  'FUTUREBUILDER connectionState=${snap.connectionState} hasData=${snap.hasData} hasError=${snap.hasError} error=${snap.error}');
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snap.hasData) {
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
    GoRoute(
      path: '/search',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) => _fadeSlide(c, s, const SearchScreen()),
    ),
    GoRoute(
      path: '/notifications',
      redirect: AuthRouteGuard.redirect,
      pageBuilder: (c, s) => _fadeSlide(c, s, const NotificationsScreen()),
    ),
  ],
);

class PrintXApp extends StatelessWidget {
  const PrintXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'PrintX',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
