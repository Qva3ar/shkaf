import 'package:flutter/material.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';

import '../constants/routes.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({Key? key}) : super(key: key);

  @override
  _VerifyEmailViewState createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.verify_email),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                // We've sent you an email verification. Please open it to verify your account.
                // If you haven't received a verification email yet, press the button below!'
                "Вам на почту было выслано верификационное сообщение. Пожалуйста, откройте его и подтвердите верификацию. Если вы не получили сообщение, нажмите кнопку 'Отправить еще раз'",
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                // We've sent you an email verification. Please open it to verify your account.
                // If you haven't received a verification email yet, press the button below!'
                "После подверждения акаунта, перейдите на страницу авторизации и залогиньтесь.",
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(
                      const AuthEventSendEmailVerification(),
                    );
              },
              child: Text(
                "Отправить еще раз",
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                context.read<AuthBloc>().add(
                      const AuthEventLogOut(),
                    );
                Navigator.pushReplacementNamed(context, login);
              },
              child: Text(
                "На страницу авторизации",
              ),
            )
          ],
        ),
      ),
    );
  }
}
