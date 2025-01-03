import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Firebase Messaging instance
  late final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Инициализация уведомлений
  Future<void> initialize(Function(PushNotification) onNotification) async {
    // Регистрация фонового обработчика
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Получение токена устройства
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print('Firebase token: $token');
        // sendTokenToServer(token); // Отправка токена на сервер
      }
    } catch (e) {
      print('Error getting Firebase token: $e');
    }

    // Подписка на обновление токена
    _messaging.onTokenRefresh.listen((newToken) {
      print('Firebase token refreshed: $newToken');
      // sendTokenToServer(newToken); // Отправьте обновлённый токен
    });

    // Запрос разрешений
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Обработка входящих уведомлений в foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
        );

        print('Foreground notification received: ${notification.title}');
        onNotification(notification);
      });

      // Обработка нажатия на уведомление
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.notification != null) {
          print('Notification clicked: ${message.notification!.title}');
          PushNotification notification = PushNotification(
            title: message.notification?.title,
            body: message.notification?.body,
          );
          onNotification(notification);
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // Фоновый обработчик уведомлений
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }
}

// Модель уведомления
class PushNotification {
  final String? title;
  final String? body;

  PushNotification({this.title, this.body});
}
