import 'package:flutter/material.dart';

import '../../views/categories/category_list.dart';

Map<String, IconData> categoryIcons = {
  "Услуги": Icons.star,
  "Аренда квартир": Icons.home,
  "Работа": Icons.work,
  "Аренда Машины": Icons.directions_car,
  "Мебель и техника": Icons.weekend,
  "Бытовая техника": Icons.kitchen,
  "Электроника": Icons.phone_android,
};

Widget featuredList(
  Function? fun,
) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: FEATURED.map((item) {
        return GestureDetector(
          onTap: () => fun!(item['id'], item['isMain'], item['name']),
          child: Card(
            color: const Color.fromARGB(255, 174, 235, 177),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: Text(
                item['name'],
                style: const TextStyle(
                  fontFamily: 'Roboto', // Используем выбранный шрифт
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),

              // subtitle: Text(item['isMain'] ? "Main" : "Secondary"),
              leading: Icon(
                categoryIcons[item['name']],
                color: Colors.blue,
              ),
              // trailing: Icon(
              //   item['isMain'] ? Icons.verified : Icons.arrow_forward_ios,
              //   color: item['isMain'] ? Colors.green : Colors.grey,
              // ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
