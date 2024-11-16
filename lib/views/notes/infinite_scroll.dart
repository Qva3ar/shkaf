import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_network/image_network.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';

import '../../services/cloud/firebase_cloud_storage.dart';
import '../categories/category_list.dart';

typedef NoteCallback = void Function(CloudNote note);
typedef NoteEmptyCallback = void Function();

class InfiniteScrollWidget extends StatefulWidget {
  final List<CloudNote> notes;
  final NoteCallback onDeleteNote;
  final NoteCallback onTap;

  const InfiniteScrollWidget({
    Key? key,
    required this.notes,
    required this.onDeleteNote,
    required this.onTap,
  }) : super(key: key);
  @override
  _InfiniteScrollWidgetState createState() => _InfiniteScrollWidgetState();
}

class _InfiniteScrollWidgetState extends State<InfiniteScrollWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FirebaseCloudStorage _notesService;

  final int _perPage = 15;
  late double paddingTop;
  DocumentSnapshot? _lastDocument;
  // List<CloudNote> _items = [];
  bool _isLoading = false;
  bool _isInfiniteScrollLoading = false;
  final ScrollController _scrollController = ScrollController();
  final PagingController<int, CloudNote> _pagingController = PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    // _items = widget.notes;
    _notesService = FirebaseCloudStorage();
    paddingTop = _notesService.showAD ? 115 : 60;
    // _getMoreData();
    _scrollController.addListener(_scrollListener); // Добавляем слушателя скролла

    _notesService.loadingManager.listen((event) {
      setState(() {
        _isLoading = event;
      });
    });
    _notesService.scrollManager.listen((event) {
      setState(() {
        _isLoading = true;
      });
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener); // Удаляем слушателя при уничтожении виджета
    _scrollController.dispose();
    super.dispose();
  }

  Timer? _timer; // Переменная для хранения таймера

  void _scrollListener() {
    // Определите величину смещения (например, 400 пикселей) от конца списка
    const offsetFromEnd = 400;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - offsetFromEnd) {
      setState(() {
        _isInfiniteScrollLoading = true;
      });
      // Отменяем предыдущий таймер, если он был установлен
      _timer?.cancel();

      // Устанавливаем новый таймер с задержкой в 500 миллисекунд
      _timer = Timer(const Duration(milliseconds: 500), () async {
        // Если осталось меньше или равно offsetFromEnd пикселей до конца списка,
        // загружаем новые данные
        // widget.onScroll();
        await _notesService.allNotes(true);

        setState(() {
          _isInfiniteScrollLoading = false;
        });
      });
    }
  }

  Widget _buildList() {
    return !_isLoading
        ? Padding(
            padding: const EdgeInsets.only(bottom: 50, top: 0, left: 16, right: 16),
            child: StreamBuilder<List<CloudNote>>(
              stream: _notesService.movieController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final items = snapshot.data!;

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _isLoading =
                            true; // Устанавливаем состояние загрузки в true перед началом обновления
                      });
                      await _notesService
                          .allNotes(false); // Загрузка данных с "pull down to refresh"
                      setState(() {
                        _isLoading =
                            false; // Устанавливаем состояние загрузки в true перед началом обновления
                      });
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          return _isInfiniteScrollLoading
                              ? const Center(child: CircularProgressIndicator())
                              : const SizedBox.shrink();
                        } else {
                          return Card(
                            semanticContainer: true,
                            elevation: 0,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  child: items[index].imagesUrls != null &&
                                          items[index].imagesUrls!.isNotEmpty
                                      ? ImageNetwork(
                                          image: items[index].imagesUrls![0],
                                          imageCache: CachedNetworkImageProvider(
                                              items[index].imagesUrls![0]),
                                          height: 120,
                                          width: double.infinity,
                                          duration: 1500,
                                          onPointer: true,
                                          debugPrint: false,
                                          fullScreen: false,
                                          fitAndroidIos: BoxFit.cover,
                                          fitWeb: BoxFitWeb.cover,
                                          borderRadius: BorderRadius.circular(4),
                                          onLoading: const CircularProgressIndicator(
                                            color: Colors.indigoAccent,
                                          ),
                                          onError: const Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                          onTap: () {
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            widget.onTap(items[index]);
                                          },
                                        )
                                      : Image.asset('assets/images/img_placeholder.jpeg',
                                          height: 120, width: double.infinity, fit: BoxFit.fill),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 3),
                                      Text(
                                        items[index].text,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      // Text(
                                      //   notes[i].price.toString() + "TL",
                                      //   style: const TextStyle(
                                      //     fontWeight: FontWeight.bold,
                                      //     fontSize: 16,
                                      //     color: Colors.black54,
                                      //   ),
                                      // ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              getCityName(items[index].cityId ?? 0),
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                // fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Color.fromARGB(177, 158, 158, 158),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            getFormattedDate(
                                                items[index].updatedAt ?? items[index].createdAt),
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              // fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  );
                } else {
                  return const Center(child: Text('Пусто'));
                }
              },
            ),
          )
        : const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildList(),
    );
  }
}

getFormattedDate(DateTime date) {
  return Jiffy.parseFromDateTime(date).format(pattern: 'dd.MM.yyyy');
}
