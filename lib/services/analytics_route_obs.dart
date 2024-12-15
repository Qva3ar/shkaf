import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseEvent {
  static sendAppOpenEvent() async {
    await FirebaseAnalytics.instance.logAppOpen();
  }

  static logScreenView(String name) async {
    await FirebaseAnalytics.instance.logScreenView(screenName: name);
  }
}
