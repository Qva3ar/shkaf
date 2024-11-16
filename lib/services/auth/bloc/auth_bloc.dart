import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProviderService provider) : super(const AuthStateUninitialized(isLoading: true)) {
    on<AuthEventShouldRegister>((event, emit) {
      emit(const AuthStateRegistering(
        exception: null,
        isLoading: false,
      ));
    });
    //forgot password
    on<AuthEventForgotPassword>((event, emit) async {
      emit(const AuthStateForgotPassword(
        exception: null,
        hasSentEmail: false,
        isLoading: false,
      ));
      final email = event.email;
      if (email == null) {
        return; // user just wants to go to forgot-password screen
      }

      // user wants to actually send a forgot-password email
      emit(const AuthStateForgotPassword(
        exception: null,
        hasSentEmail: false,
        isLoading: true,
      ));

      bool didSendEmail;
      Exception? exception;
      try {
        await provider.sendPasswordReset(toEmail: email);
        didSendEmail = true;
        exception = null;
      } on Exception catch (e) {
        didSendEmail = false;
        exception = e;
      }

      emit(AuthStateForgotPassword(
        exception: exception,
        hasSentEmail: didSendEmail,
        isLoading: false,
      ));
    });
    // send email verification
    on<AuthEventSendEmailVerification>((event, emit) async {
      await provider.sendEmailVerification();
      emit(state);
    });

    on<AuthEventGoToLogin>((event, emit) async {
      // await provider.sendEmailVerification();
      emit(const AuthStateLogin(isLogin: true));
    });
    on<AuthEventRegister>((event, emit) async {
      final email = event.email;
      final password = event.password;
      try {
        await provider.createUser(
          email: email,
          password: password,
        );
        await provider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(
          exception: e,
          isLoading: false,
        ));
      }
    });
    // initialize
    on<AuthEventInitialize>((event, emit) async {
      await provider.initialize();
      AuthUser? user = provider.currentUser;
      final prefs = await SharedPreferences.getInstance();
      var email = prefs.getString("email") ?? "";
      var password = prefs.getString("password") ?? "";

      if (provider.currentUser == null && email != "") {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          var firebaseUser = FirebaseAuth.instance.currentUser;
          if (firebaseUser != null) {
            user = AuthUser.fromFirebase(firebaseUser);
          }
          if (user != null) {
            emit(AuthStateLoggedIn(
              user: user,
              isLoading: false,
            ));
          }
        } catch (e) {
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
            isLogin: false,
          );
        }
      }

      if (user == null) {
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
            isLogin: false,
          ),
        );
      } else if (user.isEmailVerified != null && user.isEmailVerified == false) {
        emit(const AuthStateNeedsVerification(isLoading: false));
      } else {
        emit(AuthStateLoggedIn(
          user: user,
          isLoading: false,
        ));
      }
    });
    // log in
    on<AuthEventLogIn>((event, emit) async {
      emit(
        const AuthStateLoggedOut(
            exception: null,
            isLoading: true,
            loadingText: 'Please wait while I log you in',
            isLogin: false),
      );
      final email = event.email;
      final password = event.password;
      final prefs = await SharedPreferences.getInstance();
      var isGoogleSignIn = false;
      try {
        AuthUser user;
        if (event.user != null) {
          user = AuthUser.fromFirebase(event.user!.user!);
          isGoogleSignIn = true;
        } else {
          user = await provider.logIn(
            email: email!,
            password: password!,
          );
        }

        if (!isGoogleSignIn && user.isEmailVerified != null && user.isEmailVerified == false) {
          emit(
            const AuthStateLoggedOut(exception: null, isLoading: false, isLogin: false),
          );
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          emit(
            const AuthStateLoggedOut(exception: null, isLoading: false, isLogin: false),
          );
          if (event.user == null) {
            await prefs.setString('email', email!);
            await prefs.setString('password', password!);
          }

          emit(AuthStateLoggedIn(
            user: user,
            isLoading: false,
          ));
        }
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
            isLogin: false,
          ),
        );
      }
    });
    // log out
    on<AuthEventLogOut>((event, emit) async {
      try {
        await provider.logOut();
        final prefs = await SharedPreferences.getInstance();
        prefs.remove("email");
        prefs.remove("password");
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: true,
            isLogin: false,
          ),
        );
        emit(
          const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
            isLogin: false,
          ),
        );
        // emit(
        //   const AuthState(id: null, email: null, isEmailVerified: null),
        // );
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
            isLogin: false,
          ),
        );
      }
    });
  }
}
