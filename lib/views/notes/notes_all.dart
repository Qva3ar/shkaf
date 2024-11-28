import 'dart:async';

import 'package:algoliasearch/algoliasearch.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/models/search_metadata.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/services/notification_service.dart';
import 'package:mynotes/services/shared_preferences_service.dart';
import 'package:mynotes/utilities/helpers/ad_helper.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:mynotes/utilities/widgets/custom_bottom_navigation_bar.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/notes/note_details.dart';
import 'package:mynotes/views/notes/notes_gridview.dart';
import 'package:mynotes/views/notes/search_and_city_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocConsumer, ReadContext;
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/utils.dart';
import '../../models/push_notification.dart';
import '../../services/auth/bloc/auth_state.dart';
import '../../utilities/widgets/categories_bottom_sheet.dart';

class NotesAll extends StatefulWidget {
  const NotesAll({Key? key}) : super(key: key);

  @override
  State<NotesAll> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesAll> with WidgetsBindingObserver {
  late final FirebaseCloudStorage _notesService;
  late final FirebaseMessaging _messaging;
  static const selectedCityKey = 'selectedCity';

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  late int _totalNotifications;
  PushNotification? _notificationInfo;

  int currentIndex = 0;

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

  SearchClient client = SearchClient(
    appId: 'XR4DEPQU93',
    apiKey: 'eb255f09f97a86c1c52540313c8761e6',
  );

  @override
  void initState() {
    super.initState();
    _streamController = StreamController();

    _notesService = FirebaseCloudStorage();
    // _notesService.createInterstitialAd();
    _scrollController = ScrollController(); // Initialize the ScrollController
    _scrollController.addListener(_onScroll);

    initializeSpref();
    _notesService.allNotes(false);
    // _loadBannerAd();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb && !kDebugMode && getSmartPhoneOrTablet() == androidType) {
        _showPlatformDialog(context);
      }
    });

    // WidgetsBinding.instance.addObserver(this);
    _notesService.getSettings();
    registerNotification();

    _notesService.categoryNameForSheet.listen((value) {
      setState(() {
        selectedCategory = value;
      });
    });
    search();
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

    final response = await client.searchIndex(request: query);

    if (response.hits.isNotEmpty) {
      final List<CloudNote> newHits =
          response.hits.map<CloudNote>((hit) => CloudNote.fromHit(hit)).toList();

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

  void registerNotification() async {
    NotificationService().initialize((PushNotification notification) {
      setState(() {
        _notificationInfo = notification;
        _totalNotifications++;
      });

      // Показываем диалог
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(notification.title ?? "No Title"),
            content: Text(notification.body ?? "No Body"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    });
  }

  setSelectedCity(int id) async {
    await SharedPreferencesService().setInt(selectedCityKey, id);
    _notesService.setSelectedId(id);
    search();
  }

  isOldUser() => SharedPreferencesService().getBool("isOldUser") ?? false;

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

  licenseAlertDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: const Text("Принимаю"),
      onPressed: () async {
        await SharedPreferencesService().setBool('isOldUser', true);
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Пользовательское соглашение"),
      content: TextButton(
        onPressed: openUrl(
            'https://docs.google.com/document/d/16w4WSDrYcIrETM5_ERO4SbSc6yxRzXMOpyCf0p_vqj8/edit'),
        child: const Text(
            'Регистрируясь на сервисе "Shkaf.in" вы принимаете Пользовательское соглашение и соглашаетесь на обработку ваших персональных данных в соответствии с ним.'),
      ),
      actions: [
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  initializeSpref() async {
    final cityId = SharedPreferencesService().getInt(selectedCityKey) ?? 1;
    setSelectedCity(cityId);
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(const AuthEventInitialize());
  }

  onSearch(String text) {
    _notesService.setSearchStr(text);
    _notesService.allNotes(false);
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    getArguments(context);

    // _notesService.allNotes(false);
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
    _notesService.allNotes(false);

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
          print("Fetching new notes");
          _notesService.allNotes(false);
          _notesService.getSettings().then((value) => setState(() {
                _isBannerAdReady = true && _notesService.showAD;
              }));
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
      getAllNotes();
    } else {
      _notesService.setCategoryId(id);
      _notesService.setMainCategoryId(0);
      _notesService.categoryNameForSheet.add(name);

      getAllNotes();
    }
    _notesService.scrollManager.add(true);
    Navigator.pop(context);
  }

  late List<CloudNote> _allNotes = []; // Declare a state variable

  void getAllNotes() {
    // setState(() {
    //   _allNotes = _notesService.allNotes(false); // Store the result
    // });
    search();
  }

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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            centerTitle: true,
            title: StreamBuilder(
              stream: _notesService.movieStream,
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
                  if (state.user != null) {
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
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: currentIndex,
            onTabSelected: (index) {
              setState(() {
                currentIndex = index;
              });
              switch (index) {
                case 0:
                  Navigator.of(context).pushNamed('/favorites');
                  break;
                case 1:
                  showModal();
                  break;
                case 2:
                  if (state.user != null) {
                    Navigator.of(context).pushNamed('/createAd');
                  } else {
                    Navigator.of(context).pushNamed(login);
                  }
                  break;
                default:
                  break;
              }
            },
          ),
          body: Column(
            children: [
              SearchAndCityBar(
                onSearch: (text) {
                  // _notesService.setSearchStr(text);
                  // _notesService.allNotes(false);
                  _performSearch(text, isRefresh: true);
                },
                selectedCityId: _notesService.selectedCityStream.value,
                onCityChanged: (cityId) async {
                  // await setUserSelectedCity(cityId);

                  setSelectedCity(cityId);
                  // _notesService.allNotes(false);
                },
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 9),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _performSearch('', isRefresh: true); // Обновление данных
                  },
                  child: StreamBuilder<List<CloudNote>>(
                    stream: _streamController.stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData) {
                        return Center(
                          child: Text(
                            'Нет данных для отображения',
                            style: AppTextStyles.s14w500.copyWith(color: AppColors.grey),
                          ),
                        );
                      }
                      // Get data from the theat
                      final notes = snapshot.data;
                      return NotesGridView(
                        notes: notes ?? [],
                        onTap: (note) {
                          _notesService.selectedNote.add(note);
                          // Navigator.of(context).pushNamed(
                          //   noteDetailsRoute,
                          //   arguments: note,
                          // );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteDetailsView(
                                note: note,
                              ),
                            ),
                          );
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
