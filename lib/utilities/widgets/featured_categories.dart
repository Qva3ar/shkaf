import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';

import '../../views/categories/category_list.dart';

Map<String, IconData> categoryIcons = {
  "Услуги": Icons.star,
  "Аренда квартир": Icons.home,
  "Работа": Icons.work,
  "Аренда Машины": Icons.directions_car,
  "Мебель и техника": Icons.weekend,
  "Бытовая техника": Icons.kitchen,
  "Электроника": Icons.phone_android,
  "Все категории": Icons.category,
  "Недвижимость": Icons.home,
  "Машины": Icons.directions_car,
  "Дом": Icons.light,
  "Еда": Icons.fastfood,
  "Всё остальное": Icons.auto_awesome,
};

Widget featuredList(Function? fun,
    {FirebaseCloudStorage? notesService, bool isCreation = false}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
    child: Column(
      children: [
        !isCreation
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  color: AppColors.lightGrey,
                  child: ListTile(
                    title: Text('Все категории',
                        style: (AppTextStyles.s16w600
                            .copyWith(color: AppColors.black))),
                    leading: Container(
                      width: 30.0,
                      height: 30.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.violet,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.category,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    onTap: () {
                      fun!(0, true, 'Все категории');
                    },
                  ),
                ),
              )
            : Container(),
        const SizedBox(height: 10),
        Column(
          children: CATEGORIES
              .where((item) => item['id'] != 0) // Исключаем категорию с id == 0
              .toList()
              .asMap()
              .entries
              .map((entry) {
            int index = entry.key;
            var item = entry.value;
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    children: [
                      Theme(
                        data: ThemeData()
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          collapsedBackgroundColor: AppColors.lightGrey,
                          title: ListTile(
                            title: Text(
                              item['name'].toString(),
                              style: (AppTextStyles.s16w600
                                  .copyWith(color: AppColors.black)),
                            ),
                            leading: Container(
                              width: 30.0,
                              height: 30.0,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.violet,
                              ),
                              child: Center(
                                child: Icon(
                                  categoryIcons[item['name']],
                                  color: AppColors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          children: (item['sub_categories'] as List?)!
                              .map<Widget>((subcategory) {
                            return Container(
                              padding: const EdgeInsets.only(left: 17),
                              height: 50,
                              child: ListTile(
                                  title: Text(subcategory['name']),
                                  onTap: () {
                                    fun!(subcategory['id'], false, item['id']);
                                  }),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// Widget featuredList(
//   Function? fun,
// ) {
//   return Padding(
//     padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
//     child: Column(
//       children: FEATURED.map((item) {
//         return GestureDetector(
//           onTap: () => fun!(item['id'], item['isMain'], item['name']),
//           child: Card(
//             color: AppColors.lightGrey,
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: ListTile(
//               title: Text(
//                 item['name'],
//                 style: (AppTextStyles.s16w600.copyWith(color: AppColors.black)),
//               ),

//               // subtitle: Text(item['isMain'] ? "Main" : "Secondary"),
//               leading: Container(
//                 width: 30.0,
//                 height: 30.0,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: AppColors.violet,
//                 ),
//                 child: Center(
//                   child: Icon(
//                     categoryIcons[item['name']],
//                     color: AppColors.white,
//                     size: 16,
//                   ),
//                 ),
//               ),
//               trailing: Icon(
//                 Icons.arrow_drop_down,
//                 size: 30,
//               ),
//               // trailing: Icon(
//               //   item['isMain'] ? Icons.verified : Icons.arrow_forward_ios,
//               //   color: item['isMain'] ? Colors.green : Colors.grey,
//               // ),
//             ),
//           ),
//         );
//       }).toList(),
//     ),
//   );
// }

Widget featuredGrid(
  Function? fun,
) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(), // Отключаем прокрутку
      shrinkWrap:
          true, // Позволяем GridView занимать только необходимое пространство
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 колонки
        childAspectRatio: 1.3, // Соотношение сторон
      ),
      itemCount: FEATURED.length,
      itemBuilder: (context, index) {
        final category = FEATURED[index];
        return GestureDetector(
          onTap: () {
            fun!(category['id'], category['isMain'], category['mainCatId']);
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.asset(
                    category['image'].toString(),
                    fit: BoxFit.cover,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    child: Text(category['name'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        softWrap: true, // перенос текста
                        maxLines: 2 // максимальное количество строк
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
