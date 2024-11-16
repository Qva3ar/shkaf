import 'package:firebase_auth/firebase_auth.dart';
import 'package:mynotes/services/auth/auth_user.dart';

abstract class AuthProviderService {
  Future<void> initialize();
  AuthUser? get currentUser;
  Stream<User?>? get auth;
  Future<AuthUser> logIn({
    required String email,
    required String password,
  });
  Future<AuthUser> createUser({
    required String email,
    required String password,
  });
  Future<void> deleteUser();
  Future<void> logOut();
  Future<void> sendEmailVerification();
  Future<void> sendPasswordReset({required String toEmail});
}
