import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'home_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  /// Opsional: RNG ber-seed agar urutan soal deterministik pada test.
  final math.Random? random;

  const MainApp({super.key, this.random});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kuis Animasi Flutter',
      theme: AppTheme.light,
      home: HomeScreen(random: random),
    );
  }
}
