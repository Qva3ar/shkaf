import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';

class UserDetails extends StatelessWidget {
  UserDetails({Key? key}) : super(key: key);
  // final currentUser = AuthService.firebase().currentUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Мой профиль"),
      ),
      body: Column(children: [
        // Text(currentUser.email.toString(), style: TextStyle(fontSize: 20, fontWeight: ),),
        ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(userNotes);
            },
            child: Text('Мои объявления'))
      ]),
    );
  }
}
