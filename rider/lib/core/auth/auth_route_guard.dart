import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthRouteGuard {
  AuthRouteGuard._();

  static bool isLoggedIn() => FirebaseAuth.instance.currentUser != null;

  static String? redirect(BuildContext context, GoRouterState state) {
    final loggedIn = isLoggedIn();

    if (!loggedIn) {
      final isProtected = state.matchedLocation.startsWith('/home') ||
          state.matchedLocation.startsWith('/deliveries') ||
          state.matchedLocation.startsWith('/history') ||
          state.matchedLocation.startsWith('/profile') ||
          state.matchedLocation.startsWith('/delivery/');

      if (isProtected) return '/auth/login';
    }

    if (loggedIn && state.matchedLocation.startsWith('/auth/')) return '/home';

    return null;
  }
}
