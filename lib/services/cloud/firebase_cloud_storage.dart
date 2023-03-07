import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_storage_exceptions.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection('notes');

  late DocumentSnapshot<Object?> lastDoc;
  List<CloudNote> noteList = [];
  String searchStr = '';
  bool isSearching = false;
  bool isSearchingEnded = false;
  bool isCategorySet = false;

  final BehaviorSubject<List<CloudNote>> movieController =
      BehaviorSubject<List<CloudNote>>();

  BehaviorSubject<String> categoryNameForSheet =
      BehaviorSubject<String>.seeded(CATEGORIES[0]['name'].toString());

  BehaviorSubject<CloudNote?> selectedNote =
      BehaviorSubject<CloudNote?>.seeded(null);
  BehaviorSubject<int> selectedCityStream =
      BehaviorSubject<int>.seeded(TURKEY[0]['id'] as int);

  BehaviorSubject<int> categoryIdStream = BehaviorSubject<int>.seeded(0);
  BehaviorSubject<int> mainCategoryIdStream = BehaviorSubject<int>.seeded(0);

  setSelectedId(int id) {
    isCategorySet = true;
    selectedCityStream.add(id);

    allNotes(false);
  }

  setCategoryId(int id) {
    isCategorySet = true;
    categoryIdStream.add(id);
  }

  setSearchStr(String searchStringParam) {
    isSearchingEnded = false;
    if (searchStr.isNotEmpty && searchStringParam.isEmpty) {
      isSearchingEnded = true;
      isSearching = false;
    }
    if (searchStringParam.isNotEmpty) {
      isSearching = true;
    }

    searchStr = searchStringParam.toLowerCase();
  }

  setMainCategoryId(int id) {
    isCategorySet = true;
    mainCategoryIdStream.add(id);
  }

  Stream<List<CloudNote>> get movieStream =>
      movieController.stream.throttleTime(const Duration(milliseconds: 300));

  Future<void> deleteNote({required String documentId}) async {
    try {
      await notes.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteNoteException();
    }
  }

  Future<void> updateNote({
    required String documentId,
    required String text,
    required String desc,
    required int categoryId,
    required int mainCategoryId,
    required int cityId,
    required int price,
    required bool shortAdd,
    List<String>? imgUrls,
    List<String>? reports,
    String? phone,
    String? url,
  }) async {
    try {
      await notes.doc(documentId).update({
        textFieldName: text,
        textSearchFieldName: convertToArrayForSearch(text.toLowerCase()),
        descFieldName: desc,
        descSearchFieldName: desc.split(" "),
        imageUrls: imgUrls,
        urlFieldName: url,
        priceFieldName: price,
        categoryIdFieldName: categoryId,
        mainCategoryIdFieldName: mainCategoryId,
        cityIdFieldName: cityId,
        phoneFieldName: phone,
        shortAddFieldName: shortAdd,
        reportsFieldName: reports,
        updatedAtFieldName: Timestamp.now()
      });
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Stream<List<CloudNote>> allUserNotes({required String ownerUserId}) {
    var addDt = DateTime.now();
    final allNotes = notes
        // .limit(8)
        .where(ownerUserIdFieldName, isEqualTo: ownerUserId)
        .snapshots()
        .map((event) =>
            event.docs.map((doc) => CloudNote.fromSnapshot(doc)).toList());
    return allNotes;
  }

  allNotes(bool isPreload) {
    const limit = 15;
    var addDt = DateTime.now();
    Query<Map<String, dynamic>> query;
    if (mainCategoryIdStream.value == 0) {
      query = notes
          .limit(limit)
          .where(cityIdFieldName, isEqualTo: selectedCityStream.value)
          .where(createdAtFieldName,
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(addDt.subtract(const Duration(days: 30))))
          .orderBy(createdAtFieldName, descending: true);
    } else if (categoryIdStream.value == 0) {
      query = notes
          .limit(limit)
          .where(cityIdFieldName, isEqualTo: selectedCityStream.value)
          .where(mainCategoryIdFieldName, isEqualTo: mainCategoryIdStream.value)
          .where(createdAtFieldName,
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(addDt.subtract(const Duration(days: 30))))
          .orderBy(createdAtFieldName, descending: true);
    } else {
      query = notes
          .limit(limit)
          .where(cityIdFieldName, isEqualTo: selectedCityStream.value)
          .where(mainCategoryIdFieldName, isEqualTo: mainCategoryIdStream.value)
          .where(categoryIdFieldName, isEqualTo: categoryIdStream.value)
          .where(createdAtFieldName,
              isGreaterThanOrEqualTo:
                  Timestamp.fromDate(addDt.subtract(const Duration(days: 30))))
          .orderBy(createdAtFieldName, descending: true);
    }
    List<String> arr = [];

    if (searchStr != null && searchStr.isNotEmpty) {
      arr.add(searchStr);
      query = query.where(textSearchFieldName, arrayContains: searchStr);
    }

    if (isPreload) {
      query = query.startAfterDocument(lastDoc);
    }

    query.snapshots().map((event) {
      if (event.docs.isNotEmpty) {
        lastDoc = event.docs[event.docs.length - 1];
      }

      return event.docs.map((doc) => CloudNote.fromSnapshot(doc));
    }).listen((event) {
      // if (!isPreload) {
      noteList = [];
      // }

      noteList.addAll(event.toList());
      var shortAddDateRange = DateTime.now().subtract(const Duration(days: 54));
      noteList = noteList.where((record) {
        if (record.shortAdd) {
          if (record.createdAt.microsecondsSinceEpoch >
              shortAddDateRange.microsecondsSinceEpoch) {
            return true;
          } else {
            return false;
          }
        }
        return true;
      }).toList();

      movieController.sink.add(noteList);
    });
  }

  allNotesNext() {
    var addDt = DateTime.now();

    Query<Map<String, dynamic>> query = notes
        .limit(8)
        .where(cityIdFieldName, isEqualTo: selectedCityStream.value)
        .where(createdAtFieldName,
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(addDt.subtract(Duration(days: 7))));
    // if (categoryIdStream.value == 0) {
    //   query.where(mainCategoryIdFieldName,
    //       isEqualTo: mainCategoryIdStream.value);
    // } else {
    //   query.where(categoryIdFieldName, isEqualTo: categoryIdStream.value);
    // }

    query
        .orderBy(createdAtFieldName, descending: true)
        .startAfterDocument(lastDoc)
        .snapshots()
        .map((event) {
      if (event.docs.isNotEmpty) {
        lastDoc = event.docs[event.docs.length - 1];
      }

      return event.docs.map((doc) => CloudNote.fromSnapshot(doc));
    }).listen((event) {
      noteList = [];
      noteList.addAll(event.toList());
      movieController.sink.add(noteList);
    });
  }

  Future<CloudNote?> createNewNote({
    required String ownerUserId,
    required String text,
    required String desc,
    required int categoryId,
    required int mainCategoryId,
    required int cityId,
    required int price,
    required bool shortAdd,
    List<String>? imgUrls,
    String? phone,
    String? url,
  }) async {
    try {
      final document = await notes.add({
        ownerUserIdFieldName: ownerUserId,
        textFieldName: text,
        descFieldName: desc,
        imageUrls: imgUrls,
        urlFieldName: url,
        priceFieldName: price,
        mainCategoryIdFieldName: mainCategoryId,
        categoryIdFieldName: categoryId,
        cityIdFieldName: cityId,
        phoneFieldName: phone,
        createdAtFieldName: Timestamp.now(),
        shortAddFieldName: shortAdd,
      });
    } on FirebaseException catch (e) {
      // Caught an exception from Firebase.
      rethrow;
    }
  }

  removeImages(List<String> imagesUrls) async {
    var imageUrls = await Future.wait(imagesUrls.map((url) => deleteFile(url)));
  }

  Future<void> deleteFile(String url) async {
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (e) {
      print("Error deleting db from cloud: $e");
    }
  }

  List<String> convertToArrayForSearch(searchStr) {
    List<String> listnumber = searchStr.split("");
    List<String> output = []; // int -> String
    for (int i = 0; i < listnumber.length; i++) {
      if (i != listnumber.length - 1) {
        output.add(listnumber[i]); //
      }
      List<String> temp = [listnumber[i]];
      for (int j = i + 1; j < listnumber.length; j++) {
        temp.add(listnumber[j]); //
        output.add((temp.join()));
      }
    }
    return output;
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
