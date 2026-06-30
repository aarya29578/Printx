import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/storage_service.dart';
import 'auth_repository.dart';

// ─── Theme ───────────────────────────────────────────────────────────────────

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(_loadInitial());

  static ThemeMode _loadInitial() {
    final saved = StorageService.themeMode;
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void toggle() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(next);
    StorageService.setThemeMode(next == ThemeMode.light ? 'light' : 'dark');
  }

  void setMode(ThemeMode mode) {
    emit(mode);
    StorageService.setThemeMode(mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system');
  }
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String name;
  final String email;
  final String phone;

  const AuthAuthenticated({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  List<Object?> get props => [userId];
}

class AuthUnauthenticated extends AuthState {}

// Kept for existing OTP screen compatibility. Registration via email/password
// bypasses OTP (no AuthOtpSent emitted).
class AuthOtpSent extends AuthState {
  final String phone;
  const AuthOtpSent(this.phone);
  @override
  List<Object?> get props => [phone];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = AuthRepository.currentUser;
    if (user == null) {
      emit(AuthUnauthenticated());
      return;
    }

    emit(AuthLoading());

    final uid = user.uid;
    final doc = await AuthRepository.fetchUserDocument(uid: uid);
    if (doc == null) {
      // Auth is valid but profile doc missing.
      emit(AuthError('User profile not found. Please try again.'));
      emit(AuthUnauthenticated());
      return;
    }

    emit(AuthAuthenticated(
      userId: uid,
      name: (doc['fullName'] as String?) ?? '',
      email: (doc['email'] as String?) ?? user.email ?? '',
      phone: (doc['phoneNumber'] as String?) ?? '',
    ));
  }

  Future<void> login(String email, String password) async {
    if (state is AuthLoading) return;

    emit(AuthLoading());
    try {
      final credential = await AuthRepository.loginWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        emit(const AuthError('Login failed. Please try again.'));
        emit(AuthUnauthenticated());
        return;
      }

      final doc = await AuthRepository.fetchUserDocument(uid: uid);
      if (doc == null) {
        emit(AuthError('User profile not found. Please try again.'));
        emit(AuthUnauthenticated());
        return;
      }

      emit(AuthAuthenticated(
        userId: uid,
        name: (doc['fullName'] as String?) ?? '',
        email: (doc['email'] as String?) ?? credential.user?.email ?? '',
        phone: (doc['phoneNumber'] as String?) ?? '',
      ));
    } on FirebaseAuthException catch (e) {
      final code = e.code;
      if (code == 'user-not-found') {
        emit(const AuthError('No account found with this email.'));
      } else if (code == 'wrong-password') {
        emit(const AuthError('Incorrect password.'));
      } else if (code == 'invalid-email') {
        emit(const AuthError('Enter a valid email address.'));
      } else {
        emit(AuthError(e.message ?? 'Login failed. Please try again.'));
      }
      emit(AuthUnauthenticated());
    } catch (_) {
      emit(const AuthError('Network error. Please try again.'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> register(
    String name,
    String email,
    String phone,
    String password, {
    String? address,
  }) async {
    if (state is AuthLoading) return;

    emit(AuthLoading());
    try {
      final credential = await AuthRepository.registerWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        emit(const AuthError('Sign up failed. Please try again.'));
        emit(AuthUnauthenticated());
        return;
      }

      await AuthRepository.createUserDocument(
        uid: uid,
        fullName: name,
        email: email,
        phoneNumber: phone,
        address: address,
      );

      final doc = await AuthRepository.fetchUserDocument(uid: uid);
      if (doc == null) {
        emit(AuthError('User profile not found. Please try again.'));
        emit(AuthUnauthenticated());
        return;
      }

      emit(AuthAuthenticated(
        userId: uid,
        name: (doc['fullName'] as String?) ?? name,
        email: (doc['email'] as String?) ?? email,
        phone: (doc['phoneNumber'] as String?) ?? phone,
      ));
    } on FirebaseAuthException catch (e) {
      final code = e.code;
      if (code == 'email-already-in-use') {
        // If the account exists, behave like login so the user still lands on Home.
        final credential = await AuthRepository.loginWithEmailAndPassword(
          email: email,
          password: password,
        );

        final uid = credential.user?.uid;
        if (uid == null) {
          emit(const AuthError(
              'Account exists but login failed. Please try again.'));
          emit(AuthUnauthenticated());
          return;
        }

        final doc = await AuthRepository.fetchUserDocument(uid: uid);
        if (doc == null) {
          // Profile missing: create it using the supplied registration fields.
          await AuthRepository.createUserDocument(
            uid: uid,
            fullName: name,
            email: email,
            phoneNumber: phone,
            address: address,
          );
        }

        final updatedDoc = await AuthRepository.fetchUserDocument(uid: uid);
        if (updatedDoc == null) {
          emit(const AuthError('User profile not found. Please try again.'));
          emit(AuthUnauthenticated());
          return;
        }

        emit(AuthAuthenticated(
          userId: uid,
          name: (updatedDoc['fullName'] as String?) ?? name,
          email: (updatedDoc['email'] as String?) ?? email,
          phone: (updatedDoc['phoneNumber'] as String?) ?? phone,
        ));
      } else if (code == 'invalid-email') {
        emit(const AuthError('Enter a valid email address.'));
        emit(AuthUnauthenticated());
      } else if (code == 'weak-password') {
        emit(const AuthError('Password is too weak.'));
        emit(AuthUnauthenticated());
      } else {
        emit(AuthError(e.message ?? 'Sign up failed. Please try again.'));
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthError('Network error. Please try again.'));
      emit(AuthUnauthenticated());
    }
  }

  // Existing OTP screen compatibility. Registration via email/password bypasses OTP.
  Future<void> verifyOtp(String otp) async {
    emit(AuthLoading());
    emit(const AuthError(
        'OTP verification is not supported for email/password registration.'));
    emit(AuthUnauthenticated());
  }

  Future<void> logout() async {
    // 1) Sign out from FirebaseAuth
    try {
      await AuthRepository.logout();
    } catch (_) {
      // Ignore signOut errors; still clear local flags.
    }

    // 2) Clear any local auth state
    await StorageService.logout();

    // 3) Clear user/profile caches (no-op if not used)
    // If you add cache keys later, clear them here.

    // 4) Ensure cubit is unauthenticated immediately
    emit(AuthUnauthenticated());
  }
}
