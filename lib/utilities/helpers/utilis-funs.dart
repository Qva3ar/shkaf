import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';

Future<String> loadJsonData(path) async {
  return await rootBundle.loadString(path);
}

openUrl(String urlString) async {
  // final suppotrUrl = Uri.parse("https://t.me/ShkafSupportTR");
  // final licenseUrl = Uri.parse(
  //     "https://docs.google.com/document/d/16w4WSDrYcIrETM5_ERO4SbSc6yxRzXMOpyCf0p_vqj8/edit");
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    // <--
    throw Exception('Could not launch $url');
  }
}

class Debounce {
  Timer? _debounceTimer;
  void debouncing({required Function() fn, int waitForMs = 500}) {
    // if this function is called before 500ms [waitForMs] expired
    //cancel the previous call
    _debounceTimer?.cancel();
    // set a 500ms [waitForMs] timer for the [fn] to be called
    _debounceTimer = Timer(Duration(milliseconds: waitForMs), fn);
  }
}

class Utils {
  static String generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String sha256OfString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static int randomInt(int max) => (max * (1 - Random().nextDouble())).toInt();

  static openSupportUrl() async {
    final suppotrUrl = Uri.parse("https://t.me/ShkafSupportTR");

    if (!await launchUrl(suppotrUrl, mode: LaunchMode.externalApplication)) {
      // <--
      throw Exception('Could not launch $suppotrUrl');
    }
  }
}
