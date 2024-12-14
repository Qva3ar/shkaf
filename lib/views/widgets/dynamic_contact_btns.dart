import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DynamicContactButtons extends StatelessWidget {
  final String? telegramId;
  final String? phoneNumber;
  final String? link;

  const DynamicContactButtons({
    Key? key,
    this.telegramId,
    this.phoneNumber,
    this.link,
  }) : super(key: key);

  // Метод для открытия ссылки
  Future<void> openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // Метод для открытия Telegram
  Future<void> openTelegram(String telegramId) async {
    final String url = 'https://t.me/$telegramId';
    await openUrl(url);
  }

  // Метод для звонка
  Future<void> callPhone(String phoneNumber) async {
    final String telUrl = 'tel:$phoneNumber';
    await openUrl(telUrl);
  }

  @override
  Widget build(BuildContext context) {
    // Список доступных контактов
    final List<Map<String, dynamic>> contacts = [];

    if (telegramId != '' && telegramId != null) {
      contacts.add({
        'icon': Icons.telegram,
        'color': Colors.blue,
        'action': () => openTelegram(telegramId!),
        'label': 'Telegram',
      });
    }

    if (phoneNumber != '' && phoneNumber != null) {
      contacts.add({
        'icon': Icons.phone,
        'color': Colors.green,
        'action': () => callPhone(phoneNumber!),
        'label': 'Call',
      });
    }

    if (link != '' && link != null) {
      contacts.add({
        'icon': Icons.link,
        'color': Colors.orange,
        'action': () => openUrl(link!),
        'label': 'Link',
      });
    }

    return Container(
      color: AppColors.purple,
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: contacts.length == 1
              ? [
                  // Растянутая кнопка с текстом
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: contacts[0]['action'],
                        icon: Icon(contacts[0]['icon'], color: contacts[0]['color']),

                        // style: ElevatedButton.styleFrom(
                        //   padding: const EdgeInsets.symmetric(vertical: 12.0),
                        // ),
                      ),
                      Text(contacts[0]['label'])
                    ],
                  ),
                ]
              : contacts.map((contact) {
                  // Кнопки с иконками
                  return IconButton(
                    onPressed: contact['action'],
                    icon: Icon(contact['icon'], color: contact['color']),
                    iconSize: 32.0,
                  );
                }).toList(),
        ),
      ),
    );
  }
}
