import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/dialogs/logout_dialog.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/notes/notes_list_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocConsumer, ReadContext;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cities.dart';
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

  @override
  void initState() {
    initializeSpref();
    initUserSelectedCity();
    _notesService = FirebaseCloudStorage();
    super.initState();
    _notesService.categoryNameForSheet.listen((value) {
      selectedCategory = value;
    });
  }

  setSelectedCity(int id) {
    _notesService.setSelectedId(id);
  }

  Future initUserSelectedCity() async {
    prefs = await getUserSelectedCity();
  }

  Future setUserSelectedCity(int id) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(selectedCityKey, id);
  }

  Future getUserSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.getInt(selectedCityKey) ?? 10;
  }

  getUserInfo() async {
    isOldUser = prefs.getBool("isOldUser") ?? false;
  }

  initializeSpref() async {
    await SharedPreferences.getInstance().then((value) {
      prefs = value;
      getUserInfo();
      context.read<AuthBloc>().add(const AuthEventInitialize());
      AuthService.firebase().auth?.listen((event) {
        log("User");
        log(event.toString());
      });
    });
  }

  @override
  didChangeDependencies() {
    log("ALL NOTES CHASNGE");
    getArguments(context);
    _notesService.allNotes(false);
  }

  getArguments(context) {
    if (ModalRoute.of(context)!.settings.arguments != null) {
      ListViewArguments args =
          ModalRoute.of(context)!.settings.arguments as ListViewArguments;
      categoryId = args.categoryId;
      mainCategoryId = args.mainCategoryId;
    }
  }

  // showModal() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     isDismissible: true,
  //     builder: (BuildContext context) {
  //       log('show');
  //       return bottomDetailsSheet(goToDetails);
  //     },
  //   );
  // }

  openWithCategory(ListViewArguments arg) {
    _notesService.setCategoryId(arg.categoryId);
    _notesService.setMainCategoryId(arg.mainCategoryId);
    Navigator.popAndPushNamed(context, allNotes,
        arguments: ListViewArguments(arg.categoryId, arg.mainCategoryId));

    var selectedCatLabel = getMainCategoryName(arg.mainCategoryId);
    if (arg.categoryId != null) {
      selectedCategory =
          selectedCategory + " - " + getCategoryName(arg.categoryId);
    }
    _notesService.categoryNameForSheet.add(selectedCatLabel);
  }

  Future<void> _pullRefresh() async {
    setState(() {
      _notesService.allNotes(false);
    });
    // why use freshNumbers var? https://stackoverflow.com/a/52992836/2301224
  }

  @override
  Widget build(BuildContext context) {
    // context.read<AuthBloc>().add(const AuthEventInitialize());

    return BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {},
        builder: (context, state) {
          final userEmail = state.user?.email ?? '';

          return Scaffold(
            appBar: AppBar(
              title: StreamBuilder(
                stream: _notesService.movieStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final noteCount = snapshot.data as List;
                    // final text = context.loc.notes_title(noteCount);
                    return Text(noteCount.length.toString() + " " + userEmail);
                  } else {
                    return const Text('');
                  }
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
                state.user != null
                    ? PopupMenuButton<MenuAction>(
                        onSelected: (value) async {
                          switch (value) {
                            case MenuAction.logout:
                              final shouldLogout =
                                  await showLogOutDialog(context);
                              if (shouldLogout) {
                                context.read<AuthBloc>().add(
                                      const AuthEventLogOut(),
                                    );
                              }
                          }
                        },
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem<MenuAction>(
                              value: MenuAction.logout,
                              child: Text(context.loc.logout_button),
                            ),
                          ];
                        },
                      )
                    : Container()
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
                      return RefreshIndicator(
                          onRefresh: _pullRefresh,
                          child: Stack(
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
                              bottomDetailsSheet(openWithCategory, 0.1, true,
                                  selectedCategory),
                              // ElevatedButton(
                              //     onPressed: showModal, child: Text("lick"))
                            ],
                          ));
                    } else {
                      return const CircularProgressIndicator();
                    }
                  default:
                    return const CircularProgressIndicator();
                }
              },
            ),
          );
        });
  }
}

Widget bottomDetailsSheet(Function fun, double initialSize,
    bool isMainSelectable, String selectedCat) {
  return DraggableScrollableSheet(
    initialChildSize: initialSize,
    minChildSize: .1,
    maxChildSize: 1,
    builder: (BuildContext context, ScrollController scrollController) {
      return Container(
        // color: Color.fromARGB(255, 82, 99, 255),
        decoration: const BoxDecoration(
            color: Color.fromARGB(248, 210, 206, 206),
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
                          onTap: () => isMainSelectable
                              ? fun(ListViewArguments(
                                  0, int.parse(u['id'].toString())))
                              : null,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text(
                                    u['name'].toString(),
                                    style: const TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                        backgroundColor: Colors.transparent,
                                        color: Color.fromARGB(255, 69, 69, 69)),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.arrow_right,
                                    color: Colors.white,
                                  ),
                                )
                              ]),
                        ),
                      ),
                    ),
                    ...(u['sub_categories'] as List).map((e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: GestureDetector(
                          onTap: () => fun(ListViewArguments(
                              e['id'], int.parse(u['id'].toString()))),
                          child: Card(
                            color: Colors.white,
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
