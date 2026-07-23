import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AvatarApp());
}

class AvatarApp extends StatelessWidget {
  const AvatarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '나만의 캐릭터 만들기',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    const sage = Color(0xFF4F6F5C);
    const sageLight = Color(0xFFDCE7DF);
    const bg = Color(0xFFF3F6F1);
    const ink = Color(0xFF26302A);
    const inkSoft = Color(0xFF5B6960);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: sage,
      brightness: Brightness.light,
      primary: sage,
      secondary: sageLight,
      surface: Colors.white,
      onSurface: ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          color: inkSoft,
          height: 1.6,
          fontSize: 14.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: sage,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: inkSoft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}
