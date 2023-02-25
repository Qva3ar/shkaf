import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseEvent {
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  static sendAppOpenEvent() async {
    await FirebaseAnalytics.instance.logAppOpen();
  }

  static logScreenView(String name) async {
    await FirebaseAnalytics.instance.logScreenView(screenName: name);
  }
}
