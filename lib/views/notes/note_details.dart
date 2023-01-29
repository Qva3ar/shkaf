import 'dart:developer';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/dialogs/cannot_share_empty_note_dialog.dart';
import 'package:mynotes/utilities/dialogs/delete_dialog.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/notes/notes_list_view.dart';
import 'package:mynotes/views/shared/gallery.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/cloud/cloud_storage_constants.dart';

class NoteDetailsView extends StatefulWidget {
  const NoteDetailsView({Key? key}) : super(key: key);

  @override
  _NoteDetailsViewState createState() => _NoteDetailsViewState();
}

class _NoteDetailsViewState extends State<NoteDetailsView> {
  // CloudNote? note;

  String? get userId => AuthService.firebase().currentUser?.id;
  late final FirebaseCloudStorage _notesService;

  removeNote(CloudNote note) async {
    await _notesService.deleteNote(documentId: note.documentId);
    if (note.imagesUrls!.isNotEmpty) {
      await _notesService.removeImages(note.imagesUrls!);
    }
    Navigator.pop(this.context);
  }

  Future<void> openUrl(String url) async {
    final _url = Uri.parse(url);
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      // <--
      throw Exception('Could not launch $_url');
    }
  }

  @override
  void initState() {
    super.initState();

    _notesService = FirebaseCloudStorage();
    // _notesService.selectedNote.listen((value) {
    //   log(value!.desc);
    // });
    log("DETAILS");
    log(userId.toString());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // createOrGetExistingNote(context);

    return Scaffold(
        appBar: AppBar(
          title: Text(""),
          actions: [
            // IconButton(
            //   onPressed: () async {
            //     if (_note == null || text.isEmpty) {
            //       await showCannotShareEmptyNoteDialog(context);
            //     } else {
            //       Share.share(text);
            //     }
            //   },
            //   icon: const Icon(Icons.share),
            // ),
          ],
        ),
        body: StreamBuilder(
            stream: _notesService.selectedNote.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                CloudNote note = snapshot.data as CloudNote;
                switch (snapshot.connectionState) {
                  case ConnectionState.active:
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 228, 228, 228),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: note.imagesUrls != null &&
                                        note.imagesUrls!.isNotEmpty
                                    ? CarouselSlider.builder(
                                        itemCount: note.imagesUrls?.length,
                                        options: CarouselOptions(
                                          enableInfiniteScroll: false,
                                          height: 200,
                                          aspectRatio: 16 / 9,
                                          viewportFraction: 1,
                                        ),
                                        itemBuilder: (BuildContext context,
                                                int itemIndex,
                                                int pageViewIndex) =>
                                            Builder(
                                              builder: (BuildContext context) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                GalleryWidget(
                                                                    imageUrls:
                                                                        note.imagesUrls ??
                                                                            [])));
                                                  },
                                                  child: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                        fit: BoxFit.cover,
                                                        image: NetworkImage(
                                                            note.imagesUrls![
                                                                itemIndex]),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ))
                                    : Image.asset(
                                        'assets/images/img_placeholder.jpeg')),
                            SizedBox(height: 15),
                            Text(
                              getFormattedDate(note.createdAt),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                // fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Card(
                                    elevation: 0,
                                    color: Color.fromARGB(255, 144, 113, 229),
                                    child: Padding(
                                        padding: EdgeInsets.all(3),
                                        child: Text(
                                          getMainCategoryName(
                                              note.mainCategoryId ?? 0),
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500),
                                        ))),
                                Card(
                                    elevation: 0,
                                    color: Color.fromARGB(243, 77, 128, 147),
                                    child: Padding(
                                        padding: EdgeInsets.all(3),
                                        child: Text(
                                            getCategoryName(
                                                note.categoryId ?? 0),
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500)))),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text(note.text,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                )),
                            SizedBox(height: 10),
                            Text(
                                note.price != 0
                                    ? note.price.toString() + " TL"
                                    : '',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                )),
                            SizedBox(height: 25),
                            Text("Описание",
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(note.desc,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                )),
                            SizedBox(height: 25),
                            Text(note.phone ?? "",
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                )),
                            SizedBox(height: 25),
                            Column(
                              children: [
                                InkWell(
                                  onTap: () => openUrl(note.url ?? ""),
                                  child: Text(
                                    note.url ?? "",
                                    style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.blue),
                                  ),
                                ),
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      WidgetSpan(
                                        child: Icon(Icons.error, size: 14),
                                      ),
                                      TextSpan(
                                        text:
                                            "Перейдя по ссылке вы найдете оригинал объявления (Facebook)",
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            )

                            // ElevatedButton(
                            //     onPressed: () {
                            //       saveNote();
                            //     },
                            //     child: const Text("Save"))
                          ],
                        ),
                      ),
                    );
                  default:
                    return const CircularProgressIndicator();
                }
              } else {
                return Container();
              }
            }),
        bottomSheet: StreamBuilder(
            stream: _notesService.selectedNote.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                CloudNote note = snapshot.data as CloudNote;
                switch (snapshot.connectionState) {
                  case ConnectionState.active:
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: note.ownerUserId == userId
                          ? Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.popAndPushNamed(
                                            context, updateNoteRoute,
                                            arguments: note);
                                      },
                                      child: const Text("Редактировать")),
                                ),
                                Expanded(
                                    child: ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.red),
                                        ),
                                        onPressed: () async {
                                          final shouldDelete =
                                              await showDeleteDialog(context);
                                          if (shouldDelete) {
                                            removeNote(note);
                                          }
                                        },
                                        child: const Text("Удалить")))
                              ],
                            )
                          : Text(""),
                    );
                  default:
                    return const CircularProgressIndicator();
                }
              } else {
                return Container();
              }
            }));
  }
}
