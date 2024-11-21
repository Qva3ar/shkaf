import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:mynotes/constants/routes.dart';

final List<Map<String, dynamic>> FEATURED = [
  {"id": 1, "name": "Услуги", "isMain": true},
  {"id": 9, "name": "Аренда квартир", "isMain": false},
  {
    "id": 17,
    "name": "Работа",
    "isMain": true,
  },
  {"id": 26, "name": "Аренда Машины", "isMain": false},
  {"id": 31, "name": "Мебель и техника", "isMain": true},
  {"id": 12, "name": "Электроника", "isMain": true},
];

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
        "id": 29,
        "name": "Здоровье",
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
        "name": "Продажа квартир",
      },
      {
        "id": 9,
        "name": "Аренда Квартир",
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
        "id": 30,
        "name": "Ремонт",
      },
      {
        "id": 28,
        "name": "Прочее",
      },
    ]
  },
  {
    "id": 31,
    "name": "Дом",
    "sub_categories": [
      {
        "id": 32,
        "name": "Мебель",
      },
      {
        "id": 33,
        "name": "Бытовая техника",
      },
      {
        "id": 34,
        "name": "Прочее",
      },
    ]
  },
  {
    "id": 35,
    "name": "Еда",
    "sub_categories": [
      {
        "id": 36,
        "name": "На заказ",
      },
      {
        "id": 37,
        "name": "Мясо",
      },
      {
        "id": 38,
        "name": "Прочее",
      },
    ]
  },
  {
    "id": 39,
    "name": "Всё остальное",
    "sub_categories": [
      {
        "id": 40,
        "name": "Спорт",
      },
      {
        "id": 41,
        "name": "Вещи",
      },
      {
        "id": 42,
        "name": "Инструменты",
      },
      {
        "id": 43,
        "name": "Прочее",
      },
    ]
  }
];

final TURKEY = [
  {"id": 1, "name": "Анталия"},
  {"id": 10, "name": "Стамбул"},
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
                                color: const Color.fromARGB(255, 244, 237, 196),
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

String getCityName(int cityId, [List<Map<String, Object>>? turkey]) {
  for (var city in TURKEY) {
    if (city['id'] == cityId) {
      return city['name'].toString();
    }
  }
  return '';
}
