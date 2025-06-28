import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      bodySmall: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 24),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 80,
        fontWeight: FontWeight.bold,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(foregroundColor: WidgetStatePropertyAll(Colors.white)),
    ),
    popupMenuTheme: PopupMenuThemeData(iconColor: Colors.white),
    iconTheme: IconThemeData(color: Colors.white),
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    // Add other light theme customizations here
  );
}
