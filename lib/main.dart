import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/analytics_route_obs.dart';
import 'package:mynotes/services/auth/auth_state.dart';
import 'package:mynotes/services/shared_preferences_service.dart';
import 'package:mynotes/utilities/widgets/custom_bottom_navigation_bar.dart';
import 'package:mynotes/views/auth/forgot_password_view.dart';
import 'package:mynotes/views/auth/login_view.dart';
import 'package:mynotes/views/auth/register_view.dart';
import 'package:mynotes/views/auth/verify_email_view.dart';
import 'package:mynotes/views/notes/update_note_view.dart';
import 'package:mynotes/views/notes/notes_all.dart';
import 'package:mynotes/views/notes/user_notes_view.dart';
import 'package:mynotes/views/user/user_details.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'firebase_options.dart';

import 'services/auth/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await SharedPreferencesService().init();

  FirebaseApp firebase = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    // Для iOS используйте AppAttestProvider или DeviceCheckProvider
    appleProvider: AppleProvider.appAttest,
  );
  final authService = AuthService().initialize();

  NotificationService().initialize((PushNotification notification) {
    print('Notification received: ${notification.title}');
  });

  MobileAds.instance.initialize();
  // final UserService userService = UserService();

  // if (Platform.isIOS) {
  //check for ios if developing for both android & ios
  // await SignInWithApple.isAvailable();
  // SignInWithApple.
  // }

  // final fcmToken = await FirebaseMessaging.instance.getToken();
  // FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
  //   // TODO: If necessary send token to application server.

  //   // Note: This callback is fired at each app startup and whenever a new
  //   // token is generated.
  // }).onError((err) {
  //   // Error getting token.
  // });

  FirebaseEvent.logScreenView('main');
  if (!kIsWeb && Platform.isAndroid) {
    InAppUpdate.checkForUpdate().then((updateInfo) {
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          // Perform immediate update
          InAppUpdate.performImmediateUpdate().then((appUpdateResult) {
            if (appUpdateResult == AppUpdateResult.success) {
              //App Update successful
            }
          });
        } else if (updateInfo.flexibleUpdateAllowed) {
          //Perform flexible update
          InAppUpdate.startFlexibleUpdate().then((appUpdateResult) {
            if (appUpdateResult == AppUpdateResult.success) {
              //App Update successful
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
  }, appRunner: () {
    runApp(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.white,
          fontFamily: 'Montserrat',
          appBarTheme:
              const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 104, 136, 164),
              foregroundColor: Colors.white,
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.black54),
        ),
        home: const HomePage(),
        routes: {
          createNoteRoute: (context) => const UpdateNoteView(),
          updateNoteRoute: (context) => const UpdateNoteView(),
          login: (context) => const LoginView(),
          allNotes: (context) => const NotesAll(),
          userDetails: (context) => const UserDetails(),
          userNotes: (context) => UserNotesView(),
          register: (context) => const RegisterView(),
          forgotPassword: (context) => const ForgotPasswordView(),
          emailVerification: (context) => const VerifyEmailView(),
        },
      ),
    );
  });
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 1;
  String? _redirectRoute;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService().authState,
      builder: (context, snapshot) {
        final state = snapshot.data;

        if (state == null || state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Если пользователь разлогинился, просто сбрасываем вкладку на главную
        if (state.status == AuthStatus.loggedOut) {
          // Можно вызвать setState, чтобы вернуть currentIndex на нужную вкладку
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                currentIndex = 1; // например, главная вкладка
              });
            }
          });
        }

        if (state.status == AuthStatus.loggedIn && _redirectRoute != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(_redirectRoute!);
            _redirectRoute = null;
          });
        }

        return Scaffold(
          body: _getBody(state),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => _onTabSelected(index, state),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: "Избранные"),
              BottomNavigationBarItem(icon: Icon(Icons.apps), label: "Главная"),
              BottomNavigationBarItem(icon: Icon(Icons.add), label: "Добавить"),
            ],
          ),
        );
      },
    );
  }

  Widget _getBody(AuthState? state) {
    // Здесь вы сами решаете, какие экраны показывать при loggedIn/loggedOut
    switch (currentIndex) {
      case 0:
        return UserNotesView();
      case 1:
        return const NotesAll();
      case 2:
        if (state?.status == AuthStatus.loggedIn) {
          return const Placeholder();
        } else {
          return const LoginView();
        }
      default:
        return const NotesAll();
    }
  }

  void _onTabSelected(int index, AuthState? state) {
    if (index == 2) {
      if (state?.status == AuthStatus.loggedIn) {
        Navigator.of(context).pushNamed(createNoteRoute);
      } else {
        _redirectRoute = createNoteRoute;
        setState(() {
          currentIndex = 2;
        });
      }
    } else {
      setState(() {
        currentIndex = index;
      });
    }
  }
}

class Palette {
  static const MaterialColor kToDark = MaterialColor(
    0xffe55f48, // 0% comes in here, this will be color picked if no shade is selected when defining a Color property which doesn’t require a swatch.
    <int, Color>{
      50: Color(0xffce5641), //10%
      100: Color(0xffb74c3a), //20%
      200: Color(0xffa04332), //30%
      300: Color(0xff89392b), //40%
      400: Color(0xff733024), //50%
      500: Color(0xff5c261d), //60%
      600: Color(0xff451c16), //70%
      700: Color(0xff2e130e), //80%
      800: Color(0xff170907), //90%
      900: Color(0xff000000), //100%
    },
  );
}
