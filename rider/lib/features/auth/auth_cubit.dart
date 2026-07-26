import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/storage_service.dart';
import 'auth_repository.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(_loadInitial());

  static ThemeMode _loadInitial() {
    final saved = StorageService.themeMode;
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void toggle() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(next);
    StorageService.setThemeMode(next == ThemeMode.light ? 'light' : 'dark');
  }

  void setMode(ThemeMode mode) {
    emit(mode);
    StorageService.setThemeMode(switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
  }
}

// ─── Auth States ──────────────────────────────────────────────────────────────

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

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Auth Cubit ───────────────────────────────────────────────────────────────

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

    final doc = await AuthRepository.fetchUserDocument(uid: user.uid);
    if (doc == null) {
      emit(const AuthError('User profile not found. Please try again.'));
      emit(AuthUnauthenticated());
      return;
    }

    // Rider-only gate: role must be 'rider'
    final role = (doc['role'] as String?) ?? '';
    if (role != 'rider') {
      await AuthRepository.logout();
      await StorageService.logout();
      emit(const AuthError('You are not registered as a Rider. Please contact admin.'));
      emit(AuthUnauthenticated());
      return;
    }

    emit(AuthAuthenticated(
      userId: user.uid,
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
        emit(const AuthError('User profile not found. Please try again.'));
        emit(AuthUnauthenticated());
        return;
      }

      // Rider-only gate
      final role = (doc['role'] as String?) ?? '';
      if (role != 'rider') {
        await AuthRepository.logout();
        emit(const AuthError(
            'You are not registered as a Rider. Please contact admin.'));
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
      final msg = switch (e.code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-email' => 'Enter a valid email address.',
        _ => e.message ?? 'Login failed. Please try again.',
      };
      emit(AuthError(msg));
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
    String password,
  ) async {
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
      );

      final doc = await AuthRepository.fetchUserDocument(uid: uid);
      if (doc == null) {
        emit(const AuthError('Profile creation failed. Please try again.'));
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
      final msg = switch (e.code) {
        'email-already-in-use' => 'An account with this email already exists.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' => 'Password is too weak. Use at least 6 characters.',
        _ => e.message ?? 'Sign up failed. Please try again.',
      };
      emit(AuthError(msg));
      emit(AuthUnauthenticated());
    } catch (_) {
      emit(const AuthError('Network error. Please try again.'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> logout() async {
    try {
      await AuthRepository.logout();
    } catch (_) {}
    await StorageService.logout();
    emit(AuthUnauthenticated());
  }
}
