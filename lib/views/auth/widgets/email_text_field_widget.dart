import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/app_colors.dart';

Widget emailTextField(TextEditingController controller) {
  return TextFormField(
    style: const TextStyle(
      fontSize: 14,
      color: Colors.black54,
      fontWeight: FontWeight.bold,
    ),
    controller: controller,
    decoration: const InputDecoration(
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
      hintText: 'Введите email',
      hintStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.hintTextColor,
        fontWeight: FontWeight.w500,
      ),
    ),
    validator: (email) {
      if (email != null && !EmailValidator.validate(email)) {
        return 'Введите правильный email';
      } else {
        return null;
      }
    },
    autovalidateMode: AutovalidateMode.onUserInteraction,
    autofocus: false,
    keyboardType: TextInputType.emailAddress,
  );
}
