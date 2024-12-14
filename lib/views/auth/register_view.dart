import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/views/auth/login_view.dart';
import 'package:mynotes/views/auth/widgets/email_text_field_widget.dart';
import 'package:mynotes/views/auth/widgets/password_text_field_widget.dart';

// void registerScreen(BuildContext context, GlobalKey<ScaffoldState> _scaffoldKey) {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _repeatPasswordController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey();

//   _scaffoldKey.currentState?.showBottomSheet(
//     (_) {
//       return BlocListener<AuthBloc, AuthState>(
//         listener: (context, state) async {
//           if (state is AuthStateNeedsVerification) {
//             Navigator.pushNamed(context, emailVerification);
//           }
//           if (state is AuthStateRegistering) {
//             if (state.exception is WeakPasswordAuthException) {
//               await showErrorDialog(
//                 context,
//                 context.loc.register_error_weak_password,
//               );
//             } else if (state.exception is EmailAlreadyInUseAuthException) {
//               await showErrorDialog(
//                 context,
//                 context.loc.register_error_email_already_in_use,
//               );
//             } else if (state.exception is GenericAuthException) {
//               await showErrorDialog(
//                 context,
//                 context.loc.register_error_generic,
//               );
//             } else if (state.exception is InvalidEmailAuthException) {
//               await showErrorDialog(
//                 context,
//                 context.loc.register_error_invalid_email,
//               );
//             }
//           }
//         },
//         child: Container(
//           height: MediaQuery.sizeOf(context).height - 240,
//           width: MediaQuery.sizeOf(context).width,
//           decoration: const BoxDecoration(
//             color: AppColors.white,
//             borderRadius:
//                 BorderRadius.only(topLeft: Radius.circular(47), topRight: Radius.circular(47)),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: SingleChildScrollView(
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     const SizedBox(height: 30),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           'Регистрация',
//                           style: AppTextStyles.s16w600,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 19),
//                     emailTextField(_emailController),
//                     const SizedBox(height: 10),
//                     passwordTextField(_passwordController, 'Придумайте пароль'),
//                     const SizedBox(height: 10),
//                     passwordTextField(_repeatPasswordController, 'Повторите пароль'),
//                     const SizedBox(height: 40),
//                     Container(
//                       width: MediaQuery.of(context).size.width,
//                       height: 60,
//                       child: ElevatedButton(
//                         style: ButtonStyle(
//                           backgroundColor: MaterialStateProperty.all(AppColors.violet),
//                           shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                             RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(6.0),
//                             ),
//                           ),
//                         ),
//                         onPressed: () async {
//                           if (!_formKey.currentState!.validate()) {
//                             return;
//                           }
//                           final email = _emailController.text;
//                           final password = _passwordController.text;
//                           final passwordCheck = _repeatPasswordController.text;
//                           if (password != passwordCheck) {
//                             await showErrorDialog(
//                               context,
//                               "Пароли не совпадают",
//                             );
//                             return;
//                           }

//                           context.read<AuthBloc>().add(
//                                 AuthEventRegister(
//                                   email,
//                                   password,
//                                 ),
//                               );
//                         },
//                         child: Text(
//                           'Создать аккаунт',
//                           style: AppTextStyles.s16w600.copyWith(color: AppColors.white),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         GestureDetector(
//                           onTap: () {
//                             // loginScreen(context, _scaffoldKey);
//                           },
//                           child: const Text(
//                             'Уже зарегистрированы? Войдите здесь',
//                             style: AppTextStyles.s12w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 30),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//     //elevation: 0,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
//     ),
//   );
// }

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final AuthService _authService = AuthService();
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _passwordCheck;
  String? _errorMessage;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _passwordCheck = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordCheck.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _email.text;
    final password = _password.text;
    final passwordCheck = _passwordCheck.text;

    if (password != passwordCheck) {
      setState(() {
        _errorMessage = "Пароли не совпадают";
      });
      return;
    }

    try {
      // Здесь вызывается метод регистрации:
      await AuthService().registerWithEmailAndPassword(email, password);
      // Если регистрация успешна, перенаправляем на страницу подтверждения
      _sendVerificationEmail();
    } catch (e) {
      if (e is Exception) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      } else {
        setState(() {
          _errorMessage = "Произошла ошибка"; // Обработка других типов ошибок
        });
      }
    }
  }

  String _getErrorMessage(Exception e) {
    if (e is WeakPasswordAuthException) {
      return "Слабый пароль";
    } else if (e is EmailAlreadyInUseAuthException) {
      return "Email уже используется";
    } else if (e is InvalidEmailAuthException) {
      return "Неверный email";
    } else {
      return "Произошла ошибка";
    }
  }

  void _sendVerificationEmail() async {
    try {
      await _authService
          .sendEmailVerification(); // Метод для отправки верификационного письма
      Navigator.pushNamed(context, emailVerification);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(context.loc.errorSendingEmail)), // Уведомление об ошибке
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Регистрация",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 10,
              ),
              // Text(context.loc.register_view_prompt),
              // if (_errorMessage != null) ...[
              //   Text(
              //     _errorMessage!,
              //     style: TextStyle(color: Colors.red),
              //   ),
              //   const SizedBox(height: 15),
              // ],
              TextFormField(
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold),
                controller: _email,
                enableSuggestions: false,
                autocorrect: false,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  focusColor: AppColors.lightGrey,
                  hoverColor: AppColors.lightGrey,
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  contentPadding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                  ),
                  hintText: 'Введите email',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: AppColors.hintTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _password,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  focusColor: AppColors.lightGrey,
                  hoverColor: AppColors.lightGrey,
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  contentPadding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                  ),
                  hintText: 'Придумайте пароль',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: AppColors.hintTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordCheck,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  focusColor: AppColors.lightGrey,
                  hoverColor: AppColors.lightGrey,
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                  contentPadding: EdgeInsets.only(
                    left: 10,
                    right: 10,
                  ),
                  hintText: 'Повторите пароль',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: AppColors.hintTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _register();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violet,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        "Создать аккаунт",
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, login);
                      },
                      child: const Text(
                        "Уже зарегистрированы? Войдите здесь",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// class RegisterView extends StatefulWidget {
//   const RegisterView({Key? key}) : super(key: key);

//   @override
//   _RegisterViewState createState() => _RegisterViewState();
// }

// class _RegisterViewState extends State<RegisterView> {
//   late final TextEditingController _email;
//   late final TextEditingController _password;
//   late final TextEditingController _passwordCheck;

//   @override
//   void initState() {
//     _email = TextEditingController();
//     _password = TextEditingController();
//     _passwordCheck = TextEditingController();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _email.dispose();
//     _password.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthBloc, AuthState>(
//       listener: (context, state) async {
//         if (state is AuthStateNeedsVerification) {
//           Navigator.pushNamed(context, emailVerification);
//         }
//         if (state is AuthStateRegistering) {
//           if (state.exception is WeakPasswordAuthException) {
//             await showErrorDialog(
//               context,
//               context.loc.register_error_weak_password,
//             );
//           } else if (state.exception is EmailAlreadyInUseAuthException) {
//             await showErrorDialog(
//               context,
//               context.loc.register_error_email_already_in_use,
//             );
//           } else if (state.exception is GenericAuthException) {
//             await showErrorDialog(
//               context,
//               context.loc.register_error_generic,
//             );
//           } else if (state.exception is InvalidEmailAuthException) {
//             await showErrorDialog(
//               context,
//               context.loc.register_error_invalid_email,
//             );
//           }
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text("Регистрация"),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(context.loc.register_view_prompt),
//                 TextField(
//                   controller: _email,
//                   enableSuggestions: false,
//                   autocorrect: false,
//                   autofocus: true,
//                   keyboardType: TextInputType.emailAddress,
//                   decoration: const InputDecoration(
//                     hintText: "Введите email",
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 TextField(
//                   controller: _password,
//                   obscureText: true,
//                   enableSuggestions: false,
//                   autocorrect: false,
//                   decoration: const InputDecoration(
//                     hintText: "Придумайте пароль",
//                   ),
//                 ),
//                 TextField(
//                   controller: _passwordCheck,
//                   obscureText: true,
//                   enableSuggestions: false,
//                   autocorrect: false,
//                   decoration: const InputDecoration(
//                     hintText: "Повторите пароль",
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 Center(
//                   child: Column(
//                     children: [
//                       ElevatedButton(
//                         onPressed: () async {
//                           final email = _email.text;
//                           final password = _password.text;
//                           final passwordCheck = _passwordCheck.text;
//                           if (password != passwordCheck) {
//                             await showErrorDialog(
//                               context,
//                               "Пароли не совпадают",
//                             );
//                             return;
//                           }

//                           context.read<AuthBloc>().add(
//                                 AuthEventRegister(
//                                   email,
//                                   password,
//                                 ),
//                               );
//                         },
//                         child: const Text(
//                           "Создать аккаунт",
//                         ),
//                       ),
//                       const SizedBox(height: 15),
//                       TextButton(
//                         onPressed: () {
//                           context.read<AuthBloc>().add(
//                                 const AuthEventLogOut(),
//                               );
//                         },
//                         child: const Text(
//                           "Уже зарегистрированы? Войдите здесь",
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
