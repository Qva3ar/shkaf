import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mynotes/constants/routes.dart';

import 'package:flutter/material.dart';

final CATEGORIES = [
  {"id": 0, "name": "Все категории", "sub_categories": []},
  {
    "id": 1,
    "name": "Услуги",
    "sub_categories": [
      {
        "id": 2,
        "name": "Красота",
      },
      {
        "id": 3,
        "name": "Ремонт",
      },
      {
        "id": 5,
        "name": "Уборка",
      },
      {
        "id": 6,
        "name": "Прочее",
      },
    ]
  },
  {
    "id": 7,
    "name": "Недвижимость",
    "sub_categories": [
      {
        "id": 8,
        "name": "Квартиры",
      },
      {
        "id": 9,
        "name": "Аренда",
      },
      {
        "id": 10,
        "name": "Земля",
      },
      {
        "id": 11,
        "name": "Прочее",
      },
    ]
  },
  {
    "id": 12,
    "name": "Электроника",
    "sub_categories": [
      {
        "id": 13,
        "name": "Телефоны",
      },
      {
        "id": 14,
        "name": "Компьютеры",
      },
      {
        "id": 15,
        "name": "Бытовая техника",
      },
      {
        "id": 16,
        "name": "Прочее",
      },
    ]
  },
  {
    "id": 17,
    "name": "Работа",
    "sub_categories": [
      {
        "id": 18,
        "name": "Образование",
      },
      {
        "id": 19,
        "name": "Красота/фитнес",
      },
      {
        "id": 20,
        "name": "Логистика",
      },
      {
        "id": 21,
        "name": "Торговля",
      },
      {
        "id": 22,
        "name": "Домашний персонал/Сервис и быт",
      },
      {
        "id": 23,
        "name": "Прочее",
      },
    ]
  },
  {
    "id": 24,
    "name": "Машины",
    "sub_categories": [
      {
        "id": 25,
        "name": "Трансфер",
      },
      {
        "id": 26,
        "name": "Аренда",
      },
      {
        "id": 27,
        "name": "Продажа",
      },
      {
        "id": 28,
        "name": "Прочее",
      },
    ]
  }
];

final TURKEY = [
  {"id": 10, "name": "Стамбул"},
  {"id": 1, "name": "Анталия"},
];

class CategoryList extends StatelessWidget {
  const CategoryList({Key? key}) : super(key: key);

  // final tagObjsJson = jsonDecode(CATEGORIES) as List;

  @override
  Widget build(BuildContext context) {
    CATEGORIES.map((u) => log(u.toString()));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(children: [
            ListView(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                padding: const EdgeInsets.all(2),
                children: [
                  ...CATEGORIES.map((u) => Column(children: [
                        Card(
                          child: ListTile(title: Text(u['name'].toString())),
                        ),
                        ...(u['sub_categories'] as List).map((e) => Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Card(
                                color: Color.fromARGB(255, 244, 237, 196),
                                child:
                                    ListTile(title: Text(e['name'].toString())),
                              ),
                            ))
                      ]))
                ]),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(allNotes);
                },
                child: const Text('go to'))
          ])),
    );
  }
}

String getCategoryName(int categoryId) {
  for (var category in CATEGORIES) {
    for (var subCategory in (category['sub_categories'] as List)) {
      if (subCategory['id'] == categoryId) {
        return subCategory['name'];
      }
    }
  }
  return '';
}

String getMainCategoryName(int categoryId) {
  for (var category in CATEGORIES) {
    if (category['id'] == categoryId) {
      return category['name'].toString();
    }
  }
  return '';
}

int? getMainCategory(int categoryId) {
  for (var category in CATEGORIES) {
    for (var subCategory in (category['sub_categories'] as List)) {
      if (subCategory['id'] == categoryId) {
        return int.parse(category['id'].toString());
      }
    }
  }
  return null;
}

String getCityName(int cityId) {
  for (var city in TURKEY) {
    if (city['id'] == cityId) {
      return city['name'].toString();
    }
  }
  return '';
}
