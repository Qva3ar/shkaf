import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:flutter/material.dart';
import 'package:mynotes/views/auth/widgets/email_text_field_widget.dart';
import 'package:mynotes/views/auth/widgets/password_text_field_widget.dart';

import 'package:mynotes/constants/app_colors.dart';

class LoginView extends StatefulWidget {
  LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  final GlobalKey<FormState> _formKey = GlobalKey();
  bool _isLoading = false;
  bool shouldShowAppleIdAuth = false;
  bool isFromDetails = false;

  @override
  void initState() {
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    super.initState();

    isAuthWithAppleIdAvailable();
  }

  isAuthWithAppleIdAvailable() async {
    if (Platform.isIOS && await SignInWithApple.isAvailable()) {
      setState(() {
        shouldShowAppleIdAuth = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('isFromDetailsView')) {
      final isFromDetailsView = args['isFromDetailsView'] as bool?;
      // Логика обработки параметра
      print('isFromDetailsView: $isFromDetailsView');
      isFromDetails = isFromDetailsView ?? false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().loginWithEmailAndPassword(email, password);
      // Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      if (isFromDetails) {
        Navigator.pop(context);
      }
    } catch (e) {
      await showErrorDialog(context, 'Ошибка авторизации: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().signInWithGoogle();
      // Navigator.pop(context);
      if (isFromDetails) {
        Navigator.pop(context);
      }
    } catch (e) {
      await showErrorDialog(
          context, 'Ошибка входа через Google: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().signInWithApple();
      if (isFromDetails) {
        Navigator.pop(context);
      }
      // Navigator.of(context).pushNamedAndRemoveUntil(allNotes, (route) => false);
    } catch (e) {
      await showErrorDialog(
          context, 'Ошибка входа через Apple: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Авторизация",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // const SizedBox(height: 35),
                // Align(
                //   alignment: Alignment.topRight,
                //   child: GestureDetector(
                //     onTap: () => Navigator.pop(context),
                //     child: const Icon(Icons.arrow_back, color: Colors.black),
                //   ),
                // ),
                const SizedBox(height: 19),
                emailTextField(_emailController),
                const SizedBox(height: 10),
                passwordTextField(_passwordController, 'Введите пароль'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, forgotPassword),
                  child: const Text(
                    'Забыли пароль?',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Войдите с помощью"),
                    GestureDetector(
                      onTap: _isLoading ? null : _signInWithGoogle,
                      child: Image.asset(
                        'assets/icons/google_icon.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginWithEmailAndPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Войти',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 8),
                shouldShowAppleIdAuth
                    ? SignInWithAppleButton(
                        height: 55,
                        text: "Войти с помощью Apple",
                        onPressed: _signInWithApple,
                      )
                    : Container(),
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, register),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Зарегистрироваться',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'Регистрируясь на сервисе "Shkaf.in", вы принимаете ',
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: 'Пользовательское соглашение.',
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            openUrl('https://shkaf.in');
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class LoginView extends StatefulWidget {
//   const LoginView({Key? key}) : super(key: key);

//   @override
//   State<LoginView> createState() => _LoginViewState();
// }

// // GoogleSignIn _googleSignIn = GoogleSignIn(
// //   // Optional clientId
// //   // clientId: '656609494072-qdf0tupf8b0l9jr150e91r2v9qasb5v9.apps.googleusercontent.com',
// //   scopes: <String>[
// //     'email',
// //     'https://www.googleapis.com/auth/contacts.readonly',
// //   ],
// // );

// class _LoginViewState extends State<LoginView> {
//   late final TextEditingController _email;
//   late final TextEditingController _password;
//   // GoogleSignInAccount? _currentUser;

//   String welcome = "Login with Google";
//   final GoogleSignIn googleSignIn = GoogleSignIn();
//   GoogleSignInAccount? googleUser;

//   @override
//   void initState() {
//     _email = TextEditingController();
//     _password = TextEditingController();
//     // _handleSignIn();
//     // _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
//     //   setState(() {
//     //     _currentUser = account;
//     //   });
//     //   if (_currentUser != null) {
//     //     log(_currentUser.toString());
//     //     // _handleGetContact(_currentUser!);
//     //   }
//     // });
//     // _googleSignIn.signInSilently();
//     FirebaseEvent.logScreenView('login');
//     super.initState();

//     googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
//       setState(() {
//         googleUser = account;
//       });

//       if (googleUser != null) {
//         // Perform your action
//       }
//       googleSignIn.signInSilently();
//     });
//   }

//   // Future<void> _handleSignIn() async {
//   //   try {
//   //     await _googleSignIn.signIn();
//   //   } catch (error) {
//   //     print(error);
//   //   }
//   // }

//   Future<UserCredential> signInGoogle() async {
//     GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

//     setState(() {
//       welcome = googleUser!.email;
//     });

//     final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

//     final credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );

//     return await FirebaseAuth.instance.signInWithCredential(credential);
//   }

//   @override
//   void dispose() {
//     _email.dispose();
//     _password.dispose();
//     super.dispose();
//   }

//   String sha256ofString(String input) {
//     final bytes = utf8.encode(input);
//     final digest = sha256.convert(bytes);
//     return digest.toString();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthBloc, AuthState>(
//       listener: (context, state) async {
//         if (state is AuthStateLoggedIn) {
//           Navigator.of(context).pushNamedAndRemoveUntil(allNotes, (Route<dynamic> route) => false);
//         }
//         if (state is AuthStateNeedsVerification) {
//           await showErrorDialog(context,
//               "Завершите регистрацию перейдя по ссылке в письме которое мы отправили вам на почту");
//         }
//         if (state is AuthStateRegistering) {
//           Navigator.of(context).pushReplacementNamed(register);
//         }
//         if (state is AuthStateLoggedOut) {
//           if (state.exception is UserNotFoundAuthException) {
//             await showErrorDialog(
//               context,
//               "Пользователь не найден",
//             );
//           } else if (state.exception is WrongPasswordAuthException) {
//             await showErrorDialog(
//               context,
//               "Неправильный email или пароль",
//             );
//           } else if (state.exception is GenericAuthException) {
//             await showErrorDialog(
//               context,
//               context.loc.login_error_auth_error,
//             );
//           }
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text("Вход"),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.max,
//               children: [
//                 const Text("Введите ваши данные что бы иметь возможность создавать объявления"),
//                 TextField(
//                   controller: _email,
//                   enableSuggestions: false,
//                   autocorrect: false,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: const InputDecoration(
//                     hintText: "Введите email",
//                   ),
//                 ),
//                 TextField(
//                   controller: _password,
//                   obscureText: true,
//                   enableSuggestions: false,
//                   autocorrect: false,
//                   decoration: const InputDecoration(
//                     hintText: "Введите пароль",
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 SizedBox(
//                   height: 40,
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       final email = _email.text.trim();
//                       final password = _password.text;
//                       context.read<AuthBloc>().add(
//                             AuthEventLogIn(email, password, null),
//                           );
//                     },
//                     child: const Text("Войти"),
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 50,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                         child: (Image.asset(
//                       'assets/icons/google_icon.png',
//                       width: 32,
//                       height: 32,
//                     ))),
//                     TextButton(
//                         onPressed: () {
//                           signInGoogle().then((user) {
//                             context.read<AuthBloc>().add(
//                                   AuthEventLogIn(null, null, user),
//                                 );
//                           });
//                         },
//                         child: const Text(
//                           "Войти с помощью Google",
//                         )),
//                   ],
//                 ),
//                 SignInWithAppleButton(
//                     text: "Войти с помощью Apple",
//                     onPressed: () async {
//                       final rawNonce = generateNonce();
//                       final nonce = sha256ofString(rawNonce);
//                       final credential = await SignInWithApple.getAppleIDCredential(
//                         scopes: [
//                           AppleIDAuthorizationScopes.email,
//                           AppleIDAuthorizationScopes.fullName,
//                         ],

//                         // TODO: Remove these if you have no need for them
//                         nonce: nonce,
//                         state: 'example-state',
//                       );

//                       final oauthCredential = OAuthProvider("apple.com").credential(
//                         idToken: credential.identityToken,
//                         rawNonce: rawNonce,
//                       );

//                       final authResult =
//                           await FirebaseAuth.instance.signInWithCredential(oauthCredential);
//                       if (authResult.user != null) {
//                         context.read<AuthBloc>().add(
//                               AuthEventLogIn(null, null, authResult),
//                             );
//                       }
//                     }),
//                 TextButton(
//                   onPressed: () {
//                     // context.read<AuthBloc>().add(
//                     //       const AuthEventForgotPassword(),
//                     //     );
//                     Navigator.pushNamed(context, forgotPassword);
//                   },
//                   child: const Text(
//                     "Забыл пароль",
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     // context.read<AuthBloc>().add(
//                     //       const AuthEventShouldRegister(),
//                     //     );
//                     Navigator.pushNamed(context, register);
//                   },
//                   child: const Text(
//                     "Еще не зарегистрированы? Зарегистрируйтесь здесь!",
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 RichText(
//                   text: TextSpan(
//                     text: 'Регистрируясь на сервисе "Shkaf.in" вы принимаете ',
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 14,
//                       fontWeight: FontWeight.normal,
//                     ),
//                     children: <TextSpan>[
//                       TextSpan(
//                         text:
//                             'Пользовательское соглашение и соглашаетесь на обработку ваших персональных данных в соответствии с ним.',
//                         recognizer: TapGestureRecognizer()
//                           ..onTap = () => openUrl('https://shkaf.in'),
//                         style: const TextStyle(
//                             fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
//                       ),
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
