import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:mynotes/views/categories/category_list.dart';

import '../../services/cloud/firebase_cloud_storage.dart';

typedef NoteCallback = void Function(CloudNote note);

class NotesListView extends StatefulWidget {
  final Iterable<CloudNote> notes;
  final NoteCallback onDeleteNote;
  final NoteCallback onTap;

  const NotesListView({
    Key? key,
    required this.notes,
    required this.onDeleteNote,
    required this.onTap,
  }) : super(key: key);

  @override
  State<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends State<NotesListView> {
  ScrollController controller = ScrollController();
  late final FirebaseCloudStorage _notesService;
  static const _pageSize = 15;
  PagingStatus pageStatus = PagingStatus.ongoing;
  ScrollController scrollController = ScrollController();

  bool firstLoad = true;
  var counter = 0;
  final PagingController<int, CloudNote> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      if (pageStatus == PagingStatus.loadingFirstPage) {
        counter = 0;
      }
      if (!firstLoad) {
        var isPullRefresh = pageStatus == PagingStatus.loadingFirstPage;
        _notesService.allNotes(!isPullRefresh);
      }
      firstLoad = false;
    });
    _pagingController.addStatusListener((status) {
      pageStatus = status;
    });
    _notesService = FirebaseCloudStorage();

    super.initState();

    _notesService.movieStream.listen((event) {
      //clear page when on start searching
      if (_notesService.isSearching || _notesService.isSearchingEnded) {
        _pagingController.itemList = [];
        scrollController.jumpTo(
          scrollController.position.minScrollExtent,
        );
        _notesService.isSearchingEnded = false;
        _notesService.isSearching = false;
      }
      //clear page when on new category
      if (_notesService.isCategorySet) {
        _pagingController.itemList = [];
        scrollController.jumpTo(
          scrollController.position.minScrollExtent,
        );
        _notesService.isCategorySet = false;
      }

      final newItems = event;
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = counter + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    _pagingController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int pageKey, bool load) async {}

  @override
  Widget build(
    BuildContext context,
  ) {
    List<CloudNote> notes = widget.notes.toList();
    return Padding(
        padding: const EdgeInsets.only(bottom: 60, top: 60),
        child: RefreshIndicator(
          onRefresh: () => Future.sync(
            () {
              _pagingController.refresh();
            },
          ),
          child: PagedGridView<int, CloudNote>(
            scrollController: scrollController,
            pagingController: _pagingController,
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 1.2,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1),
            builderDelegate: PagedChildBuilderDelegate<CloudNote>(
              itemBuilder: (ctx, note, i) {
                return GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    widget.onTap(note);
                  },
                  child: Container(
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    // margin: EdgeInsets.all(5),
                    padding: const EdgeInsets.all(5),
                    child: Card(
                      semanticContainer: true,
                      elevation: 0,
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SizedBox(
                              child: note.imagesUrls != null &&
                                      note.imagesUrls!.isNotEmpty
                                  ? CachedNetworkImage(
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      imageUrl: note.imagesUrls![0],
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                    )
                                  : Image.asset(
                                      'assets/images/img_placeholder.jpeg',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.fill),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Text(
                                  note.text,
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
                                        getCityName(note.cityId ?? 0),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          // fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color.fromARGB(
                                              177, 158, 158, 158),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      getFormattedDate(
                                          note.updatedAt ?? note.createdAt),
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
                    ),
                  ),
                );
              },
            ),
            // shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 5),
          ),
        ));
  }
}

getFormattedDate(DateTime date) {
  return Jiffy(date).format('dd.MM.yyyy');
}
