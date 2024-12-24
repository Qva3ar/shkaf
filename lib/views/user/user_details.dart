import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:mynotes/views/notes/user_notes_view.dart';

class UserDetails extends StatefulWidget {
  const UserDetails({Key? key}) : super(key: key);

  @override
  State<UserDetails> createState() => _UserDetailsState();
}

class _UserDetailsState extends State<UserDetails> {
  final currentUser = AuthService.firebase().currentUser;

  Future<bool> deleteAccount(BuildContext context) async {
    try {
      await AuthService.firebase().deleteAccount();
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка при удалении аккаунта: ${e.toString()}')),
      );
      return false;
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Вы уверены, что хотите удалить свой аккаунт?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Удалить'),
              onPressed: () async {
                final result = await deleteAccount(context);
                Navigator.of(context).pop(result);
              },
            ),
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );

    if (shouldDelete ?? false) {
      await AuthService.firebase().logout();
      Navigator.of(context).pushNamedAndRemoveUntil(allNotes, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text("Мой профиль"),
      ),
      body: Container(
        color: const Color.fromARGB(0, 242, 242, 247),
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 30),
          const SizedBox(
              height: 200,
              width: 200,
              child: const CircleAvatar(
                  backgroundImage:
                      AssetImage('assets/images/img_placeholder.jpeg'))),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              currentUser?.email ?? '',
              style: AppTextStyles.s20w700,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            color: Colors.white,
            width: double.infinity,
            child: ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Мои объявления'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserNotesView(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            color: Colors.white,
            width: double.infinity,
            child: ListTile(
              leading: Icon(Icons.support_agent),
              title: Text('Связаться с нами'),
              trailing: Icon(Icons.create),
              onTap: () {
                Utils.openSupportUrl();
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            color: Colors.white,
            width: double.infinity,
            child: ListTile(
              leading: Icon(Icons.logout),
              title: Text('Выйти'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                AuthService().logout();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              },
            ),
          ),
          // Text(currentUser.email.toString(), style: TextStyle(fontSize: 20, fontWeight: ),),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Background color
                  ),
                  onPressed: () {
                    _showDeleteAccountDialog(context).then((value) {
                      Navigator.pushReplacementNamed(context, allNotes);
                    });
                  },
                  child: const Text('Удалить аккаунт')),
            ),
          )
        ]),
      ),
    );
  }
}
