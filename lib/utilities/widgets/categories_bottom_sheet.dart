import 'package:flutter/material.dart';
import 'featured_categories.dart';

Widget bottomDetailsSheet(Function? onFeaturedSelected,
    {bool isCreation = false}) {
  return DraggableScrollableSheet(
    builder: (BuildContext context, ScrollController scrollController) {
      return Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0))),
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  alignment: Alignment.center,
                  width: 80,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              // кнопка закрывания (Х)
              // Container(
              //   width: 40,
              //   height: 40,
              //   alignment: Alignment.centerRight,
              //   padding: EdgeInsets.fromLTRB(0, 10, 20, 0),
              //   child: Container(
              //       decoration: BoxDecoration(
              //           color: AppColors.unselectedTapGrey,
              //           shape: BoxShape.circle),
              //       child: IconButton(
              //         onPressed: () {},
              //         icon: Icon(
              //           Icons.close,
              //           size: 15,
              //         ),
              //         color: AppColors.white,
              //       )),
              // ),
              onFeaturedSelected != null && !isCreation
                  ? featuredGrid(onFeaturedSelected)
                  : Container(),
              onFeaturedSelected != null
                  ? featuredList(onFeaturedSelected, isCreation: isCreation)
                  : Container(),

              // старые категории
              //       ...CATEGORIES.map((u) => Column(children: [
              //             Padding(
              //               padding: const EdgeInsets.only(bottom: 5),
              //               child: Center(
              //                 child: GestureDetector(
              //                   onTap: () {
              //                     isMainSelectable
              //                         ? fun(ListViewArguments(
              //                             0, int.parse(u['id'].toString())))
              //                         : null;
              //                     Navigator.pop(context);
              //                   },
              //                   child: Row(
              //                       mainAxisAlignment: MainAxisAlignment.center,
              //                       children: [
              //                         Padding(
              //                           padding: const EdgeInsets.only(left: 10),
              //                           child: Text(
              //                             u['name'].toString(),
              //                             style: const TextStyle(
              //                                 fontSize: 20,
              //                                 fontWeight: FontWeight.bold,
              //                                 backgroundColor: Colors.transparent,
              //                                 color: Colors.black),
              //                           ),
              //                         ),
              //                         const Center(
              //                           child: Padding(
              //                             padding: EdgeInsets.only(top: 4),
              //                             child: Icon(
              //                               Icons.arrow_right,
              //                               color: Color.fromARGB(255, 0, 0, 0),
              //                             ),
              //                           ),
              //                         )
              //                       ]),
              //                 ),
              //               ),
              //             ),
              //             ...(u['sub_categories'] as List).map((e) => Padding(
              //                 padding: const EdgeInsets.symmetric(horizontal: 4.0),
              //                 child: GestureDetector(
              //                   onTap: () {
              //                     Navigator.pop(context);
              //                     fun(ListViewArguments(
              //                         e['id'], int.parse(u['id'].toString())));
              //                   },
              //                   child: Card(
              //                     elevation: 0,
              //                     color: const Color.fromARGB(255, 255, 255, 255),
              //                     child: ListTile(title: Text(e['name'].toString())),
              //                   ),
              //                 )))
              //           ]))
            ],
          ),
        ),
      );
    },
  );
}
