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
import 'package:mynotes/utilities/generics/get_arguments.dart';
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/cloud/cloud_storage_constants.dart';

class CreateNoteView extends StatefulWidget {
  const CreateNoteView({Key? key}) : super(key: key);

  @override
  _CreateUpdateNoteViewState createState() => _CreateUpdateNoteViewState();
}

class _CreateUpdateNoteViewState extends State<CreateNoteView> {
  CloudNote? _note;
  late final FirebaseCloudStorage _notesService;
  late final TextEditingController _textController;
  late final TextEditingController _descController;
  final currentUser = AuthService.firebase().currentUser!;
  bool isNewImages = false;

  final imagePlaceholderPath =
      const Image(image: AssetImage('images/img_placeholder.png'));

  final ImagePicker imgpicker = ImagePicker();
  List<XFile>? imagefiles = [];
  List<String> imagesUrls = [];
  @override
  void initState() {
    _notesService = FirebaseCloudStorage();
    _textController = TextEditingController();
    _descController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() {
    final note = _note;
    if (note == null) {
      return;
    }
    final text = _textController.text;
    // await _notesService
    //     .updateNote(documentId: note.documentId, text: text, imageUrls: []);
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  saveNote() async {
    log("upload");
    var imageUrls = uploadFiles(imagefiles!);
    imageUrls.then((value) async => {});

    Navigator.popAndPushNamed(context, allNotes);
  }

  Future<List<String>> uploadFiles(List<XFile> _images) async {
    var imageUrls =
        await Future.wait(_images.map((_image) => uploadFile(_image)));

    return imageUrls;
  }

  Future<String> uploadFile(XFile _image) async {
    var id = currentUser.id;
    final _firebaseStorage = FirebaseStorage.instance;

    var snapshot = await _firebaseStorage
        .ref()
        .child('images/$id/' + DateTime.now().millisecondsSinceEpoch.toString())
        .putFile(File(_image.path));
    return await snapshot.ref.getDownloadURL();
  }

  openImages() async {
    final _firebaseStorage = FirebaseStorage.instance;
    final _imagePicker = ImagePicker();
    List<XFile>? image;
    //Check Permissions
    await Permission.photos.request();

    var permissionStatus = await Permission.photos.status;

    if (permissionStatus.isGranted) {
      var images = await _imagePicker.pickMultiImage();

      if (images != null && images.length > 0) {
        setState(() {
          imagefiles = images;
        });
        isNewImages = true;
        List<String> imagesPath = [];
        for (int i = 0; i < images.length; i++) {
          imagesPath.add(images[i].path);
        }
        setState(() {
          imagesUrls = imagesPath;
        });
      }
    } else {
      print('Permission not granted. Try Again with permission access');
    }
  }

  Future<CloudNote?> createOrGetExistingNote(BuildContext context) async {
    final widgetNote = context.getArgument<CloudNote>();
    // log(widgetNote!.text.toString());
    if (widgetNote != null) {
      _note = widgetNote;
      _textController.text = widgetNote.text;
      _descController.text = widgetNote.desc;

      imagesUrls = _note!.imagesUrls ?? [];
      setState(() {
        imagesUrls = _note!.imagesUrls ?? [];
      });
    }

    return widgetNote;

    // final existingNote = _note;
    // if (existingNote != null) {
    //   return existingNote;
    // }
    // final currentUser = AuthService.firebase().currentUser!;
    // final userId = currentUser.id;
    // final newNote = await _notesService.createNewNote(ownerUserId: userId);
    // _note = newNote;
    // imagesUrls = _note!.imageUrls ?? [];
    // setState(() {
    //   imagesUrls = _note!.imageUrls ?? [];
    // });
    // return newNote;
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

  @override
  void dispose() {
    _deleteNoteIfTextIsEmpty();
    _saveNoteIfTextNotEmpty();
    _textController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.loc.note,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final text = _textController.text;
              if (_note == null || text.isEmpty) {
                await showCannotShareEmptyNoteDialog(context);
              } else {
                // Share.share(text);
              }
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: FutureBuilder(
        future: createOrGetExistingNote(context),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _setupTextControllerListener();
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    CarouselSlider.builder(
                        itemCount: imagesUrls.length,
                        options: CarouselOptions(
                          height: 200,
                          aspectRatio: 16 / 9,
                          viewportFraction: 0.8,
                        ),
                        itemBuilder: (BuildContext context, int itemIndex,
                                int pageViewIndex) =>
                            Builder(
                              builder: (BuildContext context) {
                                return Container(
                                    width: MediaQuery.of(context).size.width,
                                    // margin: EdgeInsets.symmetric(horizontal: 5.0),
                                    // decoration:BoxDecoration(color: Colors.amber),
                                    child: imagesUrls.isNotEmpty
                                        ? Image.file(
                                            new File(imagesUrls[itemIndex]))
                                        : null);
                              },
                            )),
                    TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: context.loc.start_typing_your_note,
                      ),
                    ),
                    TextField(
                      controller: _descController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: context.loc.start_typing_your_note,
                      ),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          openImages();
                        },
                        child: const Text("Open Images")),
                    ElevatedButton(
                        onPressed: () {
                          saveNote();
                        },
                        child: const Text("Save"))
                  ],
                ),
              );

            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
