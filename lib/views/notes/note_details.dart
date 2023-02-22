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
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/cloud/cloud_storage_constants.dart';

enum ReportCause { category, forbidden, obscene, fraud, spam, other }

class NoteDetailsView extends StatefulWidget {
  const NoteDetailsView({Key? key}) : super(key: key);

  @override
  _NoteDetailsViewState createState() => _NoteDetailsViewState();
}

class _NoteDetailsViewState extends State<NoteDetailsView> {
  // CloudNote? note;
  ReportCause? _report = ReportCause.category;
  late final FirebaseCloudStorage _notesService;
  bool _isVisible = false;
  int _current = 0;

  void showPhoneNumber() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  String? get userId => AuthService.firebase().currentUser?.id;

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

  void sendReport() {
    CloudNote? note = _notesService.selectedNote.stream.value;
    if (note != null) {
      note.reports?.add(_report!.index.toString());
      log(note.reports.toString());
      _notesService.updateNote(
          categoryId: note.categoryId!,
          documentId: note.documentId,
          text: note.text,
          desc: note.desc,
          mainCategoryId: note.mainCategoryId!,
          cityId: note.cityId!,
          price: note.price,
          shortAdd: note.shortAdd,
          imgUrls: note.imagesUrls,
          phone: note.phone,
          url: note.url,
          reports: note.reports);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // createOrGetExistingNote(context);

    final CarouselController _controller = CarouselController();
    return Scaffold(
        appBar: AppBar(
          title: const Text(""),
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 75),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 228, 228, 228),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: note.imagesUrls != null &&
                                        note.imagesUrls!.isNotEmpty
                                    ? CarouselSlider.builder(
                                        itemCount: note.imagesUrls?.length,
                                        carouselController: _controller,
                                        options: CarouselOptions(
                                          enlargeCenterPage: true,
                                          enableInfiniteScroll: false,
                                          height: 200,
                                          aspectRatio: 16 / 9,
                                          viewportFraction: 1,
                                          onPageChanged: (index, reason) {
                                            setState(() {
                                              _current = index;
                                            });
                                          },
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
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              9),
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
                            const SizedBox(
                              height: 10,
                            ),
                            Center(
                              child: AnimatedSmoothIndicator(
                                activeIndex: _current,
                                count: note.imagesUrls!.length,
                                effect: const WormEffect(
                                    dotHeight: 7,
                                    dotWidth: 7,
                                    dotColor: Colors.grey,
                                    activeDotColor: Colors.black),
                              ),
                            ),
                            // Row(
                            //   mainAxisAlignment: MainAxisAlignment.center,
                            //   children:
                            //       note.imagesUrls!.mapIndexed((entry, index) {
                            //     return GestureDetector(
                            //       onTap: () {
                            //         _controller.animateToPage(index);
                            //       },
                            //       child: Container(
                            //         width: 5.0,
                            //         height: 5.0,
                            //         margin: const EdgeInsets.symmetric(
                            //             vertical: 8.0, horizontal: 4.0),
                            //         decoration: BoxDecoration(
                            //             shape: BoxShape.circle,
                            //             color: ( Colors.black)
                            //                 .withOpacity(
                            //                     _current == index ? 0.9 : 0.4)),
                            //       ),
                            //     );
                            //   }).toList(),
                            // ),
                            const SizedBox(height: 15),
                            Text(
                              getFormattedDate(note.createdAt),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                // fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Card(
                                    elevation: 0,
                                    color: const Color.fromARGB(
                                        255, 144, 113, 229),
                                    child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Text(
                                          getMainCategoryName(
                                              note.mainCategoryId ?? 0),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500),
                                        ))),
                                Card(
                                    elevation: 0,
                                    color:
                                        const Color.fromARGB(243, 77, 128, 147),
                                    child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Text(
                                            getCategoryName(
                                                note.categoryId ?? 0),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500)))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(note.text,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                )),
                            const SizedBox(height: 10),
                            Text(
                                note.price != 0
                                    ? note.price.toString() + " TL"
                                    : '',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                )),
                            const SizedBox(height: 25),
                            const Text("Описание",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                )),
                            Text(note.desc,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                )),
                            const SizedBox(height: 25),
                            note.phone!.isNotEmpty
                                ? Visibility(
                                    visible: !_isVisible,
                                    child: ElevatedButton(
                                        onPressed: showPhoneNumber,
                                        child: const Text(
                                            'Показать номер телефона')),
                                  )
                                : Container(),
                            Visibility(
                              visible: _isVisible,
                              child: SelectableText(note.phone ?? "",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                            const SizedBox(height: 25),
                            note.url != ''
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () => openUrl(note.url ?? ""),
                                        child: Text(
                                          note.url ?? "",
                                          style: const TextStyle(
                                              decoration:
                                                  TextDecoration.underline,
                                              color: Colors.blue),
                                        ),
                                      ),
                                      RichText(
                                        text: const TextSpan(
                                          children: [
                                            WidgetSpan(
                                              child:
                                                  Icon(Icons.error, size: 12),
                                            ),
                                            TextSpan(
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color.fromARGB(
                                                      255, 95, 95, 95)),
                                              text:
                                                  "Перейдя по ссылке вы найдете оригинал объявления",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 20.0,
                                ),
                                TextButton(
                                  onPressed: () => showDialog<String>(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        AlertDialog(
                                      title: const Text(
                                        'Выберите причину',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      content: StatefulBuilder(builder:
                                          (BuildContext context,
                                              StateSetter setState) {
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            ListTile(
                                              title: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _report =
                                                          ReportCause.category;
                                                    });
                                                  },
                                                  child: const Text(
                                                      'Неверная категория')),
                                              leading: Radio<ReportCause>(
                                                value: ReportCause.category,
                                                groupValue: _report,
                                                onChanged:
                                                    (ReportCause? value) {
                                                  setState(() {
                                                    _report = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            ListTile(
                                              title: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _report =
                                                          ReportCause.forbidden;
                                                    });
                                                  },
                                                  child: const Text(
                                                      'Запрещенный товар')),
                                              leading: Radio<ReportCause>(
                                                value: ReportCause.forbidden,
                                                groupValue: _report,
                                                onChanged:
                                                    (ReportCause? value) {
                                                  setState(() {
                                                    _report = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            ListTile(
                                              title: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _report =
                                                          ReportCause.obscene;
                                                    });
                                                  },
                                                  child: const Text(
                                                      'Непристойное содержание')),
                                              leading: Radio<ReportCause>(
                                                value: ReportCause.obscene,
                                                groupValue: _report,
                                                onChanged:
                                                    (ReportCause? value) {
                                                  setState(() {
                                                    _report = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            ListTile(
                                              title: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _report =
                                                          ReportCause.fraud;
                                                    });
                                                  },
                                                  child: const Text(
                                                      'Мошенничество')),
                                              leading: Radio<ReportCause>(
                                                value: ReportCause.fraud,
                                                groupValue: _report,
                                                onChanged:
                                                    (ReportCause? value) {
                                                  setState(() {
                                                    _report = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            ListTile(
                                              title: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _report =
                                                          ReportCause.spam;
                                                    });
                                                  },
                                                  child: const Text('Спам')),
                                              leading: Radio<ReportCause>(
                                                value: ReportCause.spam,
                                                groupValue: _report,
                                                onChanged:
                                                    (ReportCause? value) {
                                                  setState(() {
                                                    _report = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            ListTile(
                                              title: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _report =
                                                          ReportCause.other;
                                                    });
                                                  },
                                                  child: const Text('Другое')),
                                              leading: Radio<ReportCause>(
                                                value: ReportCause.other,
                                                groupValue: _report,
                                                onChanged:
                                                    (ReportCause? value) {
                                                  setState(() {
                                                    _report = value;
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, 'false'),
                                          child: const Text('Отмена'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, 'true');
                                            // selectReportCause();
                                          },
                                          child: const Text('Отправить'),
                                        ),
                                      ],
                                    ),
                                  ).then((value) {
                                    if (value == 'true') {
                                      sendReport();
                                    }
                                  }),
                                  child: const Text(
                                    'Пожаловаться',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),

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
                    return note.ownerUserId == userId
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.popAndPushNamed(
                                              context, updateNoteRoute,
                                              arguments: note);
                                        },
                                        child: const Text("Редактировать")),
                                  ),
                                ),
                                Expanded(
                                    child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
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
                                      child: const Text("Удалить")),
                                ))
                              ],
                            ),
                          )
                        : const Text("");
                  default:
                    return const CircularProgressIndicator();
                }
              } else {
                return Container();
              }
            }));
  }
}

extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}
