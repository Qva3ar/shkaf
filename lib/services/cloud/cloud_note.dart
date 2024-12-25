import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

@immutable
class CloudNote {
  final String documentId;
  final String ownerUserId;
  final String text;
  final String desc;
  final int price;
  final int views;
  int? categoryId;
  int? mainCategoryId;
  int? cityId;
  String? phone;
  String? url;
  String? telegramId;
  bool isFavorite;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? imagesUrls;
  final List<String>? reports;
  final bool shortAdd;

  CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
    required this.desc,
    required this.price,
    required this.views,
    this.categoryId,
    this.mainCategoryId,
    this.cityId,
    this.phone,
    this.imagesUrls,
    this.url,
    this.isFavorite = false,
    this.telegramId,
    this.reports,
    this.updatedAt,
    required this.createdAt,
    required this.shortAdd,
  });

  static String removePrefix(String input) {
    return input.replaceFirst('notes/', '');
  }

  factory CloudNote.fromHit(Map<String, dynamic> hit) {
    var note = CloudNote(
      documentId: removePrefix(hit['path']) ?? '',
      ownerUserId: hit['user_id'] ?? '',
      text: hit['text'] ?? '',
      desc: hit['desc'] ?? '',
      price: hit['price'] ?? 0,
      views: hit['views'] ?? 0,
      categoryId: hit['category_id'],
      mainCategoryId: hit['main_category_id'],
      cityId: hit['city_id'],
      phone: hit['phone'],
      url: hit['url'],
      isFavorite: hit['isFavorite'] ?? false,
      telegramId: hit['telegramId'],
      imagesUrls: (hit['imageUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      reports:
          (hit['reports'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      updatedAt: hit['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(hit['updated_at'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(hit['created_at']),
      shortAdd: hit['short_add'] ?? false,
    );
    return note;
  }

  CloudNote copyWith({
    String? documentId,
    String? ownerUserId,
    String? text,
    String? desc,
    int? price,
    int? views,
    int? categoryId,
    int? mainCategoryId,
    int? cityId,
    String? phone,
    String? url,
    String? telegramId,
    List<String>? imagesUrls,
    List<String>? reports,
    DateTime? updatedAt,
    DateTime? createdAt,
    bool? shortAdd,
    bool? isFavorite,
  }) {
    return CloudNote(
      documentId: documentId ?? this.documentId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      text: text ?? this.text,
      desc: desc ?? this.desc,
      price: price ?? this.price,
      views: views ?? this.views,
      categoryId: categoryId ?? this.categoryId,
      mainCategoryId: mainCategoryId ?? this.mainCategoryId,
      cityId: cityId ?? this.cityId,
      phone: phone ?? this.phone,
      url: url ?? this.url,
      telegramId: telegramId ?? this.telegramId,
      imagesUrls: imagesUrls ?? this.imagesUrls,
      reports: reports ?? this.reports,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      shortAdd: shortAdd ?? this.shortAdd,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

String formatUpdatedAt(DateTime? updatedAt) {
  if (updatedAt == null) return "No Date";
  return DateFormat('dd.MM.yyyy').format(updatedAt);
}
