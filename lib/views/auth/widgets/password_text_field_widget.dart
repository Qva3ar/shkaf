import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';

Widget passwordTextField(TextEditingController controller, String hintText) {
  return TextFormField(
    style: const TextStyle(
      fontSize: 14,
      color: Colors.black54,
      fontWeight: FontWeight.bold,
    ),
    controller: controller,
    decoration: InputDecoration(
      filled: true,
      fillColor: AppColors.lightGrey,
      focusColor: AppColors.lightGrey,
      hoverColor: AppColors.lightGrey,
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.lightGrey,
        ),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.lightGrey,
        ),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.lightGrey,
        ),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.lightGrey,
        ),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      contentPadding: const EdgeInsets.only(
        left: 10,
        right: 10,
      ),
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.hintTextColor,
        fontWeight: FontWeight.w500,
      ),
    ),
    autovalidateMode: AutovalidateMode.onUserInteraction,
    autofocus: false,
    obscureText: true,
    validator: (value) => value!.isEmpty
        ? 'Введите пароль'
        : value.length < 4
            ? 'Пароль должен содержать не менее 4 символов'
            : null,
  );
}
