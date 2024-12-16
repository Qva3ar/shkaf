import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mynotes/services/algolia_search.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/cloud_storage_exceptions.dart';
import 'package:mynotes/utilities/helpers/ad_helper.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:rxdart/rxdart.dart';

class FirebaseCloudStorage {
  final notes = FirebaseFirestore.instance.collection('notes');
  final settings = FirebaseFirestore.instance.collection('configs').doc('settings');
  final algoliaService = AlgoliaService();

  late FirebaseRemoteConfig remoteConfig;
  InterstitialAd? interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

  late DocumentSnapshot<Object?> lastDoc;
  List<CloudNote> noteList = [];
  String searchStr = '';
  bool isSearching = false;
  bool isSearchingEnded = false;

  bool showAD = false;
  int maxViewsWithoutAD = 5;

  final BehaviorSubject<List<CloudNote>> movieController = BehaviorSubject<List<CloudNote>>();

  BehaviorSubject<String> categoryNameForSheet =
      BehaviorSubject<String>.seeded(CATEGORIES[0]['name'].toString());

  BehaviorSubject<CloudNote?> selectedNote = BehaviorSubject<CloudNote?>.seeded(null);
  BehaviorSubject<int> selectedCityStream = BehaviorSubject<int>.seeded(TURKEY[0]['id'] as int);

  BehaviorSubject<int> recordViewCounter = BehaviorSubject<int>.seeded(0);

  BehaviorSubject<int> categoryIdStream = BehaviorSubject<int>.seeded(0);
  BehaviorSubject<int> mainCategoryIdStream = BehaviorSubject<int>.seeded(0);
  final BehaviorSubject<bool> scrollManager = BehaviorSubject<bool>();
  final BehaviorSubject<bool> loadingManager = BehaviorSubject<bool>();

  void createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: AdHelper.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            interstitialAd = ad;
            // _interstitialAd!.show();
            _numInterstitialLoadAttempts = 0;
            interstitialAd!.setImmersiveMode(true);
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
            _numInterstitialLoadAttempts += 1;
            interstitialAd = null;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              createInterstitialAd();
            }
          },
        )).then((value) => log("AD LOADED"));
  }

  Future<void> getSettings() async {
    // Get docs from collection reference
    FirebaseFirestore.instance
        .collection('configs')
        .doc("settings")
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        showAD = documentSnapshot['showAd'];
        maxViewsWithoutAD = documentSnapshot['maxViewsWithoutAD'];
        // Map<String, dynamic> data = documentSnapshot.data();
        //Set the relevant data to variables as needed
      } else {
        print('Document does not exist on the database');
      }
    });
    // Get data from docs and convert map to List

    // print(allData);
  }

  Future<void> initConfig() async {
    log("ini");
    remoteConfig = FirebaseRemoteConfig.instance;
    // await remoteConfig.ensureInitialized();
    // await remoteConfig.setConfigSettings(RemoteConfigSettings(
    //   fetchTimeout: Duration(minutes: 1),
    //   minimumFetchInterval: Duration(seconds: 0),
    // ));

    _fetchConfig();
  }

  void _fetchConfig() async {
    log("fetch config");

    remoteConfig.fetchAndActivate();
  }

  incrimentRecordViewCounter() {
    recordViewCounter.add(recordViewCounter.value + 1);
  }

  resetRecordViewCounter() {
    recordViewCounter.add(0);
  }

  setSelectedId(int id) {
    selectedCityStream.add(id);
  }

  int getSelectedCityId() {
    return selectedCityStream.value;
  }

  setCategoryId(int id) {
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
    mainCategoryIdStream.add(id);
  }

  Stream<List<CloudNote>> get movieStream =>
      movieController.stream.throttleTime(const Duration(milliseconds: 300));

  Future<void> deleteNote({required String documentId}) async {
    try {
      // Удаление документа из коллекции
      await notes.doc(documentId).delete();
      await algoliaService.client.deleteObject(
        indexName: "notes",
        objectID: documentId,
      );
    } on FirebaseException catch (e) {
      // Логирование ошибки Firebase
      print('FirebaseException: $e');
      throw CouldNotDeleteNoteException();
    } catch (e) {
      // Обработка других ошибок
      print('Unexpected error: $e');
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
    String? telegramId,
    int? views,
  }) async {
    try {
      await notes.doc(documentId).update({
        textFieldName: text,
        descFieldName: desc,
        imageUrls: imgUrls,
        urlFieldName: url,
        telegramIdFieldName: telegramId,
        priceFieldName: price,
        categoryIdFieldName: categoryId,
        mainCategoryIdFieldName: mainCategoryId,
        cityIdFieldName: cityId,
        phoneFieldName: phone,
        shortAddFieldName: shortAdd,
        reportsFieldName: reports,
        viewsFieldName: views,
        updatedAtFieldName: Timestamp.now()
      });
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
  }

  Future<void> updateNotViews({
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
    String? telegramId,
    int? views,
  }) async {
    try {
      await notes.doc(documentId).update({
        textFieldName: text,
        descFieldName: desc,
        imageUrls: imgUrls,
        urlFieldName: url,
        telegramIdFieldName: telegramId,
        priceFieldName: price,
        categoryIdFieldName: categoryId,
        mainCategoryIdFieldName: mainCategoryId,
        cityIdFieldName: cityId,
        phoneFieldName: phone,
        shortAddFieldName: shortAdd,
        reportsFieldName: reports,
        viewsFieldName: views,
      });
    } catch (e) {
      throw CouldNotUpdateNoteException();
    }
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
    String? telegramId,
  }) async {
    try {
      final document = await notes.add({
        ownerUserIdFieldName: ownerUserId,
        textFieldName: text,
        descFieldName: desc,
        imageUrls: imgUrls,
        urlFieldName: url,
        telegramIdFieldName: telegramId,
        priceFieldName: price,
        mainCategoryIdFieldName: mainCategoryId,
        categoryIdFieldName: categoryId,
        cityIdFieldName: cityId,
        phoneFieldName: phone,
        createdAtFieldName: Timestamp.now(),
        updatedAtFieldName: Timestamp.now(),
        shortAddFieldName: shortAdd,
      });
    } on FirebaseException {
      // Caught an exception from Firebase.
      rethrow;
    }
    return null;
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

  static final FirebaseCloudStorage _shared = FirebaseCloudStorage._sharedInstance();
  FirebaseCloudStorage._sharedInstance();
  factory FirebaseCloudStorage() => _shared;
}
