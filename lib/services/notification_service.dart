import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  // Создаём Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Firebase Messaging instance
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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

    // Запрос разрешения на уведомления
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // Обработка входящих уведомлений
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
        );

        // Передаём уведомление через callback
        onNotification(notification);
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
