import 'package:flutter/material.dart';
import 'package:mynotes/views/categories/category_list.dart';

Widget bottomCitiesSheet(Function fun, double initialSize) {
  return DraggableScrollableSheet(
    builder: (BuildContext context, ScrollController scrollController) {
      return Container(
        color: Colors.white,
        child: ListView(
          controller: scrollController,
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Card(
                  child: Text(
                    "Выберите город",
                    style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Color.fromARGB(255, 82, 99, 255),
                        color: Colors.white),
                  ),
                ),
              ),
            ),
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
