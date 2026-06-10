 import 'package:flutter/material.dart';

class ConstantColor {

  static Color primary = const Color(0xFF4074DA);
  static Color primaryDark = const Color(0xFF153C89);
  static Color blackColor = const Color(0xff323844);
  static Color bgColor = const Color(0xffF6F5FA);
  static Color grayColor = const Color(0xffACACAC);
  static Color whiteColor = const Color(0xffFFFFFF);
  static Color orangeColor = const Color(0xffFE8312);
  static Color greenColor = const Color(0xff0eb009);

  static Color cementColor = const Color(0xFFA7AEB5);
  static Color darkRedColor = const Color(0xFF820815);
  static Color lightBlackColor = const Color(0xFF3A3838);

  static LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}