import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:rxdart/subjects.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_state.dart';
import 'dart:async';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static AuthService firebase() => _instance;

  // Контроллер для потока состояния аутентификации
  final BehaviorSubject<AuthState> _authStateController = BehaviorSubject<AuthState>();

  // Поток состояния аутентификации
  Stream<AuthState> get authState => _authStateController.stream;

  // Инициализация состояния аутентификации
  void initialize() {
    _updateState(
      AuthState(
        status: _firebaseAuth.currentUser != null ? AuthStatus.loggedIn : AuthStatus.loggedOut,
        user: _firebaseAuth.currentUser != null
            ? AuthUser.fromFirebase(_firebaseAuth.currentUser!)
            : null,
      ),
    );

    // Подписка на изменения состояния пользователя
    _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        _updateState(
          AuthState(
            status: AuthStatus.loggedIn,
            user: AuthUser.fromFirebase(user),
          ),
        );
      } else {
        _updateState(AuthState(status: AuthStatus.loggedOut));
      }
    });
  }

  void _updateState(AuthState state) {
    _authStateController.add(state);
  }

  // Текущий пользователь
  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _updateState(AuthState(status: AuthStatus.loggedOut));
  }

  Future<void> loginWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _updateState(AuthState(
        status: AuthStatus.loggedIn,
        user: AuthUser.fromFirebase(userCredential.user!),
      ));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Пользователь не найден');
      } else if (e.code == 'wrong-password') {
        throw Exception('Неправильный пароль');
      } else {
        throw Exception('Ошибка авторизации: ${e.message}');
      }
    }
  }

  Future<void> registerWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _updateState(AuthState(
        status: AuthStatus.loggedIn,
        user: AuthUser.fromFirebase(userCredential.user!),
      ));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email уже используется');
      } else {
        throw Exception('Ошибка регистрации: ${e.message}');
      }
    }
  }

  Future<void> signInWithApple() async {
    final rawNonce = Utils.generateNonce();
    final nonce = Utils.sha256OfString(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: credential.identityToken,
      rawNonce: rawNonce,
    );

    await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  // Метод для сброса пароля
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Не удалось отправить письмо для сброса пароля');
    }
  }

  Future<void> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    }
  }

  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.delete();
        _updateState(AuthState(status: AuthStatus.loggedOut));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw Exception('Необходимо заново войти в аккаунт перед удалением.');
        } else {
          throw Exception('Ошибка при удалении аккаунта: ${e.message}');
        }
      }
    } else {
      throw Exception('Пользователь не найден.');
    }
  }
}
