import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/home_page.dart';

class SuperDuperApp extends StatelessWidget {
  const SuperDuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark));
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SuperDuper',
      theme: _buildTheme(),
      home: const HomePage(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorSchemeSeed: Colors.black,
      brightness: Brightness.dark,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
            fontSize: 30.0, color: Colors.white, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(
            fontSize: 26.0, color: Colors.white, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(
            fontSize: 20.0, color: Colors.white, fontWeight: FontWeight.bold),
        bodyMedium: TextStyle(
            fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(
            color: Color.fromARGB(255, 155, 162, 190),
            fontWeight: FontWeight.w500,
            fontSize: 14),
      ),
    );
  }
}