import 'package:cloud_firestore/cloud_firestore.dart';
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
            Jiffy((snapshot.data()[createdAtFieldName] as Timestamp).toDate())
                .dateTime,
        updatedAt = snapshot.data()[updatedAtFieldName] != null
            ? Jiffy((snapshot.data()[updatedAtFieldName] as Timestamp).toDate())
                .dateTime
            : null,
        imagesUrls = snapshot.data()['imageUrls'] != null
            ? (snapshot.data()['imageUrls'] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
            : [],
        reports = snapshot.data()['reports'] != null
            ? (snapshot.data()['reports'] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
            : [];
}
