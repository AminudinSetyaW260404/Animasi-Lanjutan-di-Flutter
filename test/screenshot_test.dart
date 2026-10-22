import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quiz/app_theme.dart';
import 'package:quiz/main.dart';
import 'package:quiz/question_screen.dart';
import 'package:quiz/view_model.dart';

/// Screenshot test: menghasilkan file PNG (golden) dari frame-frame animasi
/// untuk keperluan laporan praktikum.
///
/// Jalankan dengan: flutter test --update-goldens test/screenshot_test.dart
/// (hasil PNG tersimpan di test/goldens/)
void main() {
  Future<void> setupPhone(WidgetTester tester) async {
    // 1170x2532 @3.0 = 390x844 logis (lebar sama dengan widget_test).
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Future<void> openQuiz(WidgetTester tester) async {
    await tester.pumpWidget(MainApp(random: math.Random(1234)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Kuis'));
    await tester.pumpAndSettle();
  }

  testWidgets('golden 01: halaman pembuka', (tester) async {
    await setupPhone(tester);
    await tester.pumpWidget(MainApp(random: math.Random(1234)));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01_home.png'),
    );
  });

  testWidgets('golden 02: halaman soal', (tester) async {
    await setupPhone(tester);
    await openQuiz(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02_question.png'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('golden 03: animasi jawaban - ikon skor & feedback', (
    tester,
  ) async {
    await setupPhone(tester);
    await openQuiz(tester);

    // warnIfMissed dimatikan: RenderTransform tidak masuk hit-test path (lihat SDK).
    await tester.tap(
      find.byKey(const ValueKey<String>('flip_0')),
      warnIfMissed: false,
    );
    // Tangkap di tengah animasi: skala elasticOut ikon + slide feedback.
    await tester.pump(const Duration(milliseconds: 220));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/03_answer_animation_mid.png'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('golden 04: pergantian soal - transisi & kartu terbalik', (
    tester,
  ) async {
    await setupPhone(tester);
    await openQuiz(tester);

    // warnIfMissed dimatikan: RenderTransform tidak masuk hit-test path (lihat SDK).
    await tester.tap(
      find.byKey(const ValueKey<String>('flip_0')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selanjutnya'));
    // Tangkap di tengah PageTransitionSwitcher (300ms) + flip kartu (500ms).
    await tester.pump(const Duration(milliseconds: 150));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/04_question_switch_mid.png'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('golden 05: halaman hasil akhir', (tester) async {
    await setupPhone(tester);
    await openQuiz(tester);

    for (int question = 1; question <= 6; question++) {
      // warnIfMissed dimatikan: RenderTransform tidak masuk hit-test path (lihat SDK).
    await tester.tap(
      find.byKey(const ValueKey<String>('flip_0')),
      warnIfMissed: false,
    );
      await tester.pumpAndSettle();
      if (question < 6) {
        await tester.tap(find.text('Selanjutnya'));
        await tester.pumpAndSettle();
      }
    }

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/05_game_over.png'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('golden 06: StatusBar - ikon skor di tengah animasi benar', (
    tester,
  ) async {
    await setupPhone(tester);

    final QuizViewModel vm = QuizViewModel(onGameOver: () {});
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: ListenableBuilder(
                listenable: vm,
                builder: (context, _) => StatusBar(viewModel: vm),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    vm.checkAnswer(vm.currentQuestion!.correctAnswer);
    await tester.pump();
    // Tangkap ketika AnimatedScale elasticOut & ColorTween sedang berjalan.
    await tester.pump(const Duration(milliseconds: 250));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/06_score_icon_mid_animation.png'),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('golden 07: kartu jawaban terbalik bergiliran (tengah flip)', (
    tester,
  ) async {
    await setupPhone(tester);

    final ValueNotifier<int> questionId = ValueNotifier<int>(1);
    addTearDown(questionId.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          backgroundColor: AppColors.navy,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: ValueListenableBuilder<int>(
                valueListenable: questionId,
                builder: (context, id, _) => AnswerCards(
                  questionId: id,
                  answers: const [
                    'AnimatedContainer',
                    'AnimatedBuilder',
                    'AnimatedSwitcher',
                    'AnimatedOpacity',
                  ],
                  correctAnswer: null,
                  selectedIndex: null,
                  onTapped: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Soal berganti -> CardFlipEffect berjalan bergiliran (delay 0/120/240/360).
    questionId.value = 2;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/07_card_flip_mid.png'),
    );
    await tester.pumpAndSettle();
  });
}
