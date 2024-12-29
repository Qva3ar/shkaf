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
      await showErrorDialog(context, 'Ошибка входа через Google: ${e.toString()}');
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
      await showErrorDialog(context, 'Ошибка входа через Apple: ${e.toString()}');
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
