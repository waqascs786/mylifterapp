enum QuestionType { trueFalse, singleChoice, multipleChoice, fillBlank }

class Quiz {
  final int id;
  final int courseId;
  final String title;
  final String description;
  final String duration;
  final int passingGrade;
  final int maxAttempts;
  final List<Question> questions;
  final int attempts;
  final int bestScore;

  const Quiz({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.duration,
    required this.passingGrade,
    required this.maxAttempts,
    required this.questions,
    this.attempts = 0,
    this.bestScore = 0,
  });

  int get totalPoints =>
      questions.fold(0, (sum, question) => sum + question.points);

  bool get canAttempt => attempts < maxAttempts;

  bool get isPassed => bestScore >= passingGrade;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as int? ?? 0,
      courseId: json['courseId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      passingGrade: json['passingGrade'] as int? ?? 0,
      maxAttempts: json['maxAttempts'] as int? ?? 0,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) =>
                  Question.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attempts: json['attempts'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'duration': duration,
      'passingGrade': passingGrade,
      'maxAttempts': maxAttempts,
      'questions': questions.map((e) => e.toJson()).toList(),
      'attempts': attempts,
      'bestScore': bestScore,
    };
  }
}

class Question {
  final int id;
  final QuestionType type;
  final String title;
  final List<QuestionOption> options;
  final String correctAnswer;
  final String explanation;
  final int points;
  final String? userAnswer;

  const Question({
    required this.id,
    required this.type,
    required this.title,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.points,
    this.userAnswer,
  });

  bool get isAnswered => userAnswer != null && userAnswer!.isNotEmpty;

  bool get isCorrect {
    if (!isAnswered) return false;
    if (type == QuestionType.multipleChoice) {
      final userSet = (userAnswer ?? '').split(',').map((e) => e.trim()).toSet();
      final correctSet =
          correctAnswer.split(',').map((e) => e.trim()).toSet();
      return userSet.containsAll(correctSet) &&
          correctSet.containsAll(userSet);
    }
    return userAnswer!.trim().toLowerCase() ==
        correctAnswer.trim().toLowerCase();
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int? ?? 0,
      type: _parseQuestionType(json['type'] as String? ?? 'singleChoice'),
      title: json['title'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) =>
                  QuestionOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      points: json['points'] as int? ?? 1,
      userAnswer: json['userAnswer'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'options': options.map((e) => e.toJson()).toList(),
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
      'userAnswer': userAnswer,
    };
  }

  static QuestionType _parseQuestionType(String type) {
    switch (type.toLowerCase()) {
      case 'truefalse':
        return QuestionType.trueFalse;
      case 'multiplechoice':
        return QuestionType.multipleChoice;
      case 'fillblank':
        return QuestionType.fillBlank;
      case 'singlechoice':
      default:
        return QuestionType.singleChoice;
    }
  }
}

class QuestionOption {
  final String id;
  final String title;
  final bool isCorrect;

  const QuestionOption({
    required this.id,
    required this.title,
    required this.isCorrect,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCorrect': isCorrect,
    };
  }
}
