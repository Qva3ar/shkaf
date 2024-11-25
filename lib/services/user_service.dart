import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  // Singleton instance
  static final UserService _instance = UserService._internal();

  // Factory constructor
  factory UserService() {
    return _instance;
  }

  // Private constructor
  UserService._internal() {
    _init();
  }

  // FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user
  User? currentUser;

  // Stream for auth state changes
  late final Stream<User?> authStateChanges;

  // Initialization logic
  void _init() {
    authStateChanges = _auth.authStateChanges();
    authStateChanges.listen((User? user) {
      currentUser = user;
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
      }
    });
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      currentUser = credential.user;
      return currentUser;
    } catch (e) {
      print('Sign-in error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    currentUser = null;
  }

  // Register new user
  Future<User?> register(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      currentUser = credential.user;
      return currentUser;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(displayName);
      await currentUser!.updatePhotoURL(photoURL);
      await currentUser!.reload();
      currentUser = _auth.currentUser;
    }
  }
}
