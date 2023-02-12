import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';

class UserDetails extends StatelessWidget {
  const UserDetails({Key? key}) : super(key: key);
  // final currentUser = AuthService.firebase().currentUser;
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
        )
      ]),
    );
  }
}
