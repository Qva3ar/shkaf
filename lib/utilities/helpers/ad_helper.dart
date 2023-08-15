import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3060459956824180/5924353247';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3060459956824180/2107670810';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3060459956824180/1177732527';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3060459956824180/9355605441';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
