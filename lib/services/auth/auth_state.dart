import 'package:flutter/foundation.dart' show immutable;
import 'package:mynotes/services/auth/auth_user.dart';

@immutable
class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? loadingText;
  final Exception? exception;
  final AuthUser? user;

  const AuthState({
    required this.status,
    this.isLoading = false,
    this.loadingText,
    this.exception,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? loadingText,
    Exception? exception,
    AuthUser? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      loadingText: loadingText ?? this.loadingText,
      exception: exception ?? this.exception,
      user: user ?? this.user,
    );
  }
}

enum AuthStatus {
  uninitialized,
  registering,
  forgotPassword,
  loggedIn,
  needsVerification,
  loggedOut,
  login,
}
