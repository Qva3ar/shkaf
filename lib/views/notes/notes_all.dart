import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/cloud_storage_constants.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/dialogs/logout_dialog.dart';
import 'package:mynotes/utilities/helpers/ad_helper.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/notes/search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocConsumer, ReadContext;
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/utils.dart';
import '../../models/push_notification.dart';
import '../../services/auth/bloc/auth_state.dart';
import '../../utilities/widgets/categories_bottom_sheet.dart';
import 'infinite_scroll.dart';

extension Count<T extends Iterable> on Stream<T> {
  Stream<int> get getLength => map((event) => event.length);
}

class NotesAll extends StatefulWidget {
  const NotesAll({Key? key}) : super(key: key);

  @override
  _NotesViewState createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesAll> with WidgetsBindingObserver {
  late final FirebaseCloudStorage _notesService;
  late final FirebaseMessaging _messaging;

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  late int _totalNotifications;
  PushNotification? _notificationInfo;

  int? categoryId;
  int? mainCategoryId;
  bool isOldUser = false;
  int views = 0;
  static const selectedCityKey = 'selectedCity';
  late final SharedPreferences prefs;
  String selectedCategory = "";
  DraggableScrollableController controller = DraggableScrollableController();

  final PagingController<int, CloudNote> _pagingController = PagingController(firstPageKey: 0);

  void updateCounter(views) {
    setState(() {
      views++;
    });
  }

  @override
  void initState() {
    initializeSpref();
    _loadBannerAd();
    var userSelectedId = getUserSelectedCity();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb && !kDebugMode && getSmartPhoneOrTablet() == androidType) {
        _showPlatformDialog(context);
      }
    });
    WidgetsBinding.instance.addObserver(this);
    _notesService = FirebaseCloudStorage();
    _notesService.createInterstitialAd();
    // _notesService.initConfig();
    _notesService.getSettings();
    registerNotification();
    super.initState();
    _notesService.categoryNameForSheet.listen((value) {
      setState(() {
        selectedCategory = value;
      });
    });

    // FirebaseFirestore.instance.collection('notes').get().then((snapshot) {
    //   for (DocumentSnapshot ds in snapshot.docs) {
    //     ds.reference.update({
    //       shortAddFieldName: true, //True or false
    //     });
    //   }
    // });
  }

  void registerNotification() async {
    // 1. Initialize the Firebase app

    // 2. Instantiate Firebase Messaging
    _messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _messaging.getToken().then((value) {
      print('firebase token = $value');
      //sendTokenToServer(value);
    });
    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');

      // For handling the received notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Parse the message received
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
        );

        setState(() {
          _notificationInfo = notification;
          _totalNotifications++;
        });

        showDialog(
            context: context,
            builder: (BuildContext context) {
              return const AlertDialog(
                title: Text("Success"),
                titleTextStyle:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
                backgroundColor: Colors.greenAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                content: Text("Save successfully"),
              );
            });
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  setSelectedCity(int id) {
    _notesService.setSelectedId(id);
  }

  Future setUserSelectedCity(int id) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(selectedCityKey, id);
  }

  getUserSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(selectedCityKey) ?? 10;
  }

  getUserInfo() async {
    isOldUser = prefs.getBool("isOldUser") ?? false;
  }

  showModal() {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return bottomDetailsSheet(
            openWithCategory, 1, true, _notesService.categoryNameForSheet.value, onFeaturedClicked);
      },
    );
  }

  licenseAlertDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: const Text("Принимаю"),
      onPressed: () {
        isOldUser = true;
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
    await SharedPreferences.getInstance().then((value) {
      prefs = value;
      var cityId = prefs.getInt(selectedCityKey) ?? 1;
      setSelectedCity(cityId);
      Future.delayed(Duration(microseconds: 100), setSelectedCity(cityId));
      FocusScope.of(context).unfocus();
      getUserInfo();

      context.read<AuthBloc>().add(const AuthEventInitialize());
    });
  }

  onSearch(String text) {
    _notesService.setSearchStr(text);
    _notesService.allNotes(false);
  }

  @override
  didChangeDependencies() {
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      print("App resumed");

      var usedLast = prefs.getString('last_used');
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
      prefs.setString('last_used', currentTime.millisecondsSinceEpoch.toString());

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
      _notesService.setMainCategoryId(-1);
      _notesService.categoryNameForSheet.add(name);

      getAllNotes();
    }
    _notesService.scrollManager.add(true);
    Navigator.pop(context);
  }

  void getAllNotes() {
    _notesService.allNotes(false);
    // _scrollController.jumpTo(0);
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

  @override
  void dispose() {
    //don't forget to dispose of it when not needed anymore
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {},
        builder: (context, state) {
          final userEmail = state.user?.email ?? '';

          return Scaffold(
            appBar: AppBar(
              title: StreamBuilder(
                stream: _notesService.movieStream,
                builder: (context, snapshot) {
                  // if (snapshot.hasData) {
                  //   final noteCount = snapshot.data as List;
                  //   // final text = context.loc.notes_title(noteCount);
                  //   return Text(
                  //     userEmail,
                  //     style: const TextStyle(fontSize: 18),
                  //   );
                  // } else {
                  //   return const Text('');
                  // }
                  return Image.asset(
                    'assets/icons/shkaf.png',
                    width: 80,
                    height: 32,
                  );
                },
              ),
              actions: [
                state.user != null
                    ? IconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(createNoteRoute);
                        },
                        icon: const Icon(Icons.add_business),
                      )
                    : IconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(login);
                        },
                        icon: const Icon(Icons.add_business),
                      ),
                IconButton(
                  onPressed: () {
                    if (state.user != null) {
                      Navigator.of(context).pushNamed(userDetails);
                    } else {
                      Navigator.of(context).pushNamed(login);
                    }
                  },
                  icon: const Icon(Icons.person),
                ),
                PopupMenuButton<MenuAction>(
                  onSelected: (value) async {
                    switch (value) {
                      case MenuAction.logout:
                        final shouldLogout = await showLogOutDialog(context);
                        if (shouldLogout) {
                          context.read<AuthBloc>().add(
                                const AuthEventLogOut(),
                              );
                        }
                        break;

                      case MenuAction.login:
                        Navigator.of(context).pushNamed(login);
                        break;

                      case MenuAction.writeUs:
                        openUrl('https://t.me/ShkafSupportTR');
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      state.user != null
                          ? const PopupMenuItem<MenuAction>(
                              value: MenuAction.logout,
                              child: Text("Выйти"),
                            )
                          : const PopupMenuItem<MenuAction>(
                              value: MenuAction.login,
                              child: Text("Войти"),
                            ),
                      const PopupMenuItem<MenuAction>(
                        value: MenuAction.writeUs,
                        child: Text("Напишите нам"),
                      ),
                    ];
                  },
                )
              ],
            ),
            body: Column(
              children: [
                Row(
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                        child: DropdownButton(
                            value: _notesService.selectedCityStream.value,
                            items: TURKEY
                                .map((e) => DropdownMenuItem(
                                    value: e['id'], child: Text(e['name'].toString())))
                                .toList(),
                            onChanged: ((value) {
                              setUserSelectedCity(int.parse(value.toString()));
                              setSelectedCity(int.parse(value.toString()));
                            }))),
                    Expanded(
                        child: SearchBarWidget(
                      searchcb: onSearch,
                    ))
                  ],
                ),
                if (_isBannerAdReady)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: _bannerAd.size.width.toDouble(),
                          height: _bannerAd.size.height.toDouble(),
                          child: AdWidget(ad: _bannerAd),
                        )
                      ],
                    ),
                  ),

                Expanded(
                    child: InfiniteScrollWidget(
                  notes: const [],
                  onTap: (note) {
                    updateCounter(views);
                    _notesService.selectedNote.add(note);
                    // Navigator.of(context).pushNamed(
                    //   noteDetailsRoute,
                    //   arguments: note,
                    // );
                    Navigator.pushNamed(context, noteDetailsRoute, arguments: note);
                  },
                  onDeleteNote: (note) async {
                    await _notesService.deleteNote(documentId: note.documentId);
                  },
                ))
                // NotesListView(
                //   notes: allNotes,
                //   onDeleteNote: (note) async {
                //     await _notesService.deleteNote(
                //         documentId: note.documentId);
                //   },
                //   onTap: (note) {
                //     updateCounter(views);
                //     _notesService.selectedNote.add(note);
                //     Navigator.of(context).pushNamed(
                //       noteDetailsRoute,
                //       arguments: note,
                //     );
                //   },
                // ),

                // bottomDetailsSheet(
                //     openWithCategory, 0.1, true, selectedCategory),
                // ElevatedButton(
                //     onPressed: showModal, child: Text("lick"))
              ],
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            floatingActionButton: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF4CAF50), // Используйте Color для задания цвета напрямую
                ),
                onPressed: () {
                  showModal();
                },
                child: Center(
                  child: Text(
                    _notesService.categoryNameForSheet.value ?? "Категории",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 228, 228, 228)),
                  ),
                ),
              ),
            ),
          );
        });
  }
}

Widget bottomCitiesSheet(Function fun, double initialSize) {
  return DraggableScrollableSheet(
    initialChildSize: initialSize,
    minChildSize: .1,
    maxChildSize: 1,
    builder: (BuildContext context, ScrollController scrollController) {
      return Container(
        color: Colors.white,
        child: ListView(
          controller: scrollController,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Card(
                  child: Text(
                    "Выберите город",
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Color.fromARGB(255, 82, 99, 255),
                        color: Colors.white),
                  ),
                ),
              ),
            ),
            ...TURKEY.map((u) => Column(children: [
                  Center(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => fun(u['id']),
                            child: Card(
                              color: Colors.white,
                              child: ListTile(title: Text(u['name'].toString())),
                            ),
                          ))),
                ]))
          ],
        ),
      );
    },
  );
}

Future<void> _showPlatformDialog(context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Наше приложение доступно в Google Play.'),
        content: GestureDetector(
          onTap: () {
            openUrl('https://play.google.com/store/apps/details?id=com.aturdiyev.mynotes');
          },
          child: Container(
            child: (Image.asset(
              'assets/icons/googleplay.png',
              width: 150,
              height: 80,
            )),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ок'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

@pragma('vm:entry-point')
Future _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
