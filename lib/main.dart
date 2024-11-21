import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/helpers/loading/loading_screen.dart';
import 'package:mynotes/services/analytics_route_obs.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/services/auth/firebase_auth_provider.dart';
import 'package:mynotes/views/forgot_password_view.dart';
import 'package:mynotes/views/login_view.dart';
import 'package:mynotes/views/notes/update_note_view.dart';
import 'package:mynotes/views/notes/note_details.dart';
import 'package:mynotes/views/notes/notes_all.dart';
import 'package:mynotes/views/notes/user_notes_view.dart';
import 'package:mynotes/views/register_view.dart';
import 'package:mynotes/views/user/user_details.dart';
import 'package:mynotes/views/verify_email_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:in_app_update/in_app_update.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:upgrader/upgrader.dart';

// Import the SearchBarWidget
import 'package:mynotes/views/notes/search_bar.dart';


void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp firebase = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  MobileAds.instance.initialize();

  FirebaseEvent.logScreenView('main');
  if (!kIsWeb && Platform.isAndroid) {
    InAppUpdate.checkForUpdate().then((updateInfo) {
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          InAppUpdate.performImmediateUpdate().then((appUpdateResult) {
            if (appUpdateResult == AppUpdateResult.success) {
              // App Update successful
            }
          });
        } else if (updateInfo.flexibleUpdateAllowed) {
          InAppUpdate.startFlexibleUpdate().then((appUpdateResult) {
            if (appUpdateResult == AppUpdateResult.success) {
              InAppUpdate.completeFlexibleUpdate();
            }
          });
        }
      }
    });
  }

  await SentryFlutter.init((options) {
    options.dsn =
        'https://0c73491e5beb4ed086eca37c648a3183@o4504716753174528.ingest.sentry.io/4504716754092032';
    options.tracesSampleRate = 1.0;
  },
      appRunner: () => runApp(
            MaterialApp(
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              title: 'Flutter Demo',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                  primaryColor: Colors.white,
                  appBarTheme: const AppBarTheme(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 104, 136, 164),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  bottomSheetTheme: const BottomSheetThemeData(
                      backgroundColor: Colors.black54)),
              home: firebase != null
                  ? BlocProvider<AuthBloc>(
                      create: (context) => AuthBloc(FirebaseAuthProvider()),
                      child: UpgradeAlert(
                        upgrader:
                            Upgrader(dialogStyle: UpgradeDialogStyle.cupertino),
                        child: const HomePage(),
                      ),
                    )
                  : Container(),
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
                      child: const UserDetails(),
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
          ));
}

class NotesAll extends StatelessWidget {
  const NotesAll({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notes'),
      ),
      body: Column(
        children: [
          // Add the SearchBarWidget here
          SearchBarWidget(
            searchcb: (searchText) {
              print("Search text: $searchText");
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 20, // Replace with actual note count
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Note $index'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
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
          return const NotesAll();
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
