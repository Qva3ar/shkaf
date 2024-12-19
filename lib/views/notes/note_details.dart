import 'dart:developer';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/typography.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/user_service.dart';
import 'package:mynotes/views/notes/update_note_view.dart';
import 'package:mynotes/views/widgets/dynamic_contact_btns.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/helpers/ad_helper.dart';
import 'package:mynotes/utilities/helpers/utilis-funs.dart';
import 'package:mynotes/utilities/dialogs/delete_dialog.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/shared/gallery.dart';

import '../../services/analytics_route_obs.dart';

enum ReportCause { category, forbidden, obscene, fraud, spam, other }

class NoteDetailsView extends StatefulWidget {
  final CloudNote note;
  BuildContext? context;
  NoteDetailsView({Key? key, required this.note, BuildContext? context})
      : super(key: key);

  @override
  _NoteDetailsViewState createState() => _NoteDetailsViewState();
}

class _NoteDetailsViewState extends State<NoteDetailsView> {
  late CloudNote note;
  ReportCause? _report = ReportCause.category;
  late final FirebaseCloudStorage _notesService;
  late final UserService userService;

  bool _isVisible = false;
  int _current = 0;
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  void showPhoneNumber() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  String? get userId => AuthService().currentUser?.uid;

  Future<void> removeNote(CloudNote note) async {
    try {
      // Удаление документа из базы данных
      await _notesService.deleteNote(documentId: note.documentId);

      // Удаление изображений, если они существуют
      if (note.imagesUrls != null && note.imagesUrls!.isNotEmpty) {
        await _notesService.removeImages(note.imagesUrls!);
      }

      // Закрытие текущего экрана
      Navigator.pop(
          widget.context ?? context, DetailsViewAuguments(note.documentId));
    } catch (e) {
      // Логирование и обработка ошибки
      showSnackbar(context, 'Ошибка при удалении заметки: $e');
    }
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
      },
    );
    _notesService.interstitialAd!.show();
    _notesService.interstitialAd = null;
  }

  @override
  void initState() {
    super.initState();
    note = widget.note;

    FirebaseEvent.logScreenView('details');
    _notesService = FirebaseCloudStorage();
    userService = UserService();
    _loadBannerAd();

    log(userId.toString());

    var views = note.views + 1;

    log(note.views.toString());
    _notesService.updateNotViews(
        categoryId: note.categoryId!,
        documentId: note.documentId,
        text: note.text,
        desc: note.desc,
        mainCategoryId: note.mainCategoryId ?? 0, //TODO
        cityId: note.cityId!,
        price: note.price,
        shortAdd: note.shortAdd,
        imgUrls: note.imagesUrls,
        phone: note.phone,
        url: note.url,
        views: views);
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

    CarouselSliderController controller = CarouselSliderController();
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: AuthService().currentUser != null
              ? null
              : DynamicContactButtons(
                  telegramId: note.telegramId,
                  phoneNumber: note.phone, // Если нет номера телефона
                  link: note.url, // Если нет ссылки
                ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 75),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      note.mainCategoryId != null
                          ? Text(
                              getMainCategoryName(note.mainCategoryId!),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14, // Размер текста
                                color: Colors.grey, // Цвет текста
                              ),
                            )
                          : Container(),
                      const SizedBox(
                        width: 8,
                      ),
                      note.categoryId != null
                          ? Text(
                              getCategoryName(note.categoryId!),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14, // Размер текста
                                color: Colors.grey, // Цвет текста
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Container(
                      decoration: BoxDecoration(
                        // color: const Color.fromARGB(255, 228, 228, 228),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: note.imagesUrls != null &&
                              note.imagesUrls!.isNotEmpty
                          ? Stack(
                              children: [
                                CarouselSlider.builder(
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
                                            int itemIndex, int pageViewIndex) =>
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
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(9),
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
                                        )),
                                Positioned(
                                  bottom: 8,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Логика для добавления в избранное
                                    },
                                    child: Container(
                                      width: 25,
                                      height: 25,
                                      decoration: const BoxDecoration(
                                        color: Colors.transparent,
                                      ),
                                      child: const Icon(
                                        Icons.favorite_border,
                                        size: 25,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Image.asset('assets/images/img_placeholder.jpeg')),
                  const SizedBox(
                    height: 10,
                  ),
                  note.imagesUrls != null && note.imagesUrls!.isNotEmpty
                      ? Center(
                          child: AnimatedSmoothIndicator(
                            activeIndex: _current,
                            count: note.imagesUrls?.length ?? 1,
                            effect: const WormEffect(
                                dotHeight: 7,
                                dotWidth: 7,
                                dotColor: Colors.grey,
                                activeDotColor: Colors.black),
                          ),
                        )
                      : Container(),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.text,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 10),
                        note.price != 0
                            ? Text(note.price != 0 ? "${note.price} TL" : '',
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ))
                            : Container(),
                        const Text("Описание",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            )),
                        Text(note.desc,
                            style: Typogaphy.Regular.copyWith(
                              color: Colors.black,
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  if (_notesService.showAD)
                    _isBannerAdReady
                        ? Center(
                            child: SizedBox(
                              width: _bannerAd.size.width.toDouble(),
                              height: _bannerAd.size.height.toDouble(),
                              child: AdWidget(ad: _bannerAd),
                            ),
                          )
                        : const SizedBox(
                            height:
                                50, // Место под рекламу, если она ещё не загрузилась
                          ),
                  const SizedBox(height: 25),
                  // note.phone!.isNotEmpty
                  //     ? Visibility(
                  //         visible: !_isVisible,
                  //         child: ElevatedButton(
                  //             onPressed: showPhoneNumber,
                  //             child: const Text('Показать номер телефона')),
                  //       )
                  //     : Container(),
                  // Visibility(
                  //     visible: _isVisible,
                  //     child: SelectableText(note.phone ?? "",
                  //         style: const TextStyle(
                  //           fontSize: 24,
                  //           fontWeight: FontWeight.w600,
                  //         ))),

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
                          builder: (BuildContext context) => AlertDialog(
                            title: const Text(
                              'Выберите причину',
                              style: TextStyle(color: Colors.red),
                            ),
                            content: StatefulBuilder(builder:
                                (BuildContext context, StateSetter setState) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    title: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _report = ReportCause.category;
                                          });
                                        },
                                        child:
                                            const Text('Неверная категория')),
                                    leading: Radio<ReportCause>(
                                      value: ReportCause.category,
                                      groupValue: _report,
                                      onChanged: (ReportCause? value) {
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
                                            _report = ReportCause.forbidden;
                                          });
                                        },
                                        child: const Text('Запрещенный товар')),
                                    leading: Radio<ReportCause>(
                                      value: ReportCause.forbidden,
                                      groupValue: _report,
                                      onChanged: (ReportCause? value) {
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
                                            _report = ReportCause.obscene;
                                          });
                                        },
                                        child: const Text(
                                            'Непристойное содержание')),
                                    leading: Radio<ReportCause>(
                                      value: ReportCause.obscene,
                                      groupValue: _report,
                                      onChanged: (ReportCause? value) {
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
                                            _report = ReportCause.fraud;
                                          });
                                        },
                                        child: const Text('Мошенничество')),
                                    leading: Radio<ReportCause>(
                                      value: ReportCause.fraud,
                                      groupValue: _report,
                                      onChanged: (ReportCause? value) {
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
                                            _report = ReportCause.spam;
                                          });
                                        },
                                        child: const Text('Спам')),
                                    leading: Radio<ReportCause>(
                                      value: ReportCause.spam,
                                      groupValue: _report,
                                      onChanged: (ReportCause? value) {
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
                                            _report = ReportCause.other;
                                          });
                                        },
                                        child: const Text('Другое')),
                                    leading: Radio<ReportCause>(
                                      value: ReportCause.other,
                                      groupValue: _report,
                                      onChanged: (ReportCause? value) {
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
                  //     child: const Text("Save"))ππ
                ],
              ),
            ),
          ),
          bottomSheet: StreamBuilder(
              stream: _notesService.selectedNote.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  CloudNote note = snapshot.data as CloudNote;
                  switch (snapshot.connectionState) {
                    case ConnectionState.active:
                      return note.ownerUserId == userService.currentUser?.uid
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
                                              WidgetStateProperty.all<Color>(
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
