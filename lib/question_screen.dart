import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'card_flip_effect.dart';
import 'game_over_screen.dart';
import 'model.dart';
import 'view_model.dart';

class QuestionScreen extends StatefulWidget {
  /// Opsional: RNG ber-seed untuk menjadikan urutan soal deterministik
  /// pada golden/screenshot test. Null = acak seperti biasa.
  final math.Random? random;

  const QuestionScreen({super.key, this.random});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late final QuizViewModel viewModel = QuizViewModel(
    onGameOver: _handleGameOver,
    random: widget.random,
  );

  /// Callback open milik [OpenContainer] hasil akhir, ditangkap saat closed
  /// view dibangun agar hasil kuis bisa dibuka otomatis setelah soal terakhir.
  VoidCallback? _openResults;
  bool _resultEverOpened = false;

  void _handleGameOver() {
    if (!mounted) {
      return;
    }
    setState(() {}); // Tampilkan kartu "lihat hasil" (OpenContainer).

    // Beri jeda agar umpan balik soal terakhir terbaca, lalu transisikan
    // tampilan kuis menjadi halaman hasil akhir.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted || _resultEverOpened) {
        return;
      }
      _openResults?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kuis Animasi Flutter'),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  disabledForegroundColor: AppColors.white.withOpacity(0.35),
                ),
                onPressed:
                    viewModel.hasNextQuestion && viewModel.didAnswerQuestion
                    ? () {
                        viewModel.getNextQuestion();
                      }
                    : null,
                child: const Text('Selanjutnya'),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _QuizProgress(viewModel: viewModel),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Langkah 2 & 4 - pergantian soal menggunakan
                              // PageTransitionSwitcher (mekanisme transisi
                              // yang juga dipakai langkah selanjutnya).
                              // FadeTransition + SlideTransition, ValueKey
                              // per soal, durasi 300ms.
                              PageTransitionSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder:
                                    (child, animation, secondaryAnimation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.25, 0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                child: QuestionCard(
                                  key: ValueKey<String>(
                                    viewModel.currentQuestion?.question ??
                                        'empty',
                                  ),
                                  question: viewModel.currentQuestion?.question,
                                  index: viewModel.answeredQuestionCount,
                                  total: viewModel.totalQuestions,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // AnimatedSwitcher untuk umpan balik jawaban
                              // benar/salah (fade + slide, 300ms).
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.4),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildFeedback(),
                              ),
                              const SizedBox(height: 8),
                              AnswerCards(
                                questionId: viewModel.answeredQuestionCount,
                                onTapped: (index) {
                                  viewModel.checkAnswer(index);
                                },
                                answers:
                                    viewModel.currentQuestion?.possibleAnswers ??
                                    [],
                                correctAnswer: viewModel.didAnswerQuestion
                                    ? viewModel.currentQuestion?.correctAnswer
                                    : null,
                                selectedIndex: viewModel.selectedAnswerIndex,
                              ),
                              const SizedBox(height: 8),
                              StatusBar(viewModel: viewModel),
                              if (viewModel.isFinished) ...[
                                const SizedBox(height: 16),
                                _buildResultTransition(),
                              ],
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Umpan balik benar/salah setelah jawaban dipilih.
  Widget _buildFeedback() {
    if (!viewModel.didAnswerQuestion) {
      return const SizedBox.shrink(key: ValueKey<String>('no-feedback'));
    }

    final Question? question = viewModel.currentQuestion;
    final bool isCorrect = viewModel.answerHistory.isNotEmpty
        ? viewModel.answerHistory.last
        : false;
    final String correctText =
        (question != null &&
            question.correctAnswer >= 0 &&
            question.correctAnswer < question.possibleAnswers.length)
        ? question.possibleAnswers[question.correctAnswer]
        : '';

    final Color accent = isCorrect ? AppColors.cyanDeep : AppColors.wrong;
    final String message = isCorrect
        ? 'Benar! Jawabanmu tepat +1 skor'
        : 'Kurang tepat. Jawaban benar: $correctText';

    return Container(
      key: ValueKey<String>(
        'feedback_${viewModel.answeredQuestionCount}_$isCorrect',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.bolt_rounded : Icons.info_rounded,
            color: accent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.navyDeep,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Langkah 4 - transisi OpenContainer dari tampilan kuis menuju
  /// halaman hasil akhir ([GameOverScreen]).
  Widget _buildResultTransition() {
    return OpenContainer(
      tappable: false,
      transitionDuration: const Duration(milliseconds: 550),
      closedColor: AppColors.navy,
      openColor: AppColors.navyDeep,
      closedElevation: 6,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onClosed: (_) {},
      openBuilder: (context, close) {
        _resultEverOpened = true;
        return GameOverScreen(
          score: viewModel.score,
          totalQuestions: viewModel.totalQuestions,
        );
      },
      closedBuilder: (context, openContainer) {
        _openResults = openContainer;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _resultEverOpened = true;
            openContainer();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cyan.withOpacity(0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.navyDeep,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kuis selesai!',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Skor akhir ${viewModel.score}/${viewModel.totalQuestions} - ketuk untuk melihat hasil',
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.cyan,
                  size: 30,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class QuestionCard extends StatelessWidget {
  final String? question;
  final int? index;
  final int? total;

  const QuestionCard({
    required this.question,
    this.index,
    this.total,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cyanDeep,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    index != null && total != null
                        ? 'SOAL $index/$total'
                        : 'SOAL',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.cyanDeep,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              question ?? '',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.navyDeep,
                fontSize: 21,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnswerCards extends StatelessWidget {
  final List<String> answers;
  final ValueChanged<int> onTapped;
  final int? correctAnswer;
  final int? selectedIndex;

  /// Penanda soal - dipakai [CardFlipEffect] untuk memicu animasi flip.
  final int questionId;

  const AnswerCards({
    required this.answers,
    required this.onTapped,
    required this.correctAnswer,
    required this.selectedIndex,
    required this.questionId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool answered = correctAnswer != null;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.3,
      children: List.generate(answers.length, (index) {
        final bool isCorrectChoice = answered && correctAnswer == index;
        final bool isWrongPick =
            answered && selectedIndex == index && !isCorrectChoice;
        // Key stabil per posisi agar state CardFlipEffect tidak dibuang
        // ketika soal berganti (didUpdateWidget yang menjalankan flip).
        return CardFlipEffect(
          key: ValueKey<String>('flip_$index'),
          questionId: questionId,
          delayAmount: index * 120,
          child: _AnswerCardView(
            label: String.fromCharCode(65 + index),
            answer: answers.length > index ? answers[index] : '',
            answered: answered,
            isCorrect: isCorrectChoice,
            isWrongPick: isWrongPick,
            onTap: () => onTapped(index),
          ),
        );
      }),
    );
  }
}

/// Kartu jawaban dengan transisi warna implisit (AnimatedContainer)
/// ketika pemain memilih jawaban.
class _AnswerCardView extends StatelessWidget {
  const _AnswerCardView({
    required this.label,
    required this.answer,
    required this.answered,
    required this.isCorrect,
    required this.isWrongPick,
    required this.onTap,
  });

  final String label;
  final String answer;
  final bool answered;
  final bool isCorrect;
  final bool isWrongPick;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color background = AppColors.white;
    Color accent = AppColors.navySoft;
    Color textColor = AppColors.navyDeep;
    IconData? statusIcon;

    if (isCorrect) {
      background = AppColors.cyanDeep.withOpacity(0.14);
      accent = AppColors.cyanDeep;
      statusIcon = Icons.check_circle_rounded;
    } else if (isWrongPick) {
      background = AppColors.wrong.withOpacity(0.12);
      accent = AppColors.wrong;
      textColor = AppColors.wrong;
      statusIcon = Icons.cancel_rounded;
    } else if (answered) {
      background = AppColors.background;
      accent = AppColors.pendingIcon;
      textColor = Colors.blueGrey.shade400;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent,
          width: isCorrect || isWrongPick ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    answer,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                if (statusIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(statusIcon, color: accent, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBar extends StatelessWidget {
  final QuizViewModel viewModel;

  const StatusBar({required this.viewModel, super.key});

  @override
  Widget build(BuildContext context) {
    final int total = viewModel.totalQuestions;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Soal ${viewModel.answeredQuestionCount} / $total',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.cyanDeep,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Skor: ${viewModel.score}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Langkah 1 - satu ikon skor untuk setiap soal.
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (int i = 0; i < total; i++)
                  ScoreIcon(index: i, viewModel: viewModel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ikon skor per soal (Langkah 1 - animasi implisit):
/// - [AnimatedScale] mengubah ukuran ikon, memakai [Curves.elasticOut].
/// - [TweenAnimationBuilder] + [ColorTween] mengubah warna ikon.
/// Warna/ikon dibuat sendiri (petir cyan & silang merah), bukan bintang
/// kuning seperti pada codelab.
class ScoreIcon extends StatelessWidget {
  const ScoreIcon({required this.index, required this.viewModel, super.key});

  final int index;
  final QuizViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final bool answered = index < viewModel.answerHistory.length;
    final bool isCorrect = answered && viewModel.answerHistory[index];
    final bool isCurrent =
        !answered && index == viewModel.answerHistory.length;

    final Color targetColor = answered
        ? (isCorrect ? AppColors.cyanDeep : AppColors.wrong)
        : (isCurrent ? AppColors.navySoft : AppColors.pendingIcon);
    final IconData targetIcon = answered
        ? (isCorrect ? Icons.bolt_rounded : Icons.cancel_rounded)
        : (isCurrent
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked);
    final double targetScale = isCorrect ? 1.35 : 1.0;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: AppColors.pendingIcon, end: targetColor),
      duration: const Duration(milliseconds: 600),
      // Warna memakai curve halus; elasticOut dipakai pada skala di bawah
      // (elasticOut pada ColorTween bisa menghasilkan nilai channel di
      // luar rentang 0-255 saat overshoot).
      curve: Curves.easeOutCubic,
      builder: (context, color, child) => AnimatedScale(
        scale: targetScale,
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        child: Icon(targetIcon, color: color ?? targetColor, size: 26),
      ),
    );
  }
}

/// Animasi tambahan: bar progres kuis yang bergerak halus setiap kali
/// soal terjawab, lengkap dengan persentase.
class _QuizProgress extends StatelessWidget {
  const _QuizProgress({required this.viewModel});

  final QuizViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final double fraction = viewModel.answeredFraction;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progres Kuis',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${(fraction * 100).round()}%',
              style: const TextStyle(
                color: AppColors.cyanDeep,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fraction),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 12,
              color: AppColors.cyanDeep,
              backgroundColor: AppColors.navy.withOpacity(0.10),
            ),
          ),
        ),
      ],
    );
  }
}
