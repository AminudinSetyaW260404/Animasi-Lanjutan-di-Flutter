import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'question_screen.dart';
import 'reveal.dart';

/// Halaman hasil akhir kuis (target transisi [OpenContainer]).
///
/// Menampilkan skor akhir dengan animasi count-up dan cincin progres,
/// serta tombol untuk mengulang kuis atau kembali ke beranda.
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  final int score;
  final int totalQuestions;

  double get _percent =>
      totalQuestions == 0 ? 0 : (score / totalQuestions).clamp(0.0, 1.0);

  String get _message {
    if (_percent >= 0.8) {
      return 'Luar biasa! Kamu hampir sempurna.';
    }
    if (_percent >= 0.5) {
      return 'Kerja bagus! Terus tingkatkan lagi.';
    }
    return 'Jangan menyerah, coba sekali lagi!';
  }

  void _restartQuiz(BuildContext context) {
    // Kembali ke beranda lalu mulai kuis baru dengan view model segar.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const QuestionScreen()),
      (route) => route.isFirst,
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, AppColors.navyDeep],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Reveal(
                      delayMs: 0,
                      child: Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.cyan,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Reveal(
                      delayMs: 120,
                      child: Text(
                        'Kuis Selesai!',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Animasi tambahan: count-up skor akhir + cincin progres.
                    Reveal(
                      delayMs: 240,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: _percent),
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => CustomPaint(
                          size: const Size(196, 196),
                          painter: _ScoreRingPainter(progress: value),
                          child: SizedBox(
                            width: 196,
                            height: 196,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TweenAnimationBuilder<int>(
                                  tween: IntTween(begin: 0, end: score),
                                  duration:
                                      const Duration(milliseconds: 1200),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, _) => Text(
                                    '$value',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 56,
                                      fontWeight: FontWeight.w800,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                Text(
                                  'dari $totalQuestions benar',
                                  style: const TextStyle(
                                    color: AppColors.cyan,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Reveal(
                      delayMs: 420,
                      child: Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Reveal(
                      delayMs: 560,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.cyan,
                            foregroundColor: AppColors.navyDeep,
                          ),
                          onPressed: () => _restartQuiz(context),
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Ulangi Kuis'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delayMs: 680,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.white,
                            side: const BorderSide(color: AppColors.cyan),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => _goHome(context),
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Beranda'),
                        ),
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


/// Pelukis cincin progres skor (animasi dijalankan oleh TweenAnimationBuilder).
class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 14;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide - stroke) / 2;

    final Paint background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.white.withOpacity(0.15);
    canvas.drawCircle(center, radius, background);

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.cyan;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
