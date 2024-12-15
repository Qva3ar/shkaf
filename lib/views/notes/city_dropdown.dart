import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';
import 'package:mynotes/constants/app_text_styles.dart';
import 'package:mynotes/views/categories/category_list.dart';

class CityDropdown extends StatelessWidget {
  final int selectedCityId;
  final Function(int) onCityChanged;

  const CityDropdown({
    Key? key,
    required this.selectedCityId,
    required this.onCityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: selectedCityId,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 9),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        filled: true,
        fillColor: AppColors.lightGrey,
      ),
      items: TURKEY
          .map((city) => DropdownMenuItem<int>(
                value: city['id'] as int,
                child: Text(
                  city['name'] as String,
                  style: AppTextStyles.s17w400.copyWith(color: AppColors.unselectedTextGrey),
                ),
              ))
          .toList(),
      icon: const Icon(
        Icons.arrow_drop_down_rounded,
        size: 25,
        color: AppColors.darkGrey,
      ),
      onChanged: (value) {
        if (value != null) {
          onCityChanged(value);
        }
      },
    );
  }
}
