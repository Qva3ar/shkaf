import 'package:flutter/material.dart';

import '../../constants/routes.dart';
import '../../views/categories/category_list.dart';
import 'featured_categories.dart';

Widget bottomDetailsSheet(Function fun, double initialSize,
    bool isMainSelectable, String selectedCat, Function? onFeaturedSelected) {
  return DraggableScrollableSheet(
    builder: (BuildContext context, ScrollController scrollController) {
      return Container(
        decoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0))),
        child: Container(
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Card(
                    elevation: 0,
                    color: Colors.transparent,
                    child: SizedBox.square(
                      child: Center(
                        child: Text(
                          selectedCat,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              onFeaturedSelected != null
                  ? featuredList(onFeaturedSelected)
                  : Container(),
              ...CATEGORIES.map((u) => Column(children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            isMainSelectable
                                ? fun(ListViewArguments(
                                    0, int.parse(u['id'].toString())))
                                : null;
                            Navigator.pop(context);
                          },
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    u['name'].toString(),
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        backgroundColor: Colors.transparent,
                                        color: Colors.black),
                                  ),
                                ),
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.arrow_right,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                )
                              ]),
                        ),
                      ),
                    ),
                    ...(u['sub_categories'] as List).map((e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            fun(ListViewArguments(
                                e['id'], int.parse(u['id'].toString())));
                          },
                          child: Card(
                            elevation: 0,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            child: ListTile(title: Text(e['name'].toString())),
                          ),
                        )))
                  ]))
            ],
          ),
        ),
      );
    },
  );
}
