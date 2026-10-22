import 'dart:math' as math;

class Question {
  final String question;
  final List<String> possibleAnswers;
  final int correctAnswer;
  Question(this.question, this.possibleAnswers, this.correctAnswer);
}

class QuestionBank {
  /// Sumber acak bisa disuntikkan (mis. [math.Random] ber-seed) agar urutan
  /// soal deterministik untuk golden/screenshot test.
  QuestionBank({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  final List<Question> _questions = _createQuestions();

  bool get hasNextQuestion => _questions.isNotEmpty;
  int get remainingQuestions => _questions.length;

  Question? getRandomQuestion() {
    if (_questions.isEmpty) {
      return null;
    }

    var i = _random.nextInt(_questions.length);
    var question = _questions[i];

    _questions.removeAt(i);
    return question;
  }
}

List<Question> _createQuestions() {
  return [
    Question(
      'What class used to create custom explicit animations in Flutter?',
      ['AnimationController', 'AnimatedWidget', 'AnimatedBuilder', 'Tween'],
      0,
    ),
    Question(
      'Which widget is used to rebuild its child whenever an animation changes?',
      [
        'AnimatedContainer',
        'AnimatedBuilder',
        'AnimatedSwitcher',
        'AnimatedOpacity',
      ],
      1,
    ),
    Question(
      'What class is used to define the start and end values for an animation?',
      ['Tween', 'Curve', 'AnimationController', 'AnimatedWidget'],
      0,
    ),
    Question(
      'Which widget rebuilds with a transition when its child is replaced with a different key?',
      ['Stack', 'AnimatedSwitcher', 'Opacity', 'Hero'],
      1,
    ),
    Question(
      'What does the Curves.elasticOut curve do at the end of an animation?',
      [
        'Loops forever',
        'Moves backward',
        'Stops instantly',
        'Overshoots then settles back smoothly',
      ],
      3,
    ),
    Question(
      'Which package provides the OpenContainer container-transform transition?',
      ['http', 'path_provider', 'animations', 'provider'],
      2,
    ),
  ];
}
