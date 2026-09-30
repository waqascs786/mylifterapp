import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

enum QuestionType { trueFalse, singleChoice, multipleChoice, fillInBlank }

final _htmlTags = RegExp(r'<[^>]*>');
final _htmlEntities = {
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&#039;': "'",
  '&hellip;': '…',
  '&nbsp;': ' ',
};

String _stripHtml(String? html) {
  if (html == null || html.isEmpty) return '';
  var text = html.replaceAll(_htmlTags, ' ');
  _htmlEntities.forEach((entity, char) {
    text = text.replaceAll(entity, char);
  });
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class Quiz {
  final String id;
  final String title;
  final String? description;
  final int timeLimitMinutes;
  final double passingGrade;
  final int maxAttempts;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    required this.title,
    this.description,
    this.timeLimitMinutes = 0,
    this.passingGrade = 70.0,
    this.maxAttempts = 1,
    this.questions = const [],
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    final questions = <QuizQuestion>[];
    for (final raw in rawQuestions) {
      if (raw is! Map<String, dynamic>) continue;
      final question = QuizQuestion.fromApi(raw);
      if (question != null) questions.add(question);
    }

    final maxAttempts = (json['max_attempts'] as num?)?.toInt() ?? 0;
    final description = _stripHtml(json['description'] as String?);

    return Quiz(
      id: json['id']?.toString() ?? '',
      title: _stripHtml(json['title'] as String?),
      description: description.isEmpty ? null : description,
      timeLimitMinutes: (json['time_limit'] as num?)?.toInt() ?? 0,
      passingGrade: (json['passing_grade'] as num?)?.toDouble() ?? 70.0,
      maxAttempts: maxAttempts <= 0 ? 999 : maxAttempts,
      questions: questions,
    );
  }
}

class QuizQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final List<QuizOption> options;
  final String? correctAnswer;
  final List<String>? correctAnswers;
  final String? explanation;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.type,
    this.options = const [],
    this.correctAnswer,
    this.correctAnswers,
    this.explanation,
  });

  /// Parses a question from the app API. Returns null for question shapes the
  /// app cannot render (e.g. informational content questions).
  static QuizQuestion? fromApi(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? '').toString();
    final options = <QuizOption>[];
    for (final raw in json['options'] as List<dynamic>? ?? const []) {
      if (raw is! Map<String, dynamic>) continue;
      final text = _stripHtml(raw['title'] as String?);
      options.add(QuizOption(id: raw['id']?.toString() ?? '', text: text));
    }
    options.removeWhere((o) => o.id.isEmpty && o.text.isEmpty);

    QuestionType type;
    switch (rawType) {
      case 'multi_choice':
      case 'multiple_choice':
      case 'multipleChoice':
        if (options.isEmpty) return null;
        type = QuestionType.multipleChoice;
        break;
      case 'true_false':
      case 'trueFalse':
        type = QuestionType.trueFalse;
        break;
      case 'fill_blank':
      case 'fillInBlank':
      case 'short_answer':
        type = QuestionType.fillInBlank;
        break;
      case 'content':
        return null;
      case 'choice':
      case 'picture_choice':
      case 'single_choice':
      case 'singleChoice':
      default:
        if (options.isEmpty) return null;
        type = QuestionType.singleChoice;
        break;
    }

    final text = _stripHtml(json['title'] as String?);
    final content = _stripHtml(json['content'] as String?);

    return QuizQuestion(
      id: json['id'].toString(),
      text: content.isEmpty ? text : '$text\n$content',
      type: type,
      options: options,
      explanation: json['explanation'] != null
          ? _stripHtml(json['explanation'] as String?)
          : null,
    );
  }
}

class QuizOption {
  final String id;
  final String text;

  const QuizOption({required this.id, required this.text});

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as String,
      text: json['text'] as String,
    );
  }
}

class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final double score;
  final bool passed;
  final List<QuestionResult> questionResults;

  const QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.score,
    required this.passed,
    required this.questionResults,
  });
}

class QuestionResult {
  final QuizQuestion question;
  final dynamic userAnswer;
  final bool isCorrect;

  const QuestionResult({
    required this.question,
    this.userAnswer,
    required this.isCorrect,
  });
}

// ─── Quiz Provider ───────────────────────────────────────────────────────────

class QuizProvider extends ChangeNotifier {
  Quiz? _quiz;
  int _currentQuestionIndex = 0;
  Map<int, dynamic> _answers = {};
  int _attemptsRemaining = 1;
  Timer? _timer;
  int _timeRemainingSeconds = 0;
  bool _isQuizStarted = false;
  bool _isQuizFinished = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String? _submitError;
  QuizResult? _lastResult;

  Quiz? get quiz => _quiz;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<int, dynamic> get answers => _answers;
  bool get isQuizStarted => _isQuizStarted;
  bool get isQuizFinished => _isQuizFinished;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String? get submitError => _submitError;
  QuizResult? get lastResult => _lastResult;
  int get attemptsRemaining => _attemptsRemaining;
  bool get canStart => _quiz != null && _quiz!.questions.isNotEmpty && _attemptsRemaining > 0;

  QuizQuestion? get currentQuestion =>
      _quiz?.questions[_currentQuestionIndex];
  bool get hasPrevious => _currentQuestionIndex > 0;
  bool get hasNext =>
      _quiz != null && _currentQuestionIndex < _quiz!.questions.length - 1;
  bool get allAnswered =>
      _quiz != null && _answers.length == _quiz!.questions.length;

  int get timeRemainingSeconds => _timeRemainingSeconds;
  String get timeRemainingFormatted {
    final minutes = (_timeRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get isTimeUp => _timeRemainingSeconds <= 0 && _quiz!.timeLimitMinutes > 0;

  Future<void> loadQuiz(String quizId) async {
    _isLoading = true;
    _error = null;
    _submitError = null;
    notifyListeners();

    try {
      final data = await ApiService.instance.getQuiz(quizId);
      final quiz = Quiz.fromJson(data);
      if (quiz.questions.isEmpty) {
        _error = 'This quiz has no questions yet.';
      }
      _quiz = quiz;

      final usedAttempts = (data['attempts'] as num?)?.toInt() ?? 0;
      final remaining = quiz.maxAttempts - usedAttempts;
      _attemptsRemaining = quiz.maxAttempts >= 999
          ? 999
          : (remaining < 0 ? 0 : remaining);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load quiz';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startQuiz() {
    _isQuizStarted = true;
    _currentQuestionIndex = 0;
    _answers.clear();

    if (_quiz!.timeLimitMinutes > 0) {
      _timeRemainingSeconds = _quiz!.timeLimitMinutes * 60;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _timeRemainingSeconds--;
        if (_timeRemainingSeconds <= 0) {
          _timer?.cancel();
          unawaited(submitQuiz());
        }
        notifyListeners();
      });
    }
    notifyListeners();
  }

  void selectAnswer(int questionIndex, dynamic answer) {
    _answers[questionIndex] = answer;
    notifyListeners();
  }

  void nextQuestion() {
    if (hasNext) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (hasPrevious) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && _quiz != null && index < _quiz!.questions.length) {
      _currentQuestionIndex = index;
      notifyListeners();
    }
  }

  Future<void> submitQuiz() async {
    if (_isSubmitting || _quiz == null || _isQuizFinished) return;
    _isSubmitting = true;
    _submitError = null;
    _timer?.cancel();
    notifyListeners();

    try {
      final payload = <String, dynamic>{};
      for (int i = 0; i < _quiz!.questions.length; i++) {
        final question = _quiz!.questions[i];
        final answer = _answers[i];
        if (answer == null) continue;
        if (question.type == QuestionType.multipleChoice) {
          payload[question.id] = answer is List
              ? answer.map((e) => e.toString()).toList()
              : [answer.toString()];
        } else {
          payload[question.id] = answer.toString();
        }
      }

      final data =
          await ApiService.instance.submitQuizAnswers(_quiz!.id, payload);

      final serverResults = <String, Map<String, dynamic>>{};
      for (final raw in data['results'] as List<dynamic>? ?? const []) {
        if (raw is! Map<String, dynamic>) continue;
        serverResults[raw['question_id'].toString()] = raw;
      }

      int correct = 0;
      final results = <QuestionResult>[];
      for (int i = 0; i < _quiz!.questions.length; i++) {
        final question = _quiz!.questions[i];
        final serverResult = serverResults[question.id];
        final isCorrect = serverResult?['is_correct'] == true;
        if (isCorrect) correct++;
        results.add(QuestionResult(
          question: question,
          userAnswer: _answers[i],
          isCorrect: isCorrect,
        ));
      }

      final attemptNumber = (data['attempt_number'] as num?)?.toInt() ?? 0;
      if (_quiz!.maxAttempts < 999) {
        final remaining = _quiz!.maxAttempts - attemptNumber;
        _attemptsRemaining = remaining < 0 ? 0 : remaining;
      }

      _lastResult = QuizResult(
        totalQuestions: _quiz!.questions.length,
        correctAnswers: correct,
        score: (data['percentage'] as num?)?.toDouble() ?? 0.0,
        passed: data['passed'] == true,
        questionResults: results,
      );
      _isQuizFinished = true;
    } on ApiException catch (e) {
      _submitError = e.message;
    } catch (_) {
      _submitError = 'Failed to submit quiz. Please try again.';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void retryQuiz() {
    if (_attemptsRemaining > 0) {
      _isQuizStarted = false;
      _isQuizFinished = false;
      _currentQuestionIndex = 0;
      _answers.clear();
      _timeRemainingSeconds = 0;
      _submitError = null;
      _lastResult = null;
      _timer?.cancel();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ─── Quiz Screen ─────────────────────────────────────────────────────────────

class QuizScreen extends StatefulWidget {
  static const route = '/quiz';
  final String quizId;
  final String courseTitle;

  const QuizScreen({
    super.key,
    required this.quizId,
    required this.courseTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final QuizProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = QuizProvider();
    _provider.addListener(_onProviderUpdate);
    _provider.loadQuiz(widget.quizId);
  }

  void _onProviderUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderUpdate);
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.courseTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_provider.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.courseTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_provider.error!),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _provider.loadQuiz(widget.quizId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_provider.isSubmitting) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.courseTitle)),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Submitting your answers...'),
            ],
          ),
        ),
      );
    }

    if (_provider.submitError != null && !_provider.isQuizFinished) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.courseTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_provider.submitError!, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _provider.submitQuiz(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Submit'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Course'),
              ),
            ],
          ),
        ),
      );
    }

    if (_provider.isQuizFinished) {
      return _QuizResultScreen(provider: _provider, quizTitle: widget.courseTitle);
    }

    if (!_provider.isQuizStarted) {
      return _QuizStartScreen(provider: _provider, quizTitle: widget.courseTitle);
    }

    return _QuizPlayScreen(provider: _provider, quizTitle: widget.courseTitle);
  }
}

// ─── Quiz Start Screen ───────────────────────────────────────────────────────

class _QuizStartScreen extends StatelessWidget {
  final QuizProvider provider;
  final String quizTitle;

  const _QuizStartScreen({required this.provider, required this.quizTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiz = provider.quiz!;

    return Scaffold(
      appBar: AppBar(title: Text(quizTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.quiz,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                quiz.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (quiz.description != null) ...[
                const SizedBox(height: 12),
                Text(
                  quiz.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              _InfoCard(
                icon: Icons.help_outline,
                label: 'Questions',
                value: '${quiz.questions.length}',
              ),
              const SizedBox(height: 12),
              if (quiz.timeLimitMinutes > 0)
                _InfoCard(
                  icon: Icons.timer_outlined,
                  label: 'Time Limit',
                  value: '${quiz.timeLimitMinutes} min',
                ),
              if (quiz.timeLimitMinutes > 0) const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.grade_outlined,
                label: 'Passing Grade',
                value: '${quiz.passingGrade.toInt()}%',
              ),
              const SizedBox(height: 12),
              _InfoCard(
                icon: Icons.replay,
                label: quiz.maxAttempts >= 999
                    ? 'Attempts'
                    : 'Attempts Left',
                value: quiz.maxAttempts >= 999
                    ? 'Unlimited'
                    : '${provider.attemptsRemaining} of ${quiz.maxAttempts}',
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: provider.canStart ? provider.startQuiz : null,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    provider.canStart
                        ? 'Start Quiz'
                        : provider.attemptsRemaining <= 0
                            ? 'No Attempts Remaining'
                            : 'Start Quiz',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyLarge),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quiz Play Screen ────────────────────────────────────────────────────────

class _QuizPlayScreen extends StatelessWidget {
  final QuizProvider provider;
  final String quizTitle;

  const _QuizPlayScreen({required this.provider, required this.quizTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quiz = provider.quiz!;
    final question = provider.currentQuestion!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Quit Quiz?'),
            content: const Text(
              'Are you sure you want to quit? Your progress will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Quit'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(quizTitle),
          actions: [
            if (quiz.timeLimitMinutes > 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: provider.timeRemainingSeconds < 60
                          ? theme.colorScheme.error
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: provider.timeRemainingSeconds < 60
                              ? theme.colorScheme.onError
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          provider.timeRemainingFormatted,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: provider.timeRemainingSeconds < 60
                                ? theme.colorScheme.onError
                                : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Question indicator dots
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: quiz.questions.length,
                itemBuilder: (context, index) {
                  final isAnswered = provider.answers.containsKey(index);
                  final isCurrent = index == provider.currentQuestionIndex;
                  return GestureDetector(
                    onTap: () => provider.goToQuestion(index),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : isAnswered
                                ? theme.colorScheme.primary.withOpacity(0.3)
                                : theme.colorScheme.surfaceContainerHighest,
                        border: isCurrent
                            ? Border.all(color: theme.colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Question number and progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Question ${provider.currentQuestionIndex + 1} of ${quiz.questions.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  _QuestionTypeBadge(type: question.type),
                ],
              ),
            ),

            const Divider(),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AnswerWidget(
                      question: question,
                      questionIndex: provider.currentQuestionIndex,
                      selectedAnswer: provider.answers[provider.currentQuestionIndex],
                      onAnswer: (answer) =>
                          provider.selectAnswer(provider.currentQuestionIndex, answer),
                    ),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          provider.hasPrevious ? provider.previousQuestion : null,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (provider.hasNext)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: provider.nextQuestion,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Next'),
                      ),
                    )
                  else
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: provider.allAnswered
                            ? () => _showSubmitDialog(context)
                            : null,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Submit'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    final unanswered =
        provider.quiz!.questions.length - provider.answers.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Quiz?'),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unanswered question(s). Are you sure you want to submit?'
              : 'Are you sure you want to submit your answers?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              unawaited(provider.submitQuiz());
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

// ─── Answer Widget ───────────────────────────────────────────────────────────

class _AnswerWidget extends StatelessWidget {
  final QuizQuestion question;
  final int questionIndex;
  final dynamic selectedAnswer;
  final ValueChanged<dynamic> onAnswer;

  const _AnswerWidget({
    required this.question,
    required this.questionIndex,
    this.selectedAnswer,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.trueFalse:
        return _TrueFalseAnswer(
          options: question.options,
          selectedValue: selectedAnswer,
          onAnswer: onAnswer,
        );
      case QuestionType.singleChoice:
        return _SingleChoiceAnswer(
          options: question.options,
          selectedId: selectedAnswer,
          onAnswer: onAnswer,
        );
      case QuestionType.multipleChoice:
        return _MultipleChoiceAnswer(
          options: question.options,
          selectedIds: selectedAnswer is List<String> ? selectedAnswer : [],
          onAnswer: onAnswer,
        );
      case QuestionType.fillInBlank:
        return _FillInBlankAnswer(
          initialValue: selectedAnswer,
          onAnswer: onAnswer,
        );
    }
  }
}

class _TrueFalseAnswer extends StatelessWidget {
  final List<QuizOption> options;
  final dynamic selectedValue;
  final ValueChanged<dynamic> onAnswer;

  const _TrueFalseAnswer({
    this.options = const [],
    this.selectedValue,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final hasApiOptions = options.length >= 2;
    final trueLabel = hasApiOptions ? options[0].text : 'True';
    final falseLabel = hasApiOptions ? options[1].text : 'False';
    final trueValue = hasApiOptions ? options[0].id : 'true';
    final falseValue = hasApiOptions ? options[1].id : 'false';

    return Row(
      children: [
        Expanded(
          child: _SelectionTile(
            label: trueLabel,
            isSelected: selectedValue == trueValue,
            onTap: () => onAnswer(trueValue),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectionTile(
            label: falseLabel,
            isSelected: selectedValue == falseValue,
            onTap: () => onAnswer(falseValue),
            color: Colors.red,
          ),
        ),
      ],
    );
  }
}

class _SingleChoiceAnswer extends StatelessWidget {
  final List<QuizOption> options;
  final String? selectedId;
  final ValueChanged<String> onAnswer;

  const _SingleChoiceAnswer({
    required this.options,
    this.selectedId,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = option.id == selectedId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RadioListTile<String>(
            value: option.id,
            groupValue: selectedId,
            onChanged: (value) {
              if (value != null) onAnswer(value);
            },
            title: Text(option.text),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            tileColor: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _MultipleChoiceAnswer extends StatelessWidget {
  final List<QuizOption> options;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onAnswer;

  const _MultipleChoiceAnswer({
    required this.options,
    required this.selectedIds,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedIds.contains(option.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              final updated = List<String>.from(selectedIds);
              if (value == true) {
                updated.add(option.id);
              } else {
                updated.remove(option.id);
              }
              onAnswer(updated);
            },
            title: Text(option.text),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            tileColor: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _FillInBlankAnswer extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<String> onAnswer;

  const _FillInBlankAnswer({this.initialValue, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: initialValue ?? ''),
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      onChanged: onAnswer,
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _SelectionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionTypeBadge extends StatelessWidget {
  final QuestionType type;

  const _QuestionTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String label;
    switch (type) {
      case QuestionType.trueFalse:
        label = 'True / False';
        break;
      case QuestionType.singleChoice:
        label = 'Single Choice';
        break;
      case QuestionType.multipleChoice:
        label = 'Multiple Choice';
        break;
      case QuestionType.fillInBlank:
        label = 'Fill in Blank';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

// ─── Quiz Result Screen ──────────────────────────────────────────────────────

class _QuizResultScreen extends StatelessWidget {
  final QuizProvider provider;
  final String quizTitle;

  const _QuizResultScreen({required this.provider, required this.quizTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = provider.lastResult!;

    return Scaffold(
      appBar: AppBar(
        title: Text(quizTitle),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score circle
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: result.score / 100,
                      strokeWidth: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: result.passed ? Colors.green : theme.colorScheme.error,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${result.score.toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: result.passed ? Colors.green : theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        result.passed ? 'PASSED' : 'FAILED',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: result.passed ? Colors.green : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${result.correctAnswers}/${result.totalQuestions} correct answers',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),

            // Question breakdown
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Answers',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...result.questionResults.asMap().entries.map((entry) {
              final idx = entry.key;
              final qr = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  leading: Icon(
                    qr.isCorrect ? Icons.check_circle : Icons.cancel,
                    color: qr.isCorrect ? Colors.green : theme.colorScheme.error,
                  ),
                  title: Text(
                    'Question ${idx + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    qr.question.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question: ${qr.question.text}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your answer: ${_formatAnswer(qr.question.type, qr.userAnswer)}',
                            style: TextStyle(
                              color: qr.isCorrect ? Colors.green : theme.colorScheme.error,
                            ),
                          ),
                          if (qr.question.explanation != null) ...[
                            const Divider(height: 24),
                            Text(
                              'Explanation:',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              qr.question.explanation!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Back to Course'),
                  ),
                ),
                const SizedBox(width: 12),
                if (provider._attemptsRemaining > 0 && !result.passed)
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        provider.retryQuiz();
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Retry (${provider._attemptsRemaining} left)'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatAnswer(QuestionType type, dynamic answer) {
    if (answer == null) return 'Not answered';
    if (answer is List) {
      return answer.join(', ');
    }
    return answer.toString();
  }
}
