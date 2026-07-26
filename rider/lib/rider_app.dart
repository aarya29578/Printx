import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_route_guard.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/models/order_model.dart';
import 'features/auth/auth_cubit.dart';
import 'features/auth/login/login_screen.dart';
import 'features/auth/register/register_screen.dart';
import 'features/home/home_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/rider/deliveries_screen.dart';
import 'features/rider/delivery_detail_screen.dart';
import 'features/rider/history_screen.dart';
import 'features/splash/splash_screen.dart';
import 'services/firestore_service.dart';

// ─── Router ───────────────────────────────────────────────────────────────────

final _rootNavKey = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

final riderRouter = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/splash',
  redirect: AuthRouteGuard.redirect,
  routes: [
    // ── Splash ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),

    // ── Onboarding ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),

    // ── Auth ─────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/auth/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/register',
      builder: (_, __) => const RegisterScreen(),
    ),

    // ── Main Shell (4-tab nav) ────────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _shellNavKey,
      builder: (context, state, child) => RiderShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/deliveries',
          builder: (_, __) => const DeliveriesScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (_, __) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
        ),
      ],
    ),

    // ── Delivery Detail (full-screen, outside shell) ──────────────────────────
    GoRoute(
      path: '/delivery/:orderId',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        // Pass a minimal Order as initialOrder; the StreamBuilder inside will
        // immediately replace it with live Firestore data.
        return StreamBuilder<Order>(
          stream: FirestoreService.watchOrderById(orderId: orderId),
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return DeliveryDetailScreen(initialOrder: snap.data!);
          },
        );
      },
    ),

    // ── Notifications (full-screen) ───────────────────────────────────────────
    GoRoute(
      path: '/notifications',
      parentNavigatorKey: _rootNavKey,
      builder: (_, __) => const NotificationsScreen(),
    ),
  ],
);

// ─── Shell ────────────────────────────────────────────────────────────────────

class RiderShell extends StatelessWidget {
  final Widget child;
  const RiderShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).matchedLocation;

    final selectedIndex = switch (location) {
      String l when l.startsWith('/home') => 0,
      String l when l.startsWith('/deliveries') => 1,
      String l when l.startsWith('/history') => 2,
      String l when l.startsWith('/profile') => 3,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => switch (i) {
          0 => context.go('/home'),
          1 => context.go('/deliveries'),
          2 => context.go('/history'),
          _ => context.go('/profile'),
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping_rounded),
            label: 'Deliveries',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Root App ─────────────────────────────────────────────────────────────────

class RiderApp extends StatelessWidget {
  const RiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'PrintX Rider',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          routerConfig: riderRouter,
        );
      },
    );
  }
}
