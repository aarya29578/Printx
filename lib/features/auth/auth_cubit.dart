import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/storage_service.dart';

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
    final next =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(next);
    StorageService.setThemeMode(
        next == ThemeMode.light ? 'light' : 'dark');
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

  void _checkAuth() {
    if (StorageService.isLoggedIn) {
      emit(const AuthAuthenticated(
        userId: 'u_mock',
        name: 'Rahul Kumar',
        email: 'rahul@example.com',
        phone: '+91 98765 43210',
      ));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));
    // Mock: always succeeds
    await StorageService.saveAuthToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');
    emit(const AuthAuthenticated(
      userId: 'u_mock',
      name: 'Rahul Kumar',
      email: 'rahul@example.com',
      phone: '+91 98765 43210',
    ));
  }

  Future<void> register(
      String name, String email, String phone, String password) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));
    emit(AuthOtpSent(phone));
  }

  Future<void> verifyOtp(String otp) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    await StorageService.saveAuthToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');
    emit(const AuthAuthenticated(
      userId: 'u_mock',
      name: 'Rahul Kumar',
      email: 'rahul@example.com',
      phone: '+91 98765 43210',
    ));
  }

  Future<void> logout() async {
    await StorageService.logout();
    emit(AuthUnauthenticated());
  }
}
