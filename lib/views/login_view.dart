import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

// GoogleSignIn _googleSignIn = GoogleSignIn(
//   // Optional clientId
//   // clientId: '656609494072-qdf0tupf8b0l9jr150e91r2v9qasb5v9.apps.googleusercontent.com',
//   scopes: <String>[
//     'email',
//     'https://www.googleapis.com/auth/contacts.readonly',
//   ],
// );

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  // GoogleSignInAccount? _currentUser;

  String welcome = "Login with Google";
  final GoogleSignIn googleSignIn = GoogleSignIn();
  GoogleSignInAccount? googleUser;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    // _handleSignIn();
    // _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
    //   setState(() {
    //     _currentUser = account;
    //   });
    //   if (_currentUser != null) {
    //     log(_currentUser.toString());
    //     // _handleGetContact(_currentUser!);
    //   }
    // });
    // _googleSignIn.signInSilently();

    super.initState();

    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        googleUser = account;
      });

      if (googleUser != null) {
        // Perform your action
      }
      googleSignIn.signInSilently();
    });
  }

  // Future<void> _handleSignIn() async {
  //   try {
  //     await _googleSignIn.signIn();
  //   } catch (error) {
  //     print(error);
  //   }
  // }

  Future<UserCredential> signInGoogle() async {
    GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    setState(() {
      welcome = googleUser!.email;
    });

    final GoogleSignInAuthentication? googleAuth =
        await googleUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateLoggedIn) {
          Navigator.of(context).pushNamedAndRemoveUntil(
              allNotes, (Route<dynamic> route) => false);
        }
        if (state is AuthStateNeedsVerification) {
          await showErrorDialog(context,
              "Завершите регистрацию перейдя по ссылке в письме которое мы отправили вам на почту");
        }
        if (state is AuthStateRegistering) {
          Navigator.of(context).pushReplacementNamed(register);
        }
        if (state is AuthStateLoggedOut) {
          if (state.exception is UserNotFoundAuthException) {
            await showErrorDialog(
              context,
              "Пользователь не найден",
            );
          } else if (state.exception is WrongPasswordAuthException) {
            await showErrorDialog(
              context,
              "Неправильный email или пароль",
            );
          } else if (state.exception is GenericAuthException) {
            await showErrorDialog(
              context,
              context.loc.login_error_auth_error,
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Вход"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                    "Введите ваши данные что бы иметь возможность создавать объявления"),
                TextField(
                  controller: _email,
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: "Введите email",
                  ),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: "Введите пароль",
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () async {
                    final email = _email.text.trim();
                    final password = _password.text;
                    context.read<AuthBloc>().add(
                          AuthEventLogIn(email, password, null),
                        );
                  },
                  child: const Text("Войти"),
                ),
                TextButton(
                    onPressed: () {
                      signInGoogle().then((user) {
                        context.read<AuthBloc>().add(
                              AuthEventLogIn(null, null, user),
                            );
                      });
                    },
                    child: const Text(
                      "Войти с помощью Google",
                    )),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    // context.read<AuthBloc>().add(
                    //       const AuthEventForgotPassword(),
                    //     );
                    Navigator.pushNamed(context, forgotPassword);
                  },
                  child: const Text(
                    "Забыл пароль",
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // context.read<AuthBloc>().add(
                    //       const AuthEventShouldRegister(),
                    //     );
                    Navigator.pushNamed(context, register);
                  },
                  child: const Text(
                    "Еще не зарегистрированы? Зарегистрируйтесь здесь!",
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
