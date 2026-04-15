import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/login_screen.dart';
import 'providers/user_provider.dart';
import 'screens/booking_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize Firebase
  await Firebase.initializeApp();

  /// Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('offline_cache');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Digital Atelier',

        /// GLOBAL THEME
        theme: ThemeData(

          /// BACKGROUND
          scaffoldBackgroundColor: const Color(0xFFFBF9F8),

          /// PRIMARY COLORS
          primaryColor: const Color(0xFF735C00),

          colorScheme: const ColorScheme.light(
            primary: Color(0xFF735C00),
            secondary: Color(0xFFD4AF37),
            background: Color(0xFFFBF9F8),
            surface: Colors.white,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1B1C1C),
          ),

          /// APPBAR
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFBF9F8),
            elevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: Color(0xFF735C00)),
            titleTextStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF735C00),
            ),
          ),

          /// INPUT FIELDS
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF6F3F2),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF8A8578),
            ),
          ),

          /// BUTTON STYLE
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B1C1C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),

          /// CARD STYLE (FIXED FOR FLUTTER 3.22)
          cardTheme: CardThemeData(
            color: const Color(0xFFF6F3F2),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),

          /// TEXT THEME
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B1C1C),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: Color(0xFF4D4635),
            ),
          ),
        ),

        /// START SCREEN
        home: const Booking(),
      ),
    );
  }
}