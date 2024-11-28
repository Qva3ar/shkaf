import 'package:flutter/material.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';

Future<void> showPlatformDialog(context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Наше приложение доступно в Google Play.'),
        content: GestureDetector(
          onTap: () {
            openUrl('https://play.google.com/store/apps/details?id=com.aturdiyev.mynotes');
          },
          child: Container(
            child: (Image.asset(
              'assets/icons/googleplay.png',
              width: 150,
              height: 80,
            )),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ок'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
