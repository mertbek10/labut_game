// lib/main.dart
import 'package:flutter/material.dart';
import 'features/labut/labut_page.dart';

void main() {
  runApp(const YurtPalApp());
}

class YurtPalApp extends StatelessWidget {
  const YurtPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YurtPal',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const LabutPage(),
    );
  }
}
