import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:mynotes/constants/routes.dart';

final List<Map<String, dynamic>> FEATURED = [
  {
    "id": 1,
    "name": "Услуги",
    "image": 'assets/images/services.jpg',
    "isMain": true
  },
  {
    "id": 9,
    "name": "Аренда квартир",
    "image": 'assets/images/rent.jpg',
    "isMain": false,
    "mainCatId": 7,
  },
  {
    "id": 17,
    "name": "Работа",
    "image": 'assets/images/work.jpg',
    "isMain": true,
  },
  {
    "id": 26,
    "name": "Аренда Машины",
    "image": 'assets/images/car_rent.jpg',
    "isMain": false,
    "mainCatId": 24,
  },
  {
    "id": 31,
    "name": "Мебель и техника",
    "image": 'assets/images/furniture.jpg',
    "isMain": true
  },
  {
    "id": 12,
    "name": "Электроника",
    "image": 'assets/images/electronics.jpg',
    "isMain": true
  },
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
        "icon": "assets/category_icons/beautiful_icon.svg",
      },
      {
        "id": 3,
        "name": "Ремонт",
        "icon": "assets/category_icons/repair_icon.svg",
      },
      {
        "id": 5,
        "name": "Уборка",
        "icon": "assets/category_icons/mop_icon.svg",
      },
      {
        "id": 29,
        "name": "Здоровье",
        "icon": "assets/category_icons/health_icon.svg",
      },
      {
        "id": 6,
        "name": "Прочее",
        "icon": "assets/category_icons/other_icon.svg",
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
        "icon": "assets/category_icons/apartment_icon.svg",
      },
      {
        "id": 9,
        "name": "Аренда Квартир",
        "icon": "assets/category_icons/hotel-key_icon.svg",
      },
      {
        "id": 10,
        "name": "Земля",
        "icon": "assets/category_icons/plant_icon.svg",
      },
      {
        "id": 11,
        "name": "Прочее",
        "icon": "assets/category_icons/other_icon.svg",
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
        "icon": "assets/category_icons/mobilephone_icon.svg",
      },
      {
        "id": 14,
        "name": "Компьютеры",
        "icon": "assets/category_icons/laptop_icon.svg",
      },
      {
        "id": 15,
        "name": "Бытовая техника",
        "icon": "assets/category_icons/kettle_icon.svg",
      },
      {
        "id": 16,
        "name": "Прочее",
        "icon": "assets/category_icons/other_icon.svg",
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
        "icon": "assets/category_icons/book_icon.svg",
      },
      {
        "id": 19,
        "name": "Красота/фитнес",
        "icon": "assets/category_icons/gym_icon.svg",
      },
      {
        "id": 20,
        "name": "Логистика",
        "icon": "assets/category_icons/logistic_icon.svg",
      },
      {
        "id": 21,
        "name": "Торговля",
        "icon": "assets/category_icons/shopping-cart_icon.svg",
      },
      {
        "id": 22,
        "name": "Домашний персонал/Сервис и быт",
        "icon": "assets/category_icons/home-service_icon.svg",
      },
      {
        "id": 23,
        "name": "Прочее",
        "icon": "assets/category_icons/other_icon.svg",
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
        "icon": "assets/category_icons/pickup-car_icon.svg",
      },
      {
        "id": 26,
        "name": "Аренда",
        "icon": "assets/category_icons/car-key_icon.svg",
      },
      {
        "id": 27,
        "name": "Продажа",
        "icon": "assets/category_icons/car_icon.svg",
      },
      {
        "id": 30,
        "name": "Ремонт",
        "icon": "assets/category_icons/car-repair_icon.svg",
      },
      {
        "id": 28,
        "name": "Прочее",
        "icon": "assets/category_icons/other_icon.svg",
      },
    ]
  },
  {
    "id": 31,
    "name": "Мебель и техника",
    "sub_categories": [
      {
        "id": 32,
        "name": "Мебель",
        "icon": "assets/category_icons/furniture_icon.svg",
      },
      {
        "id": 33,
        "name": "Бытовая техника",
        "icon": "assets/category_icons/kettle_icon.svg",
      },
      {
        "id": 34,
        "name": "Прочее",
        "icon": "assets/category_icons/other_icon.svg",
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
        "icon": "assets/category_icons/chiken_icon.svg",
      },
      {
        "id": 37,
        "name": "Мясо",
        "icon": "assets/category_icons/steak_icon.svg",
      },
      {
        "id": 38,
        "name": "Прочее",
        "icon": "assets/category_icons/other_icon.svg",
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
        "icon": "assets/category_icons/tennis_icon.svg",
      },
      {
        "id": 41,
        "name": "Вещи",
        "icon": "assets/category_icons/socks_icon.svg",
      },
      {
        "id": 42,
        "name": "Инструменты",
        "icon": "assets/category_icons/drill_icon.svg",
      },
      {
        "id": 43,
        "name": "Прочее",
        "icon": "assets/category_icons/other_icon.svg",
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
