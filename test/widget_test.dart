import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quiz/main.dart';
import 'package:quiz/question_screen.dart';
import 'package:quiz/view_model.dart';

/// Kenali teks umpan balik jawaban (Benar!/Kurang tepat.).
bool _isFeedbackText(Widget widget) {
  return widget is Text &&
      ((widget.data?.startsWith('Benar') ?? false) ||
          (widget.data?.startsWith('Kurang') ?? false));
}

void main() {
  test('penilaian kuis tetap benar dan ketukan ganda diabaikan', () {
    final QuizViewModel vm = QuizViewModel(onGameOver: () {});
    final int correct = vm.currentQuestion!.correctAnswer;

    vm.checkAnswer(correct);
    expect(vm.score, 1);
    expect(vm.answerHistory, <bool>[true]);

    // Ketukan kedua pada soal yang sama tidak menambah skor.
    vm.checkAnswer((correct + 1) % 4);
    expect(vm.score, 1);
    expect(vm.answerHistory.length, 1);
    expect(vm.selectedAnswerIndex, correct);
  });

  test('riwayat jawaban salah tidak menambah skor', () {
    final QuizViewModel vm = QuizViewModel(onGameOver: () {});
    final int wrong = (vm.currentQuestion!.correctAnswer + 1) % 4;

    vm.checkAnswer(wrong);
    expect(vm.score, 0);
    expect(vm.answerHistory, <bool>[false]);
  });

  testWidgets('halaman pembuka menampilkan judul dan tombol mulai', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MainApp(random: math.Random(1234)));
    await tester.pumpAndSettle();

    expect(find.text('Kuis Animasi Flutter'), findsOneWidget);
    expect(find.text('Mulai Kuis'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsWidgets);
  });

  testWidgets('alur kuis lengkap: 6 soal -> hasil akhir -> ulangi', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MainApp(random: math.Random(1234)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai Kuis'));
    await tester.pumpAndSettle();

    expect(find.text('Kuis Animasi Flutter'), findsOneWidget);
    expect(find.text('Soal 1 / 6'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(5));

    for (int question = 1; question <= 6; question++) {
      expect(find.text('SOAL $question/6'), findsOneWidget);

      // RenderTransform tidak menambahkan dirinya ke hit-test path
      // (lihat RenderTransform.hitTest di SDK), jadi warnIfMissed dimatikan.
      await tester.tap(
        find.byKey(const ValueKey<String>('flip_0')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Umpan balik benar/salah muncul.
      expect(find.byWidgetPredicate(_isFeedbackText), findsOneWidget);
      // Progres kuis ikut bergerak.
      expect(find.text('${(question / 6 * 100).round()}%'), findsOneWidget);
      // Ikon skor berubah menjadi benar (petir) atau salah (silang).
      expect(
        find.byIcon(Icons.bolt_rounded).evaluate().isNotEmpty ||
            find.byIcon(Icons.cancel_rounded).evaluate().isNotEmpty,
        isTrue,
      );

      if (question < 6) {
        await tester.tap(find.text('Selanjutnya'));
        await tester.pumpAndSettle();
      }
    }

    // Kartu transisi hasil akhir (OpenContainer) tampil setelah soal terakhir.
    expect(find.text('Kuis selesai!'), findsOneWidget);

    await tester.pump();
    // Lewati jeda auto-buka menuju GameOverScreen (1400ms).
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.text('Kuis Selesai!'), findsOneWidget);
    expect(find.text('dari 6 benar'), findsOneWidget);

    // Mengulang kuis membuat layar kuis baru dengan skor reset.
    await tester.tap(find.text('Ulangi Kuis'));
    await tester.pumpAndSettle();

    expect(find.text('Soal 1 / 6'), findsOneWidget);
    expect(find.text('Skor: 0'), findsOneWidget);
    expect(find.text('Kuis Selesai!'), findsNothing);
  });

  testWidgets('ScoreIcon beranimasi: membesar + cyan saat jawaban benar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final QuizViewModel vm = QuizViewModel(onGameOver: () {});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ListenableBuilder(
              listenable: vm,
              builder: (context, _) => StatusBar(viewModel: vm),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Sebelum dijawab: ikon radio (belum aktif).
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);

    final AnimatedScale before = tester.widget<AnimatedScale>(
      find.byType(AnimatedScale).first,
    );
    expect(before.scale, 1.0);

    // TweenAnimationBuilder + ColorTween dipakai untuk warna ikon.
    expect(
      find.byWidgetPredicate(
        (w) => w is TweenAnimationBuilder<Color?> && w.tween is ColorTween,
      ),
      findsNWidgets(6),
    );

    vm.checkAnswer(vm.currentQuestion!.correctAnswer);
    await tester.pump();

    // Setelah benar: target skala membesar dan ikon menjadi petir.
    final AnimatedScale after = tester.widget<AnimatedScale>(
      find.byType(AnimatedScale).first,
    );
    expect(after.scale, 1.35);
    expect(
      find.descendant(
        of: find.byType(ScoreIcon),
        matching: find.byIcon(Icons.bolt_rounded),
      ),
      findsOneWidget,
    );

    await tester.pumpAndSettle();
  });
}
