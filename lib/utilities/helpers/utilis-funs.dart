import 'dart:async';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
