import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'reveal.dart';
import 'question_screen.dart';

class HomeScreen extends StatelessWidget {
  /// Diteruskan ke [QuestionScreen] (lihat keterangan di sana).
  final math.Random? random;

  const HomeScreen({super.key, this.random});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, AppColors.navyDeep],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo: ikon petir cyan (berbeda dari bintang kuning codelab)
                    // dengan animasi scale elastis saat halaman dibuka.
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.cyan,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withOpacity(0.4),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          size: 68,
                          color: AppColors.navyDeep,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Judul + subjudul fade-slide masuk (tertunda via Interval).
                    Reveal(
                      delayMs: 250,
                      child: const Text(
                        'Kuis Animasi Flutter',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Reveal(
                      delayMs: 400,
                      child: Text(
                        'Praktikum 1 - Pemrograman Mobile\nUji pemahamanmu tentang animasi Flutter!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.cyan.withOpacity(0.9),
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    Reveal(
                      delayMs: 550,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                            foregroundColor: AppColors.navyDeep,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onPressed: () {
                            // Show the question screen to start the game
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return QuestionScreen(random: random);
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Mulai Kuis'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Reveal(
                      delayMs: 700,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.animation_rounded,
                            color: AppColors.cyan,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '6 soal • animasi implisit & eksplisit',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

