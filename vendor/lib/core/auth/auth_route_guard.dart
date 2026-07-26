import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthRouteGuard {
  AuthRouteGuard._();

  static bool isLoggedIn() => FirebaseAuth.instance.currentUser != null;

  /// Redirect unauthenticated users to login.
  ///
  /// Must be used as `redirect:` on GoRoute/GoRouter.
  static String? redirect(BuildContext context, GoRouterState state) {
    final loggedIn = isLoggedIn();

    final goingToLogin = state.matchedLocation.startsWith('/auth/login') ||
        state.matchedLocation.startsWith('/auth/register') ||
        state.matchedLocation.startsWith('/auth/otp');

    // If not logged in, block protected areas.
    if (!loggedIn) {
      final isProtected = state.matchedLocation.startsWith('/home') ||
          state.matchedLocation.startsWith('/categories') ||
          state.matchedLocation.startsWith('/product/') ||
          state.matchedLocation.startsWith('/products/') ||
          state.matchedLocation.startsWith('/cart') ||
          state.matchedLocation.startsWith('/orders') ||
          state.matchedLocation.startsWith('/profile') ||
          state.matchedLocation.startsWith('/order/');

      if (isProtected) {
        return '/auth/login';
      }
    }

    // If logged in, keep auth pages away.
    if (loggedIn && goingToLogin) {
      return '/home';
    }

    return null;
  }
}
