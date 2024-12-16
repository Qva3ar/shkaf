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
  const NotesAll({Key? key}) : super(key: key);

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

  int? categoryId;
  int? mainCategoryId;
  int views = 0;
  String selectedCategory = "";
  DraggableScrollableController controller = DraggableScrollableController();
  ScrollController _scrollController = ScrollController();

  late StreamController<List<CloudNote>> _streamController;

  final List<CloudNote> _notes = [];
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  late List<String> favorites = [];

  final algoliaService = AlgoliaService();

  @override
  void initState() {
    super.initState();
    _streamController = StreamController();
    getFavorites();

    _notesService = FirebaseCloudStorage();
    _scrollController = ScrollController(); // Initialize the ScrollController
    _scrollController.addListener(_onScroll);

    initializeSpref();
    _loadBannerAd();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb && !kDebugMode && getSmartPhoneOrTablet() == androidType) {
        showPlatformDialog(context);
      }
    });

    // WidgetsBinding.instance.addObserver(this);
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
    _performSearch("", isRefresh: true);
  }

  Future<void> _performSearch(String? text, {bool isRefresh = false}) async {
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
        indexName: 'notes', hitsPerPage: 20, page: _page, query: text, filters: filtersString);

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
        return bottomDetailsSheet(
            openWithCategory, 1, true, _notesService.categoryNameForSheet.value, onFeaturedClicked);
      },
    );
  }

  initializeSpref() async {
    final cityId = SharedPreferencesService().getInt(selectedCityKey) ?? 1;
    await setSelectedCity(cityId);
    FocusScope.of(context).unfocus();
  }

  updateWithFaforite(String documentId) {}

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    getArguments(context);
  }

  getArguments(context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      ListViewArguments args = ModalRoute.of(context)!.settings.arguments as ListViewArguments;
      categoryId = args.categoryId;
      mainCategoryId = args.mainCategoryId;
    }
  }

  openWithCategory(ListViewArguments arg) {
    _notesService.setCategoryId(arg.categoryId);
    _notesService.setMainCategoryId(arg.mainCategoryId);

    var selectedCatLabel = getMainCategoryName(arg.mainCategoryId);
    if (arg.categoryId != 0) {
      selectedCatLabel = "$selectedCatLabel - ${getCategoryName(arg.categoryId)}";
    }
    _notesService.categoryNameForSheet.add(selectedCatLabel);
    _notesService.loadingManager.add(true);
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

  void onFeaturedClicked(id, isMain, name) {
    if (isMain) {
      _notesService.setCategoryId(0);
      _notesService.setMainCategoryId(id);
      _notesService.categoryNameForSheet.add(name);
    } else {
      _notesService.setCategoryId(id);
      _notesService.setMainCategoryId(0);
      _notesService.categoryNameForSheet.add(name);
    }
    search();
    _notesService.scrollManager.add(true);
    Navigator.pop(context);
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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _performSearch('');
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
            actions: [
              IconButton(
                onPressed: () {
                  if (authState?.status == AuthStatus.loggedIn) {
                    Navigator.of(context).pushNamed(userDetails);
                  } else {
                    Navigator.of(context).pushNamed(login);
                  }
                },
                icon: const Icon(
                  Icons.person_rounded,
                  color: AppColors.black,
                ),
              ),
            ],
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
                  _performSearch(text, isRefresh: true);
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
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Популярное',
                    style: AppTextStyles.s16w600.copyWith(color: AppColors.black),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _performSearch('', isRefresh: true);
                  },
                  child: StreamBuilder<List<CloudNote>>(
                    stream: _streamController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
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
                        onTap: (note) {
                          _notesService.selectedNote.add(note);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteDetailsView(
                                note: note,
                              ),
                            ),
                          );
                        },
                        onTapFavorite: (note) async {
                          final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
                          final currentUser = AuthService().currentUser;

                          // Проверяем, авторизован ли пользователь
                          if (currentUser == null) {
                            Navigator.of(context).pushNamed(login);
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
