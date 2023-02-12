import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class GalleryWidget extends StatelessWidget {
  List<String> imageUrls = [];
  GalleryWidget({Key? key, required this.imageUrls}) : super(key: key);

  PhotoViewController controller = PhotoViewController();
  Widget build(BuildContext context) {
    log(imageUrls.toString());
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          builder: (BuildContext context, int index) {
            return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrls[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3);
          },
          itemCount: imageUrls.length,
          loadingBuilder: (context, event) => Center(
            child: Container(
              width: 20.0,
              height: 20.0,
              child: const CircularProgressIndicator(),
            ),
          ),
          // backgroundDecoration: widget.backgroundDecoration,
          // onPageChanged: onPageChanged,
        ),
      ),
      bottomSheet: Container(
        width: MediaQuery.of(context).size.width,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              textStyle:
                  const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          child: const Text(
            "Закрыть",
            style: TextStyle(color: Colors.grey),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
