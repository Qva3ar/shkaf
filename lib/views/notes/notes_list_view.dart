import 'dart:developer';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/utilities/dialogs/delete_dialog.dart';
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

  @override
  void initState() {
    controller.addListener(_scrollListener);
    _notesService = FirebaseCloudStorage();

    super.initState();
  }

  void _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      print("at the end of list");
      _notesService.allNotesNext();
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    List<CloudNote> notes = widget.notes.toList();
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60, top: 60),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller,
          children: [
            notes.length > 0
                ? ListView.builder(
                    physics: const ScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: notes.length,
                    itemBuilder: (ctx, i) {
                      return GestureDetector(
                        onTap: () {
                          widget.onTap(notes[i]);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10)),
                          // margin: EdgeInsets.all(5),
                          padding: const EdgeInsets.all(5),
                          child: Card(
                            semanticContainer: true,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 100,
                                  child: notes[i].imagesUrls != null &&
                                          notes[i].imagesUrls!.isNotEmpty
                                      ? Image.network(notes[i].imagesUrls![0],
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover)
                                      : Image.asset(
                                          'assets/images/img_placeholder.jpeg',
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.fill),
                                ),
                                Container(
                                    child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 3),
                                      Text(
                                        notes[i].text,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        notes[i].price.toString() + "TL",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              getCityName(notes[i].cityId ?? 0),
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
                                                notes[i].createdAt),
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
                                ))
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text("Нет записей"),
                  )
          ],
        ),
      ),
    );
  }
}

getFormattedDate(DateTime date) {
  return Jiffy(date).format('dd.MM.yyyy');
}
