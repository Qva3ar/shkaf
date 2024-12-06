import 'package:flutter/material.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';

import '../../constants/routes.dart';

import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/views/auth/login_view.dart';
import 'package:mynotes/views/auth/widgets/email_text_field_widget.dart';
import 'package:mynotes/views/auth/widgets/password_text_field_widget.dart';

void verifyEmailScreen(
    BuildContext context, GlobalKey<ScaffoldState> _scaffoldKey) {
  _scaffoldKey.currentState?.showBottomSheet(
    (contextVerifyEmail) {
      return Container(
        height: MediaQuery.sizeOf(context).height - 240,
        width: MediaQuery.sizeOf(context).width,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(47), topRight: Radius.circular(47)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.loc.verify_email,
                      style: AppTextStyles.s16w600,
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    // We've sent you an email verification. Please open it to verify your account.
                    // If you haven't received a verification email yet, press the button below!'
                    "Вам на почту было выслано верификационное сообщение. Пожалуйста, откройте его и подтвердите верификацию. Если вы не получили сообщение, нажмите кнопку 'Отправить еще раз'",
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    // We've sent you an email verification. Please open it to verify your account.
                    // If you haven't received a verification email yet, press the button below!'
                    "После подверждения акаунта, перейдите на страницу авторизации и залогиньтесь.",
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 60,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(AppColors.violet),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      context.read<AuthBloc>().add(
                            const AuthEventSendEmailVerification(),
                          );
                    },
                    child: Text(
                      'Отправить еще раз',
                      style: AppTextStyles.s16w600
                          .copyWith(color: AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        //Navigator.pop(contextVerifyEmail);
                        loginScreen(context, _scaffoldKey);
                      },
                      child: const Text(
                        'На страницу авторизациии',
                        style: AppTextStyles.s12w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      );
    },
    //elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
    ),
  );
}



/*
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                // We've sent you an email verification. Please open it to verify your account.
                // If you haven't received a verification email yet, press the button below!'
                "Вам на почту было выслано верификационное сообщение. Пожалуйста, откройте его и подтвердите верификацию. Если вы не получили сообщение, нажмите кнопку 'Отправить еще раз'",
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
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
              child: const Text(
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
              child: const Text(
                "На страницу авторизации",
              ),
            )
          ],
        ),
      ),
    );
  }
}
*/