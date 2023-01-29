import 'package:flutter/services.dart';

Future<String> loadJsonData(path) async {
  return await rootBundle.loadString(path);
}
