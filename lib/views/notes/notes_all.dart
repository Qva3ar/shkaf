import 'dart:async';

import 'package:algoliasearch/algoliasearch.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/algolia_search.dart';
import 'package:mynotes/services/auth/auth_state.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/services/favorites_services.dart';
import 'package:mynotes/services/notification_service.dart';
import 'package:mynotes/services/shared_preferences_service.dart';
import 'package:mynotes/utilities/helpers/ad_helper.dart';
import 'package:mynotes/utilities/widgets/custom_bottom_navigation_bar.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/dialogs/platform_dialog.dart';
import 'package:mynotes/views/notes/note_details.dart';
import 'package:mynotes/views/notes/notes_gridview.dart';
import 'package:mynotes/views/notes/search_and_city_bar.dart';
import '../../helpers/utils.dart';
import '../../utilities/widgets/categories_bottom_sheet.dart';

class NotesAll extends StatefulWidget {
  final Function(int)? onFavoriteTap;
  const NotesAll({Key? key, this.onFavoriteTap}) : super(key: key);

  @override
  State<NotesAll> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesAll> with WidgetsBindingObserver {
  late final FirebaseCloudStorage _notesService;
  final FavoritesService favoritesService = FavoritesService();

  static const selectedCityKey = 'selectedCity';

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  int currentIndex = 1;

  int views = 0;
  String selectedCategory = "";
  DraggableScrollableController controller = DraggableScrollableController();
  ScrollController _scrollController = ScrollController();

  late StreamController<List<CloudNote>> _streamController;

  final List<CloudNote> _notes = [];
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String searchText = "";

  late List<String> favorites = [];

  final algoliaService = AlgoliaService();

  @override
  void initState() {
    super.initState();
    _streamController = StreamController();
    getFavorites();

    _notesService = FirebaseCloudStorage();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    initializeSpref();
    _loadBannerAd();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb && !kDebugMode && getSmartPhoneOrTablet() == androidType) {
        showPlatformDialog(context);
      }
    });

    _notesService.getSettings();

    _notesService.categoryNameForSheet.listen((value) {
      setState(() {
        selectedCategory = value;
      });
    });
  }

  getFavorites() async {
    favorites = await favoritesService.getFavorites();
  }

  search() {
    _performSearch(isRefresh: true);
  }

  Future<void> _performSearch({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    if (isRefresh) {
      _page = 0;
      _hasMore = true;
      _notes.clear();
      _streamController.add([]);
    }

    List<String> filters = [];

    int cityId = _notesService.getSelectedCityId();
    filters.add('city_id=$cityId');

    int? mainCategory = _notesService.mainCategoryIdStream.value;
    if (mainCategory != 0) {
      filters.add('main_category_id=$mainCategory');
    }

    int? categoryId = _notesService.categoryIdStream.value;
    if (categoryId != 0) {
      filters.add('category_id=$categoryId');
    }

    String filtersString = filters.join(' AND ');

    var query = SearchForHits(
        indexName: 'notes',
        hitsPerPage: 20,
        page: _page,
        query: searchText,
        filters: filtersString);
    print("page $query");
    // print("page $_page");
    // print("search text $searchText");

    final response = await algoliaService.client.searchIndex(request: query);
    print(response.hits.length);
    List<CloudNote> newHits;
    if (response.hits.isNotEmpty) {
      if (favorites.isNotEmpty) {
        newHits = response.hits.map<CloudNote>((hit) {
          final note = CloudNote.fromHit(hit);
          return note.copyWith(isFavorite: favorites.contains(note.documentId));
        }).toList();
      } else {
        //почему то иногда favorites не проинициализирован
        newHits = response.hits.map<CloudNote>((hit) {
          return CloudNote.fromHit(hit);
        }).toList();
      }

      setState(() {
        _isLoading = false;
        if (newHits.length < 20) {
          _hasMore = false;
        }
        print("has more $_hasMore");
        _page++;
        _notes.addAll(newHits);
        _streamController.add(_notes);
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  setSelectedCity(int id) async {
    await SharedPreferencesService().setInt(selectedCityKey, id);
    _notesService.setSelectedId(id);
    await search();
  }

  showModal() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useRootNavigator: false,
      builder: (BuildContext context) {
        return bottomDetailsSheet(onFeaturedClicked);
      },
    );
  }

  initializeSpref() async {
    final cityId = SharedPreferencesService().getInt(selectedCityKey) ?? 1;
    await setSelectedCity(cityId);
    FocusScope.of(context).unfocus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      print("App resumed");

      var usedLast = SharedPreferencesService().getString('last_used');
      if (usedLast != null) {
        var threshold = DateTime.now().subtract(const Duration(minutes: 2)); // Порог в 60 минут
        DateTime dt1 = DateTime.fromMillisecondsSinceEpoch(int.parse(usedLast));

        Duration diff = threshold.difference(dt1); // Изменено порядок сравнения

        print("Last used: ${dt1.toString()}");
        print("Difference in minutes: ${diff.inMinutes}");

        if (diff.inMinutes > 60) {
          search();
          _notesService.getSettings();
          setState(() {});
        }
      }

      var currentTime = DateTime.now();
      await SharedPreferencesService()
          .setString('last_used', currentTime.millisecondsSinceEpoch.toString());

      print("Current time: ${currentTime.toString()}");
    }
  }

  void onFeaturedClicked(id, isMain, mainCatId) {
    if (isMain) {
      _notesService.setCategoryId(0);
      _notesService.setMainCategoryId(id);
    } else {
      _notesService.setCategoryId(id);
      _notesService.setMainCategoryId(mainCatId);
    }
    search();
    Navigator.pop(context);
  }

  void resetCategory() {
    _notesService.setCategoryId(0);
    _notesService.setMainCategoryId(0);

    search();
  }

  late List<CloudNote> _allNotes = []; // Declare a state variable

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true && _notesService.showAD;
          });
        },
        onAdFailedToLoad: (ad, err) {
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  void _onScroll() {
    var nextPageTrigger = 0.8 * _scrollController.position.maxScrollExtent;

    if (_scrollController.position.pixels > nextPageTrigger) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _streamController.close();
    // client.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService().authState, // Подключаем поток состояния аутентификации
      builder: (context, authSnapshot) {
        final authState = authSnapshot.data;
        print("notes ALL APPBAR");

        return Scaffold(
          backgroundColor: AppColors.lightGrey,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            centerTitle: true,
            title: StreamBuilder(
              stream: AuthService().authState,
              builder: (context, snapshot) {
                return Image.asset(
                  'assets/icons/shkaf.png',
                  width: 80,
                  height: 32,
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showModal();
            },
            backgroundColor: AppColors.violet,
            child: const Icon(Icons.list),
          ),
          body: Column(
            children: [
              SearchAndCityBar(
                onSearch: (text) {
                  setState(() {
                    searchText = text;
                  });
                  _performSearch(isRefresh: true);
                },
                selectedCityId: _notesService.selectedCityStream.value,
                onCityChanged: (cityId) async {
                  setSelectedCity(cityId);
                },
              ),
              const SizedBox(height: 8),
              if (_notesService.showAD)
                _isBannerAdReady
                    ? Padding(
                        padding: const EdgeInsets.only(top: 0),
                        child: SizedBox(
                          width: _bannerAd.size.width.toDouble(),
                          height: _bannerAd.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd),
                        ),
                      )
                    : const SizedBox(
                        height: 50, // Место под рекламу, если она ещё не загрузилась
                      ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _notesService.mainCategoryIdStream.value != null
                        ? Text(
                            getMainCategoryName(_notesService.mainCategoryIdStream.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14, // Размер текста
                              color: AppColors.grey, // Цвет текста
                            ),
                          )
                        : Container(),
                    const SizedBox(
                      width: 8,
                    ),
                    _notesService.categoryIdStream.value != 0
                        ? Text(
                            getCategoryName(_notesService.categoryIdStream.value),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          )
                        : Container(),
                    _notesService.mainCategoryIdStream.value != 0
                        ? Container(
                            height: 18,
                            child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: resetCategory,
                                icon: const Icon(
                                  Icons.clear,
                                  size: 20,
                                  color: AppColors.grey,
                                )),
                          )
                        : Container(),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _performSearch(isRefresh: true);
                  },
                  child: StreamBuilder<List<CloudNote>>(
                    stream: _streamController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'Нет данных для отображения',
                            style: AppTextStyles.s14w500.copyWith(color: AppColors.grey),
                          ),
                        );
                      }

                      final notes = snapshot.data;
                      return NotesGridView(
                        notes: notes ?? [],
                        onTap: (note) async {
                          _notesService.selectedNote.add(note);
                          final DetailsViewAuguments args = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteDetailsView(
                                note: note,
                              ),
                            ),
                          );

                          setState(() {
                            // Удаляем элемент
                            _notes.removeWhere((note) => note.documentId == args.documentId);

                            // Обновляем поток
                            _streamController.add(_notes);
                          });
                        },
                        onTapFavorite: (note) async {
                          final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
                          final currentUser = AuthService().currentUser;

                          // Проверяем, авторизован ли пользователь
                          if (currentUser == null) {
                            // Navigator.of(context).pushNamed(login);
                            widget.onFavoriteTap!(3);
                            return; // Прерываем выполнение
                          }

                          // Добавляем или удаляем из избранного
                          if (updatedNote.isFavorite) {
                            await favoritesService.addToFavorites(note.documentId);
                            favorites.add(note.documentId);
                          } else {
                            await favoritesService.removeFromFavorites(note.documentId);
                            favorites.removeWhere((item) => item == note.documentId);
                          }

                          // Обновляем список
                          setState(() {
                            final index = _notes.indexWhere((n) => n.documentId == note.documentId);
                            if (index != -1) {
                              _notes[index] = updatedNote;
                              _streamController.add(_notes); // Обновляем поток
                            }
                          });
                        },
                        onDeleteNote: (note) async {
                          await _notesService.deleteNote(documentId: note.documentId);
                        },
                        scrollController: _scrollController,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

@pragma('vm:entry-point')
Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
