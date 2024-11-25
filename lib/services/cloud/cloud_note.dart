import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
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
    this.telegramId,
    this.reports,
    this.updatedAt,
    required this.createdAt,
    required this.shortAdd,
  });

  CloudNote.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  )   : documentId = snapshot.id,
        ownerUserId = snapshot.data()[ownerUserIdFieldName],
        text = snapshot.data()[textFieldName] as String,
        desc = snapshot.data()[descFieldName] ?? '',
        phone = snapshot.data()[phoneFieldName] ?? '',
        url = snapshot.data()[urlFieldName] ?? '',
        telegramId = snapshot.data()[telegramIdFieldName] ?? '',
        price = snapshot.data()[priceFieldName] ?? 0,
        shortAdd = snapshot.data()[shortAddFieldName] ?? false,
        categoryId = snapshot.data()[categoryIdFieldName] ?? 0,
        mainCategoryId = snapshot.data()[mainCategoryIdFieldName] ?? 0,
        cityId = snapshot.data()[cityIdFieldName] ?? 0,
        views = snapshot.data()[viewsFieldName] ?? 0,
        createdAt =
            Jiffy.parseFromDateTime((snapshot.data()[createdAtFieldName] as Timestamp).toDate())
                .dateTime,
        updatedAt = snapshot.data()[updatedAtFieldName] != null
            ? Jiffy.parseFromDateTime((snapshot.data()[updatedAtFieldName] as Timestamp).toDate())
                .dateTime
            : null,
        imagesUrls = snapshot.data()['imageUrls'] != null
            ? (snapshot.data()['imageUrls'] as List<dynamic>).map((e) => e.toString()).toList()
            : [],
        reports = snapshot.data()['reports'] != null
            ? (snapshot.data()['reports'] as List<dynamic>).map((e) => e.toString()).toList()
            : [];

  factory CloudNote.fromHit(Map<String, dynamic> hit) {
    var note = CloudNote(
      documentId: hit['objectID'] ?? '',
      ownerUserId: hit['user_id'] ?? '',
      text: hit['text'] ?? '',
      desc: hit['desc'] ?? '',
      price: hit['price'] ?? 0,
      views: hit['views'] ?? 0,
      categoryId: hit['category_id'],
      mainCategoryId: hit['main_ategory_id'],
      cityId: hit['city_id'],
      phone: hit['phone'],
      url: hit['url'],
      telegramId: hit['telegramId'],
      imagesUrls: (hit['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      reports: (hit['reports'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      updatedAt:
          hit['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(hit['updated_at']) : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(hit['created_at']),
      shortAdd: hit['short_add'] ?? false,
    );
    return note;
  }
}

String formatUpdatedAt(DateTime? updatedAt) {
  if (updatedAt == null) return "No Date";
  return DateFormat('dd.MM.yyyy').format(updatedAt);
}
