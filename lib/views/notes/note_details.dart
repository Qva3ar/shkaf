import 'dart:developer';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/helpers/ad_helper.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:mynotes/utilities/dialogs/delete_dialog.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/notes/notes_list_view.dart';
import 'package:mynotes/views/shared/gallery.dart';

import '../../services/analytics_route_obs.dart';

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
  final int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  void showPhoneNumber() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  void writeToTelegram() {
    CloudNote? note = _notesService.selectedNote.stream.value;
    if (note != null && note.telegramId!.isNotEmpty) {
      openUrl('https://t.me/${note.telegramId!}');
    }
  }

  String? get userId => AuthService.firebase().currentUser?.id;

  removeNote(CloudNote note) async {
    await _notesService.deleteNote(documentId: note.documentId);
    if (note.imagesUrls!.isNotEmpty) {
      await _notesService.removeImages(note.imagesUrls!);
    }
    Navigator.pop(context);
  }

  // Future<void> openUrl(String url) async {
  //   final _url = Uri.parse(url);
  //   if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
  //     // <--
  //     throw Exception('Could not launch $_url');
  //   }
  // }

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

  void _showInterstitialAd() {
    if (_notesService.interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _notesService.interstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _notesService.createInterstitialAd();
        _notesService.resetRecordViewCounter();
        Navigator.pop(context);
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        // _createInterstitialAd();
      },
    );
    _notesService.interstitialAd!.show();
    _notesService.interstitialAd = null;
  }

  @override
  void initState() {
    super.initState();

    FirebaseEvent.logScreenView('details');
    _notesService = FirebaseCloudStorage();

    _loadBannerAd();
    // _createInterstitialAd();
    // _notesService.selectedNote.listen((value) {
    //   log(value!.desc);
    // });
    CloudNote? note = _notesService.selectedNote.stream.value;
    // _views = _notesService.;
    // _notesService.selectedNote.listen((value) {
    //   log(value!.desc);
    // });
    log(userId.toString());

    if (note != null) {
      var views = note.views + 1;

      log(note.views.toString());
      _notesService.updateNotViews(
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
          views: views);
    }
  }

  void sendReport() {
    CloudNote? note = _notesService.selectedNote.stream.value;
    if (note != null) {
      note.reports?.add(_report!.index.toString());
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
          reports: note.reports,
          views: note.views);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // createOrGetExistingNote(context);

    final CarouselController controller = CarouselController();
    return WillPopScope(
      onWillPop: () {
        if (_notesService.showAD) {
          var viewCounter = _notesService.recordViewCounter.value;
          if (viewCounter == _notesService.maxViewsWithoutAD) {
            _showInterstitialAd();
            return Future.value(false);
          } else {
            _notesService.incrimentRecordViewCounter();
            return Future.value(true);
          }
        } else {
          return Future.value(true);
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text("ШКАФ"),
            actions: const [],
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
                                    color: const Color.fromARGB(
                                        255, 228, 228, 228),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: note.imagesUrls != null &&
                                          note.imagesUrls!.isNotEmpty
                                      ? CarouselSlider.builder(
                                          itemCount: note.imagesUrls?.length,
                                          carouselController: controller,
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
                                                builder:
                                                    (BuildContext context) {
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
                                                            BorderRadius
                                                                .circular(9),
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
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Text(
                                      getFormattedDate(note.createdAt),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        // fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.visibility,
                                    color: Colors.grey,
                                    size: 10.0,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    note.views.toString(),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                                      color: const Color.fromARGB(
                                          243, 77, 128, 147),
                                      child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: Text(
                                              getCategoryName(
                                                  note.categoryId ?? 0),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w500)))),
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
                              Text(note.price != 0 ? "${note.price} TL" : '',
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  )),

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
                              if (_isBannerAdReady && _notesService.showAD)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: _bannerAd.size.width.toDouble(),
                                      height: _bannerAd.size.height.toDouble(),
                                      child: AdWidget(ad: _bannerAd),
                                    )
                                  ],
                                ),
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
                                        fontWeight: FontWeight.w600,
                                      ))),
                              const SizedBox(height: 25),
                              note.telegramId!.isNotEmpty
                                  ? ElevatedButton(
                                      onPressed: writeToTelegram,
                                      child: const Text('Написать в Телеграм'))
                                  : Container(),
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
                                                alignment:
                                                    PlaceholderAlignment.middle,
                                                child:
                                                    Icon(Icons.error, size: 12),
                                              ),
                                              TextSpan(
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color.fromARGB(
                                                        255, 95, 95, 95)),
                                                text:
                                                    " Перейдя по ссылке вы найдете оригинал объявления",
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
                                                        _report = ReportCause
                                                            .category;
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
                                                        _report = ReportCause
                                                            .forbidden;
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
                                                    child:
                                                        const Text('Другое')),
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
                      return true
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
              })),
    );
  }
}

extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}
