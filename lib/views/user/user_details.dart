import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/firebase_auth_provider.dart';

import '../../services/auth/bloc/auth_bloc.dart';
import '../../services/auth/bloc/auth_event.dart';

class UserDetails extends StatefulWidget {
  UserDetails({Key? key}) : super(key: key);

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  final currentUser = AuthService.firebase().currentUser;

  final provider = FirebaseAuthProvider();

  Future<bool> deleteAcc(context) async {
    return await provider.deleteUser().then((value) => Future.value(true));
  }

  Future<void> _showPlatformDialog(contextt) async {
    return showDialog<void>(
      context: contextt,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Вы уверены что хотите удалить свой аккаунт?'),
          content: GestureDetector(
            onTap: () {},
            child: Container(),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Удалить'),
              onPressed: () async {
                var result = await deleteAcc(context);
                Navigator.pop(contextt, result);
              },
            ),
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Мой профиль"),
      ),
      body: Column(children: [
        // Text(currentUser.email.toString(), style: TextStyle(fontSize: 20, fontWeight: ),),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(userNotes);
                },
                child: const Text('Мои объявления')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Background color
                ),
                onPressed: () {
                  _showPlatformDialog(context).then((value) {
                    context.read<AuthBloc>().add(const AuthEventLogOut());
                    Navigator.pushReplacementNamed(context, allNotes);
                  });
                },
                child: const Text('Удалить аккаунт')),
          ),
        )
      ]),
    );
  }
}
