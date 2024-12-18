import 'package:flutter/material.dart';
import 'package:mynotes/views/categories/category_list.dart';

Widget bottomCitiesSheet(Function fun, double initialSize) {
  return DraggableScrollableSheet(
    builder: (BuildContext context, ScrollController scrollController) {
      return Container(
        padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.only(topLeft: Radius.circular(40.0), topRight: Radius.circular(40.0))),
        child: ListView(
          controller: scrollController,
          children: [
            ...TURKEY.map((u) => Column(children: [
                  Center(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => fun(u['id']),
                            child: Card(
                              color: Colors.white,
                              child: ListTile(title: Text(u['name'].toString())),
                            ),
                          ))),
                ]))
          ],
        ),
      );
    },
  );
}
