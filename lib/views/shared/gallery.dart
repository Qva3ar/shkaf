import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class GalleryWidget extends StatefulWidget {
  List<String> imageUrls = [];
  GalleryWidget({Key? key, required this.imageUrls}) : super(key: key);

  @override
  State<GalleryWidget> createState() => _GalleryWidgetState();
}

class _GalleryWidgetState extends State<GalleryWidget> {
  int _current = 0;

  PhotoViewController controller = PhotoViewController();

  Widget build(BuildContext context) {
    log(widget.imageUrls.toString());
    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          Container(
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(widget.imageUrls[index]),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3);
              },
              itemCount: widget.imageUrls.length,
              loadingBuilder: (context, event) => Center(
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  child: const CircularProgressIndicator(),
                ),
              ),
              // backgroundDecoration: widget.backgroundDecoration,
              onPageChanged: (index) {
                setState(() {
                  _current = index;
                });
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            alignment: AlignmentDirectional.bottomCenter,
            child: AnimatedSmoothIndicator(
              activeIndex: _current,
              count: widget.imageUrls.length,
              effect: const WormEffect(
                  dotHeight: 7,
                  dotWidth: 7,
                  dotColor: Color.fromARGB(255, 82, 82, 82),
                  activeDotColor: Color.fromARGB(255, 201, 201, 201)),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            alignment: AlignmentDirectional.topEnd,
            child: IconButton(
              onPressed: (() {
                Navigator.pop(context);
              }),
              icon: const Icon(Icons.close),
              color: Colors.grey,
              iconSize: 30,
            ),
          ),
        ],
      ),
      // bottomSheet: SizedBox(
      //   width: MediaQuery.of(context).size.width,
      //   child: ElevatedButton(
      //     style: ElevatedButton.styleFrom(
      //         elevation: 0,
      //         backgroundColor: Colors.transparent,
      //         padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      //         textStyle:
      //             const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      //     child: const Text(
      //       "Закрыть",
      //       style: TextStyle(color: Colors.grey),
      //     ),
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //   ),
      // ),
    );
  }
}
