import 'dart:io';
import 'dart:math' as Rand;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/extensions/buildcontext/loc.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:mynotes/utilities/generics/get_arguments.dart';
import 'package:mynotes/utilities/widgets/categories_bottom_sheet.dart';
import 'package:mynotes/views/categories/bottom_cities_sheet.dart';
import 'package:mynotes/views/categories/category_list.dart';
import 'package:mynotes/views/notes/validators/validators.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateNoteView extends StatefulWidget {
  const UpdateNoteView({Key? key}) : super(key: key);

  @override
  _CreateUpdateNoteViewState createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<UpdateNoteView> {
  CloudNote? _note;
  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _textController;
  late final TextEditingController _urlController;
  late final TextEditingController _telegramIdController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _phoneController;
  late final TextEditingController _categoryController;
  late final TextEditingController _cityController;
  late bool isFirebaseInitialized;

  FocusNode focusNode = FocusNode();

  late final currentUser;
  List<String> oldImageUrls = [];
  bool isNewImages = false;
  int? categoryId;
  int? mainCategoryId;
  int? cityId;
  bool isSaving = false;
  bool isFirstTime = true;
  bool shortAdd = false;

  DraggableScrollableController controller = DraggableScrollableController();

  final _formKey = GlobalKey<FormState>();

  var maskFormatter = MaskTextInputFormatter(
      mask: '+# (###) ###-##-##',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy);

  final ImagePicker imgpicker = ImagePicker();
  List<XFile>? imagefiles = [];
  List<String> imagesUrls = [];
  @override
  void initState() {
    currentUser = AuthService().currentUser;
    _notesService = FirebaseCloudStorage();
    _phoneController = TextEditingController();
    _textController = TextEditingController();
    _urlController = TextEditingController();
    _telegramIdController = TextEditingController();
    _descController = TextEditingController();
    _priceController = TextEditingController();
    _categoryController = TextEditingController();
    _cityController = TextEditingController();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        showModal();
      }
    });

    super.initState();
  }

  void _textControllerListener() {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textController.text;
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  bool updateShortAdd(bool value) {
    setState(() {
      shortAdd = value;
    });
    return value;
  }

  saveNote() async {
    if (_formKey.currentState!.validate()) {
      late List<String> imageUrls;
      setState(() {
        isSaving = true;
      });
      if (isNewImages) {
        if (kIsWeb) {
          imageUrls = await uploadFilesWEB(imagefiles!).catchError((e) {
            setState(() {
              isSaving = false;
            });
          });
        } else {
          imageUrls = await uploadFiles(imagefiles!).catchError((e) {
            print(e.toString());
            setState(() {
              isSaving = false;
            });
          });
        }
        await _notesService.removeImages(oldImageUrls);
      }
      if (_note != null) {
        await _notesService
            .updateNote(
              documentId: _note!.documentId,
              text: _textController.text,
              desc: _descController.text,
              phone: _phoneController.text,
              url: _urlController.text,
              telegramId: _telegramIdController.text,
              price: int.parse(_priceController.text),
              categoryId: categoryId ?? 0,
              mainCategoryId: mainCategoryId ?? 0,
              cityId: cityId ?? 0,
              imgUrls: isNewImages ? imageUrls : imagesUrls,
              shortAdd: shortAdd,
              views: _note?.views ?? 0,
            )
            .catchError((error, stackTrace) =>
                {showSnackbar(context, error.toString())});
      } else {
        try {
          await _notesService.createNewNote(
            ownerUserId: AuthService().currentUser!.uid,
            text: _textController.text,
            desc: _descController.text,
            url: _urlController.text.isNotEmpty ? _urlController.text : null,
            telegramId: _telegramIdController.text.isNotEmpty
                ? _telegramIdController.text
                : null,
            price: int.tryParse(_priceController.text) ?? 0,
            phone:
                _phoneController.text.isNotEmpty ? _phoneController.text : null,
            categoryId: categoryId ?? 0,
            mainCategoryId: mainCategoryId ?? 0,
            cityId: cityId ?? 0,
            imgUrls: isNewImages ? imageUrls : imagesUrls,
            shortAdd: shortAdd,
          );
        } catch (error) {
          print(error);
          showSnackbar(context, error.toString());
        }
      }
      setState(() {
        isSaving = false;
      });

      Navigator.pop(context);
    }
  }

  Future<List<String>> uploadFilesWEB(List<XFile> images) async {
    var imageUrls =
        await Future.wait(images.map((image) => uploadFileWEB(image)));

    return imageUrls;
  }

  Future<String> uploadFileWEB(XFile image) async {
    Uint8List data = await XFile(image.path).readAsBytes();

    var id = currentUser.id;
    final firebaseStorage = FirebaseStorage.instance;

    var snapshot = await firebaseStorage
        .ref()
        .child(
            'images/$id/${Rand.Random().nextInt(100)}${Rand.Random().nextInt(100)}${DateTime.now().millisecondsSinceEpoch}')
        .putData(data, SettableMetadata(contentType: '${image.mimeType}'));
    return await snapshot.ref.getDownloadURL();
  }

  Future<List<String>> uploadFiles(List<XFile> images) async {
    var imageUrls = await Future.wait(images.map((image) => uploadFile(image)));

    return imageUrls;
  }

  Future<String> uploadFile(XFile image) async {
    var id = AuthService().currentUser?.uid;
    final firebaseStorage = FirebaseStorage.instance;

    var snapshot = await firebaseStorage
        .ref()
        .child(
            'images/$id/${Rand.Random().nextInt(100)}${Rand.Random().nextInt(100)}${DateTime.now().millisecondsSinceEpoch}')
        .putFile(File(image.path));
    return await snapshot.ref.getDownloadURL();
  }

  openImages() async {
    final firebaseStorage = FirebaseStorage.instance;
    final imagePicker = ImagePicker();
    Iterable<XFile>? image;
    //Check Permissions
    // await Permission.photos.request();

    // var permissionStatus = await Permission.photos.status;

    // if (permissionStatus.isGranted) {
    var isAllow = false;
    if (!kIsWeb) {
      isAllow = await checkPermission();
    } else {
      isAllow = true;
    }
    if (isAllow) {
      var images = await imagePicker.pickMultiImage(imageQuality: 20);
      if (images.length > 4) {
        images = images.take(4).toList().cast<XFile>();
        const snackBar = SnackBar(
          content: Text("Ограничение в 4 фото"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      if (images.isNotEmpty) {
        isNewImages = true;
        List<String> imagesPath = [];
        for (int i = 0; i < images.length; i++) {
          imagesPath.add(images[i].path);
        }

        setState(() {
          imagefiles = images;
          imagesUrls = imagesPath;
          isNewImages = true;
        });
      }
    }

    // } else {
    //   print('Permission not granted. Try Again with permission access');
    // }
  }

  checkPermission() async {
    var status = await Permission.photos.status;

    return status.isDenied;
  }

  Future<void> createOrGetExistingNote(BuildContext context) async {
    if (isFirstTime) {
      final widgetNote = context.getArgument<CloudNote?>();
      if (widgetNote != null) {
        _note = widgetNote;
        _textController.text = widgetNote.text;
        _urlController.text = widgetNote.url ?? '';
        _descController.text = widgetNote.desc;
        _telegramIdController.text = widgetNote.telegramId ?? '';
        _priceController.text = widgetNote.price.toString();
        _phoneController.text = widgetNote.phone != "" ? widgetNote.phone! : "";
        _categoryController.text =
            '${getMainCategoryName(widgetNote.mainCategoryId ?? 0)} ${getCategoryName(widgetNote.categoryId ?? 0)}';

        _cityController.text = getCityName(widgetNote.cityId ?? 0);
        cityId = widgetNote.cityId ?? 0;
        imagesUrls = _note?.imagesUrls ?? [];
        oldImageUrls = _note?.imagesUrls ?? [];
        categoryId = widgetNote.categoryId ?? 0;
        _priceController.text = widgetNote.price.toString();
        mainCategoryId = widgetNote.mainCategoryId ?? 0;
      } else {
        _priceController.text = "0";
      }

      isFirstTime = false;
    }

    // selectCategory(widgetNote?.categoryId ?? 0);

    // return widgetNote;
  }

  void _deleteNoteIfTextIsEmpty() {
    final note = _note;
    if (_textController.text.isEmpty && note != null) {
      // _notesService.deleteNote(documentId: note.documentId);
    }
  }

  void _saveNoteIfTextNotEmpty() async {
    final note = _note;
    final text = _textController.text;
    if (note != null && text.isNotEmpty) {
      // await _notesService.updateNote(
      //     documentId: note.documentId, text: text, imageUrls: imagesUrls);
    }
  }

  selectCategory(id, isMain, mainCatId) {
    _note?.categoryId = id;

    setState(() {
      categoryId = id;
      _note = _note;
      mainCategoryId = mainCatId;
    });
    _categoryController.text =
        "${getMainCategoryName(mainCatId)} ${getCategoryName(id)}";
    Navigator.pop(context);
  }

  selectCity(int city) {
    _note?.cityId = cityId;
    setState(() {
      cityId = city;
      _note = _note;
    });
    _cityController.text = getCityName(city);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  showModal() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return bottomDetailsSheet(selectCategory, isCreation: true);
      },
    );
  }

  showCitiesModal() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      builder: (BuildContext context) {
        return bottomCitiesSheet(selectCity, 1);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    createOrGetExistingNote(context);

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          context.loc.note,
        ),
        actions: const [],
      ),
      body: Stack(children: [
        Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              child: Column(
                children: [
                  imagesUrls.isEmpty
                      ? Image.asset('assets/images/placeholder.png')
                      : CarouselSlider.builder(
                          itemCount: imagesUrls.length,
                          options: CarouselOptions(
                            enableInfiniteScroll: false,
                            height: 200,
                            aspectRatio: 16 / 9,
                            viewportFraction: 0.8,
                          ),
                          itemBuilder: (BuildContext context, int itemIndex,
                                  int pageViewIndex) =>
                              Builder(
                                builder: (BuildContext context) {
                                  return SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      // margin: EdgeInsets.symmetric(horizontal: 5.0),
                                      // decoration:BoxDecoration(color: Colors.amber),
                                      child: isNewImages && !kIsWeb
                                          ? Image.file(
                                              File(imagesUrls[itemIndex]))
                                          : kIsWeb
                                              ? Image.network(
                                                  imagesUrls[itemIndex])
                                              : Image.network(
                                                  imagesUrls[itemIndex]));
                                },
                              )),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violetLight,
                      ),
                      onPressed: () {
                        openImages();
                      },
                      child: const Text("Выберите до 4 фото")),
                  const SizedBox(height: 10),
                  RichText(
                    text: const TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(Icons.error, size: 12),
                        ),
                        TextSpan(
                          style: TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 95, 95, 95)),
                          text:
                              " Слова в заголовке будут использованы для поиска",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    maxLength: 45,
                    onChanged: (text) => setState(() {}),
                    controller: _textController,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: titleValidator,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    decoration: getInputDecoration("Заголовок"),
                  ),

                  AppInheritedWidget(
                      shortState: this,
                      child: SwitchShortAdds(
                        initialValue: _note?.shortAdd ?? false,
                      )),
                  const SizedBox(height: 10),
                  TextFormField(
                      maxLength: 1000,
                      onChanged: (text) => setState(() {}),
                      validator: descValidator,
                      controller: _descController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      decoration: getInputDecoration("Oписание")),
                  const SizedBox(height: 10),
                  TextFormField(
                      maxLength: 10,
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: getInputDecoration("Цена")),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: _urlController,
                      keyboardType: TextInputType.text,
                      decoration: getInputDecoration("Url")),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: _telegramIdController,
                      keyboardType: TextInputType.text,
                      decoration: getInputDecoration("@Telegram username")),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: getInputDecoration("Номер телефона"),
                  ),
                  const SizedBox(height: 15),
                  // getCategoryName(_note?.categoryId ?? 0)
                  // TextFormField(
                  //     // focusNode: focusNode,
                  //     onChanged: (text) => setState(() {}),
                  //     controller: _categoryController,
                  //     validator: catValidator,
                  //     decoration: getSelectDecorations(
                  //         "Категория", "Выбрать", showModal)),
                  Stack(
                    children: [
                      TextFormField(
                          enabled: false,
                          onChanged: (text) => setState(() {}),
                          controller: _categoryController,
                          validator: catValidator,
                          decoration: getSelectDecorations(
                              "Категория", "Выбрать", showModal)),
                      Align(
                        alignment:
                            AlignmentDirectional.centerEnd, // <-- SEE HERE

                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(100, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: const Text("Выбрать"),
                            onPressed: () {
                              showModal();
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Stack(
                    children: [
                      TextFormField(
                          enabled: false,
                          onChanged: (text) => setState(() {}),
                          controller: _cityController,
                          validator: cityValidator,
                          decoration: getSelectDecorations(
                              'Город', "Выбрать", showModal)),
                      Align(
                        alignment:
                            AlignmentDirectional.centerEnd, // <-- SEE HERE

                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(100, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: const Text("Выбрать"),
                            onPressed: () {
                              showCitiesModal();
                            },
                          ),
                        ),
                      )
                    ],
                  ),

                  // ElevatedButton(
                  //     onPressed: () {
                  //       showModal();
                  //     },
                  //     child: Text("Изменить"))
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: AppColors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: saveNote,
                  child: const Text("Сохранить")),
            ),
          ),
        )
      ]),
    );
  }
}

InputDecoration getInputDecoration(String title) {
  return InputDecoration(
      labelText: title,
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent, width: 1.0),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide:
            BorderSide(color: Color.fromARGB(255, 171, 171, 171), width: 1.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: Color(0xFFC72C41),
          width: 2.0,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      )
      // hintText: context.loc.start_typing_your_note,
      );
}

getSelectDecorations(String title, String btnText, Function f) {
  return InputDecoration(
    labelText: title,
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.greenAccent, width: 2.0),
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey, width: 2.0),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(
        color: Color(0xFFC72C41),
        width: 2.0,
      ),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(color: Colors.grey, width: 2.0),
    ),
  );
}

showSnackbar(context, message) {
  SnackBar snackBar = SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    content: Container(
      padding: const EdgeInsets.all(16),
      height: 90,
      decoration: const BoxDecoration(
          color: Color(0xFFC72C41),
          borderRadius: BorderRadius.all(Radius.circular(20))),
      child: Text(message),
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class SwitchShortAdds extends StatefulWidget {
  final bool initialValue;
  const SwitchShortAdds({required this.initialValue, Key? key})
      : super(key: key);

  @override
  State<SwitchShortAdds> createState() => _SwitchShortAddsState();
}

class _SwitchShortAddsState extends State<SwitchShortAdds> {
  late bool switchValue;

  @override
  void initState() {
    super.initState();
    switchValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final switchShortAddsState = AppInheritedWidget.of(context)!.shortState;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 0, 8.0, 0),
          child: Text('Короткое 14-дневное объявление'),
        ),
        Switch(
          value: switchValue,
          onChanged: (value) {
            setState(() {
              switchValue = value;
              switchShortAddsState.updateShortAdd(value);
            });
          },
        ),
      ],
    );
  }
}

class AppInheritedWidget extends InheritedWidget {
  final _CreateUpdateNoteViewState shortState;

  const AppInheritedWidget(
      {Key? key, required Widget child, required this.shortState})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(AppInheritedWidget oldWidget) {
    return shortState.shortAdd != oldWidget.shortState.shortAdd;
  }

  static AppInheritedWidget? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }
}
