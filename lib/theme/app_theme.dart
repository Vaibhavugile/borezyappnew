import 'package:flutter/material.dart';

class AppTheme {

  static ThemeData lightTheme = ThemeData(

    scaffoldBackgroundColor: const Color(0xFFFBF9F8),

    primaryColor: const Color(0xFF735C00),

    fontFamily: "Manrope",

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF735C00),
      onPrimary: Colors.white,
      secondary: Color(0xFFD4AF37),
      onSecondary: Colors.black,
      error: Colors.red,
      onError: Colors.white,
      background: Color(0xFFFBF9F8),
      onBackground: Color(0xFF1B1C1C),
      surface: Colors.white,
      onSurface: Color(0xFF1B1C1C),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFBF9F8),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFF735C00),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B1C1C),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0EDED),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),

  );
}