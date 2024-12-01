import 'package:flutter/material.dart';

const String _FONT_FAMILY = 'Montserrat';

class Typogaphy {
  static TextStyle Black = const TextStyle(fontFamily: _FONT_FAMILY, fontWeight: FontWeight.w900);

  static TextStyle ExtraBold =
      const TextStyle(fontFamily: _FONT_FAMILY, fontWeight: FontWeight.w800);

  static TextStyle Bold = const TextStyle(fontFamily: _FONT_FAMILY, fontWeight: FontWeight.w700);

  static TextStyle SemiBold =
      const TextStyle(fontFamily: _FONT_FAMILY, fontWeight: FontWeight.w600);

  static TextStyle Medium = const TextStyle(fontFamily: _FONT_FAMILY, fontWeight: FontWeight.w500);

  static TextStyle Regular = const TextStyle(fontFamily: _FONT_FAMILY, fontWeight: FontWeight.w400);

  static TextStyle Thin = const TextStyle(fontFamily: _FONT_FAMILY, fontWeight: FontWeight.w300);

  static TextStyle Light = const TextStyle(fontFamily: _FONT_FAMILY, fontWeight: FontWeight.w200);

  static TextStyle ExtraLight =
      const TextStyle(fontFamily: _FONT_FAMILY, fontWeight: FontWeight.w100);
}
