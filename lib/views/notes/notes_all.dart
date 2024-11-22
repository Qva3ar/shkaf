import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/helpers/ad_helper.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:mynotes/utilities/widgets/custom_bottom_navigation_bar.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/notes/notes_gridview.dart';
import 'package:mynotes/views/notes/search_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocConsumer, ReadContext;
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/utils.dart';
import '../../models/push_notification.dart';
import '../../services/auth/bloc/auth_state.dart';
import '../../utilities/widgets/categories_bottom_sheet.dart';

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

  int currentIndex = 0;

  int? categoryId;
  int? mainCategoryId;
  bool isOldUser = false;
  int views = 0;
  static const selectedCityKey = 'selectedCity';
  late final SharedPreferences prefs;
  String selectedCategory = "";
  DraggableScrollableController controller = DraggableScrollableController();

  final PagingController<int, CloudNote> _pagingController =
      PagingController(firstPageKey: 0);

  void updateCounter(views) {
    setState(() {
      views++;
    });
  }

  @override
  void initState() {
    super.initState();

    _notesService = FirebaseCloudStorage();
    _notesService.createInterstitialAd();

    initializeSpref();
    _notesService.allNotes(false);
    _loadBannerAd();

    var userSelectedId = getUserSelectedCity();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb && !kDebugMode && getSmartPhoneOrTablet() == androidType) {
        _showPlatformDialog(context);
      }
    });

    WidgetsBinding.instance.addObserver(this);
    _notesService.getSettings();
    registerNotification();

    _notesService.categoryNameForSheet.listen((value) {
      setState(() {
        selectedCategory = value;
      });
    });
  }

  // FirebaseFirestore.instance.collection('notes').get().then((snapshot) {
  //   for (DocumentSnapshot ds in snapshot.docs) {
  //     ds.reference.update({
  //       shortAddFieldName: true, //True or false
  //     });
  //   }
  // });

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
                titleTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 20),
                backgroundColor: Colors.greenAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
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
      useRootNavigator: false,
      builder: (BuildContext context) {
        return bottomDetailsSheet(openWithCategory, 1, true,
            _notesService.categoryNameForSheet.value, onFeaturedClicked);
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
      Future.delayed(
          const Duration(microseconds: 100), setSelectedCity(cityId));
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
    super.didChangeDependencies();
    getArguments(context);

    // _notesService.allNotes(false);
  }

  getArguments(context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      ListViewArguments args =
          ModalRoute.of(context)!.settings.arguments as ListViewArguments;
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
      selectedCatLabel =
          "$selectedCatLabel - ${getCategoryName(arg.categoryId)}";
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
        var threshold = DateTime.now()
            .subtract(const Duration(minutes: 2)); // Порог в 60 минут
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
      prefs.setString(
          'last_used', currentTime.millisecondsSinceEpoch.toString());

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

  late List<CloudNote> _allNotes = []; // Declare a state variable

  void getAllNotes() {
    setState(() {
      _allNotes = _notesService.allNotes(false); // Store the result
    });
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
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
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
              state.user != null
                  ? IconButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(createNoteRoute);
                      },
                      icon: const Icon(
                        Icons.add_business,
                        color: AppColors.black,
                      ),
                    )
                  : IconButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(login);
                      },
                      icon: const Icon(
                        Icons.add_business,
                        color: AppColors.black,
                      ),
                    ),
              IconButton(
                onPressed: () {
                  if (state.user != null) {
                    Navigator.of(context).pushNamed(userDetails);
                  } else {
                    Navigator.of(context).pushNamed(login);
                  }
                },
                icon: const Icon(
                  Icons.person,
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
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                    child: DropdownButton(
                      value: _notesService.selectedCityStream.value,
                      dropdownColor: AppColors.white,
                      items: TURKEY
                          .map((e) => DropdownMenuItem(
                                value: e['id'],
                                child: Text(
                                  e['name'].toString(),
                                  style: AppTextStyles.s16w400,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setUserSelectedCity(int.parse(value.toString()));
                        setSelectedCity(int.parse(value.toString()));
                      },
                    ),
                  ),
                  Expanded(
                    child: SearchBarWidget(
                      searchcb: onSearch,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<List<CloudNote>>(
                  stream: _notesService.movieStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'Нет данных для отображения',
                          style: AppTextStyles.s14w500
                              .copyWith(color: AppColors.grey),
                        ),
                      );
                    }

                    // Get data from the theat
                    final notes = snapshot.data!;
                    return NotesGridView(notes: notes);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                              child:
                                  ListTile(title: Text(u['name'].toString())),
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
            openUrl(
                'https://play.google.com/store/apps/details?id=com.aturdiyev.mynotes');
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
