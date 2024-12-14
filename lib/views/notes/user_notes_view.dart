import 'dart:async';

import 'package:algoliasearch/algoliasearch.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/enums/menu_action.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/algolia_search.dart';
import 'package:mynotes/services/auth/auth_state.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/services/favorites_services.dart';
import 'package:mynotes/utilities/dialogs/logout_dialog.dart';
import 'package:mynotes/utilities/widgets/custom_bottom_navigation_bar.dart';
import 'package:mynotes/views/notes/note_details.dart';
import 'package:mynotes/views/notes/notes_gridview.dart';

extension Count<T extends Iterable> on Stream<T> {
  Stream<int> get getLength => map((event) => event.length);
}

class UserNotesView extends StatefulWidget {
  final bool? showUserAds;
  UserNotesView({
    Key? key,
    this.showUserAds = false,
  }) : super(key: key);

  @override
  _UserNotesViewState createState() => _UserNotesViewState();
}

class _UserNotesViewState extends State<UserNotesView> {
  late final FirebaseCloudStorage _notesService;
  final FavoritesService favoritesService = FavoritesService();
  final ScrollController _scrollController = ScrollController();
  final algoliaService = AlgoliaService();

  String get userId => AuthService.firebase().currentUser?.uid ?? "";
  String get email => AuthService.firebase().currentUser?.email ?? "";
  late StreamController<List<CloudNote>> _streamController;
  int currentIndex = 0;
  late List<String> favorites;

  final List<CloudNote> _notes = [];
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();

    _notesService = FirebaseCloudStorage();
    _streamController = StreamController();

    _initialize();
  }

  Future<void> _initialize() async {
    await getFavorites(); // Ждём завершения загрузки избранных
    search(); // Вызываем поиск только после загрузки избранных
  }

  Future<void> getFavorites() async {
    favorites = await favoritesService.getFavorites();
  }

  Future<void> search() async {
    await _performSearch("", isRefresh: true); // Убедитесь, что поиск завершён
  }

  Future<void> _logout() async {
    final shouldLogout = await showLogOutDialog(context);
    if (shouldLogout) {
      await AuthService.firebase().logout();
      Navigator.of(context).pushNamedAndRemoveUntil(login, (_) => false);
    }
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

    String filters;

    if (widget.showUserAds ?? false) {
      filters = 'user_id:${AuthService().currentUser?.uid}';
      print(filters);
    } else {
      filters = favorites.map((id) => 'objectID:"$id"').join(' OR ');
    }
    var query = SearchForHits(
        indexName: 'notes', hitsPerPage: 20, page: _page, query: text, filters: filters);

    final response = await algoliaService.client.searchIndex(request: query);

    if (response.hits.isNotEmpty) {
      final List<CloudNote> newHits = response.hits.map<CloudNote>((hit) {
        final note = CloudNote.fromHit(hit);
        return note.copyWith(isFavorite: favorites.contains(note.documentId));
      }).toList();

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService().authState, // Подключаем поток состояния аутентификации
      builder: (context, authSnapshot) {
        final authState = authSnapshot.data;

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
          // bottomNavigationBar: StreamBuilder<AuthState>(
          //     stream: AuthService().authState, // Подключаем поток состояния аутентификации
          //     builder: (context, snapshot) {
          //       final authState = snapshot.data;

          //       return CustomBottomNavigationBar(
          //         currentIndex: currentIndex,
          //         onTabSelected: (index) {
          //           setState(() {
          //             currentIndex = index;
          //           });

          //           switch (index) {
          //             case 0:
          //             // Navigator.of(context).pushReplacementNamed(userNotes);
          //             // break;
          //             case 1:
          //               // showModal();
          //               Navigator.of(context).pushReplacementNamed(allNotes);
          //               break;
          //             case 2:
          //               if (authState?.status == AuthStatus.loggedIn) {
          //                 Navigator.of(context).pushNamed(createNoteRoute);
          //               } else {
          //                 Navigator.of(context).pushNamed(login);
          //               }
          //               break;
          //             default:
          //               break;
          //           }
          //         },
          //       );
          //     }),
          body: Column(
            children: [
              // SearchAndCityBar(
              //   onSearch: (text) {
              //     _performSearch(text, isRefresh: true);
              //   },
              //   selectedCityId: _notesService.selectedCityStream.value,
              //   onCityChanged: (cityId) async {
              //     setSelectedCity(cityId);
              //   },
              // ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Избранное',
                    style: AppTextStyles.s16w600.copyWith(color: AppColors.black),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Expanded(
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
                        final currentUser = AuthService().currentUser;

                        // Проверяем, авторизован ли пользователь
                        if (currentUser == null) {
                          Navigator.of(context).pushNamed(login);
                          return; // Прерываем выполнение
                        }
                        final updatedNote = note.copyWith(isFavorite: !note.isFavorite);

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
            ],
          ),
        );
      },
    );
  }
}
