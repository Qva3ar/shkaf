import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/helpers/loading/loading_screen.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/services/auth/firebase_auth_provider.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/forgot_password_view.dart';
import 'package:mynotes/views/login_view.dart';
import 'package:mynotes/views/notes/update_note_view.dart';
import 'package:mynotes/views/notes/note_details.dart';
import 'package:mynotes/views/notes/notes_all.dart';
import 'package:mynotes/views/notes/notes_list_view.dart';
import 'package:mynotes/views/notes/user_notes_view.dart';
import 'package:mynotes/views/register_view.dart';
import 'package:mynotes/views/user/user_details.dart';
import 'package:mynotes/views/verify_email_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'views/notes/create_note_view.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp firebase = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: Colors.white,
          appBarTheme: AppBarTheme(
              backgroundColor: Colors.white, foregroundColor: Colors.black),
          bottomSheetTheme:
              BottomSheetThemeData(backgroundColor: Colors.black54)),
      home: firebase != null
          ? BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(FirebaseAuthProvider()),
              child: const HomePage(),
            )
          : Container(),
      // home: const NotesAll(),
      routes: {
        createNoteRoute: (context) => const UpdateNoteView(),
        updateNoteRoute: (context) => const UpdateNoteView(),
        login: (context) => BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(FirebaseAuthProvider()),
              child: const LoginView(),
            ),
        allNotes: (context) => BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(FirebaseAuthProvider()),
              child: const NotesAll(),
            ),
        noteDetailsRoute: (context) => BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(FirebaseAuthProvider()),
              child: const NoteDetailsView(),
            ),
        userDetails: (context) => BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(FirebaseAuthProvider()),
              child: UserDetails(),
            ),
        userNotes: (context) => BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(FirebaseAuthProvider()),
              child: const UserNotesView(),
            ),
        register: (context) => BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(FirebaseAuthProvider()),
              child: const RegisterView(),
            ),
        forgotPassword: (context) => BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(FirebaseAuthProvider()),
              child: const ForgotPasswordView(),
            ),
        emailVerification: (context) => BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(FirebaseAuthProvider()),
              child: const VerifyEmailView(),
            ),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<AuthBloc>().add(const AuthEventInitialize());
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isLoading) {
          LoadingScreen().show(
            context: context,
            text: state.loadingText ?? 'Please wait a moment',
          );
        } else {
          LoadingScreen().hide();
        }
      },
      builder: (context, state) {
        if (state is AuthStateLoggedIn) {
          return const NotesAll();
        } else if (state is AuthStateNeedsVerification) {
          return const VerifyEmailView();
        } else if (state is AuthStateLoggedOut) {
          return NotesAll();
        } else if (state is AuthStateForgotPassword) {
          return const ForgotPasswordView();
        } else if (state is AuthStateRegistering) {
          return const RegisterView();
        } else if (state is AuthStateLogin) {
          return const LoginView();
        } else {
          return const Scaffold(
            body: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class Palette {
  static const MaterialColor kToDark = MaterialColor(
    0xffe55f48, // 0% comes in here, this will be color picked if no shade is selected when defining a Color property which doesn’t require a swatch.
    <int, Color>{
      50: const Color(0xffce5641), //10%
      100: const Color(0xffb74c3a), //20%
      200: const Color(0xffa04332), //30%
      300: const Color(0xff89392b), //40%
      400: const Color(0xff733024), //50%
      500: const Color(0xff5c261d), //60%
      600: const Color(0xff451c16), //70%
      700: const Color(0xff2e130e), //80%
      800: const Color(0xff170907), //90%
      900: const Color(0xff000000), //100%
    },
  );
}
