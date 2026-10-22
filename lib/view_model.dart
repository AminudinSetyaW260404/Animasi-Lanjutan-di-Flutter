import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'model.dart';

class QuizViewModel extends ChangeNotifier {
  final QuestionBank _questionBank;
  final VoidCallback onGameOver;
  late final int totalQuestions;
  Question? currentQuestion;
  int answeredQuestionCount = 0;
  int score = 0;
  bool didAnswerQuestion = false;

  /// Riwayat benar/salah untuk setiap soal yang sudah dijawab.
  /// Index 0 = soal pertama, dipakai oleh [StatusBar] untuk animasi ikon skor.
  final List<bool> answerHistory = <bool>[];

  /// Indeks jawaban yang dipilih pemain pada soal saat ini (null = belum).
  /// Hanya untuk keperluan tampilan, tidak memengaruhi penilaian.
  int? selectedAnswerIndex;

  bool get hasNextQuestion => answeredQuestionCount < totalQuestions;

  /// Kuis selesai: soal terakhir sudah dijawab.
  bool get isFinished => didAnswerQuestion && !hasNextQuestion;

  /// Fraksi soal yang sudah dijawab (0.0 - 1.0) untuk indikator progres.
  double get answeredFraction =>
      totalQuestions == 0 ? 0 : answerHistory.length / totalQuestions;

  QuizViewModel({required this.onGameOver, math.Random? random})
    : _questionBank = QuestionBank(random: random) {
    totalQuestions = _questionBank.remainingQuestions;
    getNextQuestion();
  }

  void getNextQuestion() {
    if (_questionBank.hasNextQuestion) {
      currentQuestion = _questionBank.getRandomQuestion();
      answeredQuestionCount++;
    }

    didAnswerQuestion = false;
    selectedAnswerIndex = null;

    notifyListeners();
  }

  void checkAnswer(int selectedIndex) {
    // Jawaban sudah dipilih untuk soal ini - abaikan ketukan berikutnya
    // agar skor tidak berubah ganda dan onGameOver tidak terpanggil dua kali.
    if (didAnswerQuestion) {
      return;
    }

    final bool isCorrect = currentQuestion?.correctAnswer == selectedIndex;
    if (isCorrect) {
      score++;
    }
    answerHistory.add(isCorrect);
    selectedAnswerIndex = selectedIndex;
    didAnswerQuestion = true;

    if (!_questionBank.hasNextQuestion) {
      onGameOver();
    }

    notifyListeners();
  }
}
