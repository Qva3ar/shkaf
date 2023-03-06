import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/firebase_auth_provider.dart';

import '../../services/auth/bloc/auth_bloc.dart';
import '../../services/auth/bloc/auth_event.dart';

class UserDetails extends StatelessWidget {
  UserDetails({Key? key}) : super(key: key);
  final currentUser = AuthService.firebase().currentUser;
  final provider = FirebaseAuthProvider();
  deleteAcc(context) {
    provider.deleteUser();
    Navigator.popAndPushNamed(context, allNotes);
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
              onPressed: () {
                deleteAcc(context);
                // Navigator.of(context).pop();
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
                onPressed: () {
                  _showPlatformDialog(context);
                },
                child: const Text('Удалить аккаунт')),
          ),
        )
      ]),
    );
  }
}
