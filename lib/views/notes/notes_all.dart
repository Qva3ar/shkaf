import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/dialogs/logout_dialog.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/notes/notes_list_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocConsumer, ReadContext;
import 'package:mynotes/views/notes/search_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/utils.dart';
import '../../services/auth/bloc/auth_state.dart';

extension Count<T extends Iterable> on Stream<T> {
  Stream<int> get getLength => map((event) => event.length);
}

class NotesAll extends StatefulWidget {
  const NotesAll({Key? key}) : super(key: key);

  @override
  _NotesViewState createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesAll> {
  late final FirebaseCloudStorage _notesService;
  int? categoryId;
  int? mainCategoryId;
  bool isOldUser = false;
  static const selectedCityKey = 'selectedCity';
  late final SharedPreferences prefs;
  String selectedCategory = "";
  DraggableScrollableController controller = DraggableScrollableController();

  @override
  void initState() {
    initializeSpref();
    var userSelectedId = getUserSelectedCity();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb && !kDebugMode && getSmartPhoneOrTablet() == androidType) {
        _showPlatformDialog(context);
      }
    });

    _notesService = FirebaseCloudStorage();
    super.initState();
    _notesService.categoryNameForSheet.listen((value) {
      setState(() {
        selectedCategory = value;
      });
    });
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
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return bottomDetailsSheet(openWithCategory, 1, true,
            _notesService.categoryNameForSheet.value);
      },
    );
  }

  licenseAlertDialog(BuildContext context) {
    Widget okButton = TextButton(
      child: Text("Принимаю"),
      onPressed: () {
        isOldUser = true;
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Пользовательское соглашение"),
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
                  return const Text('ШКАФ');
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
                    : Container(),
                IconButton(
                  onPressed: () {
                    if (state.user != null) {
                      Navigator.of(context).pushNamed(userDetails);
                    } else {
                      Navigator.of(context).pushNamed(login);
                    }
                  },
                  icon: Icon(Icons.person),
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
            body: StreamBuilder(
              stream: _notesService.movieStream,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                  case ConnectionState.active:
                    if (snapshot.hasData) {
                      final allNotes = snapshot.data as Iterable<CloudNote>;
                      return Stack(
                        children: [
                          Row(
                            children: [
                              Padding(
                                  padding:
                                      const EdgeInsets.only(left: 20, top: 5),
                                  child: DropdownButton(
                                      value: _notesService
                                          .selectedCityStream.value,
                                      items: TURKEY
                                          .map((e) => DropdownMenuItem(
                                              value: e['id'],
                                              child:
                                                  Text(e['name'].toString())))
                                          .toList(),
                                      onChanged: ((value) {
                                        setUserSelectedCity(
                                            int.parse(value.toString()));
                                        setSelectedCity(
                                            int.parse(value.toString()));
                                      }))),
                              Expanded(
                                  child: SearchBar(
                                searchcb: onSearch,
                              ))
                            ],
                          ),

                          SizedBox(
                            child: NotesListView(
                              notes: allNotes,
                              onDeleteNote: (note) async {
                                await _notesService.deleteNote(
                                    documentId: note.documentId);
                              },
                              onTap: (note) {
                                _notesService.selectedNote.add(note);
                                Navigator.of(context).pushNamed(
                                  noteDetailsRoute,
                                  arguments: note,
                                );
                              },
                            ),
                          ),

                          // bottomDetailsSheet(
                          //     openWithCategory, 0.1, true, selectedCategory),
                          // ElevatedButton(
                          //     onPressed: showModal, child: Text("lick"))
                        ],
                      );
                    } else {
                      return const CircularProgressIndicator();
                    }
                  default:
                    return const CircularProgressIndicator();
                }
              },
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: Container(
              height: 55,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () {
                  showModal();
                },
                child: Center(
                  child: Text(
                    _notesService.categoryNameForSheet.value ?? "Категории",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24,
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

Widget bottomDetailsSheet(
  Function fun,
  double initialSize,
  bool isMainSelectable,
  String selectedCat,
) {
  return DraggableScrollableSheet(
    builder: (BuildContext context, ScrollController scrollController) {
      return Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0))),
        child: Container(
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Container(
                    height: 4,
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: const Color.fromARGB(255, 91, 91, 91),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Card(
                    elevation: 0,
                    child: SizedBox.square(
                      child: Center(
                        child: Text(
                          selectedCat,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ...CATEGORIES.map((u) => Column(children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            isMainSelectable
                                ? fun(ListViewArguments(
                                    0, int.parse(u['id'].toString())))
                                : null;
                            Navigator.pop(context);
                          },
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    u['name'].toString(),
                                    style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                        backgroundColor: Colors.transparent,
                                        color: Color.fromARGB(255, 69, 69, 69)),
                                  ),
                                ),
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.arrow_right,
                                      color: Color.fromARGB(255, 124, 124, 124),
                                    ),
                                  ),
                                )
                              ]),
                        ),
                      ),
                    ),
                    ...(u['sub_categories'] as List).map((e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            fun(ListViewArguments(
                                e['id'], int.parse(u['id'].toString())));
                          },
                          child: Card(
                            elevation: 0,
                            color: Color.fromARGB(128, 173, 204, 255),
                            child: ListTile(title: Text(e['name'].toString())),
                          ),
                        )))
                  ]))
            ],
          ),
        ),
      );
    },
  );
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
