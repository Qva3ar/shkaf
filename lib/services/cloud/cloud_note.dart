import 'dart:developer';
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
  int? categoryId;
  int? mainCategoryId;
  int? cityId;
  String? phone;
  String? url;
  final DateTime createdAt;
  final List<String>? imagesUrls;
  CloudNote({
    required this.documentId,
    required this.ownerUserId,
    required this.text,
    required this.desc,
    required this.price,
    this.categoryId,
    this.mainCategoryId,
    this.cityId,
    this.phone,
    this.imagesUrls,
    required this.createdAt,
  });

  CloudNote.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : documentId = snapshot.id,
        ownerUserId = snapshot.data()[ownerUserIdFieldName],
        text = snapshot.data()[textFieldName] as String,
        desc = snapshot.data()[descFieldName] ?? '',
        phone = snapshot.data()[phoneFieldName] ?? '',
        url = snapshot.data()[urlFieldName] ?? '',
        price = snapshot.data()[priceFieldName] ?? 0,
        categoryId = snapshot.data()[categoryIdFieldName] ?? 0,
        mainCategoryId = snapshot.data()[mainCategoryIdFieldName] ?? 0,
        cityId = snapshot.data()[cityIdFieldName] ?? 0,
        createdAt =
            Jiffy((snapshot.data()[createdAtFieldName] as Timestamp).toDate())
                .dateTime,
        imagesUrls = snapshot.data()['imageUrls'] != null
            ? (snapshot.data()['imageUrls'] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
            : [];
}
