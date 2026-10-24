class Question {
  final int? id;
  final int? topicId;
  final String? level;
  final String? place;

  /// The square on the printed board this question belongs to, when the
  /// lecturer has pinned it to one. See the checkpoint list in the admin.
  final int? checkpoint;
  final String topic;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String landmark;
  final String emoji;
  final String? imageUrl;
  final List<String> acceptedAnswers;
  final bool isActive;

  const Question({
    this.id,
    this.topicId,
    this.level,
    this.place,
    this.checkpoint,
    required this.topic,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.landmark,
    required this.emoji,
    this.imageUrl,
    this.acceptedAnswers = const [],
    this.isActive = true,
  });

  String get correctAnswer {
    if (acceptedAnswers.isNotEmpty) return acceptedAnswers.first;
    if (options.isNotEmpty &&
        correctIndex >= 0 &&
        correctIndex < options.length) {
      return options[correctIndex];
    }
    return '';
  }

  /// Questions with choices are answered by tapping one, not by typing.
  bool get isMultipleChoice => options.length >= 2;

  Iterable<String> get allAcceptedAnswers =>
      acceptedAnswers.isNotEmpty ? acceptedAnswers : [correctAnswer];

  bool matchesAnswer(String submitted) {
    return allAcceptedAnswers.any(
      (accepted) => answersAreEquivalent(submitted, accepted),
    );
  }

  factory Question.fromApiJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>? ?? const [])
        .map((option) => option.toString())
        .toList();
    final accepted = (json['accepted_answers'] as List<dynamic>? ?? const [])
        .map((answer) => answer.toString())
        .toList();
    // The public endpoint hides the answers, so the correct choice is only
    // known for admin payloads; otherwise the server grades the submission.
    final correctIndex = options.indexWhere(
      (option) =>
          accepted.any((answer) => answersAreEquivalent(option, answer)),
    );

    return Question(
      id: json['id'] as int?,
      topicId: json['topic_id'] as int?,
      level: json['level'] as String?,
      place: json['place'] as String?,
      checkpoint: json['checkpoint'] as int?,
      topic: json['topic_name'] as String? ?? '',
      question: json['prompt'] as String? ?? '',
      options: options,
      correctIndex: correctIndex,
      landmark: json['topic_name'] as String? ?? 'i.-GB',
      emoji: '❓',
      imageUrl: json['image_url'] as String?,
      acceptedAnswers: accepted,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

bool answersAreEquivalent(String submitted, String accepted) {
  final submittedNumber = _parseNumber(submitted);
  final acceptedNumber = _parseNumber(accepted);
  if (submittedNumber != null && acceptedNumber != null) {
    return (submittedNumber - acceptedNumber).abs() < 1e-12;
  }
  return _normalizeAnswer(submitted) == _normalizeAnswer(accepted);
}

String _normalizeAnswer(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('²', '2')
    .replaceAll('³', '3')
    .replaceAll('^', '')
    .replaceAll(RegExp(r'\s+'), '');

double? _parseNumber(String value) {
  final compact = _normalizeAnswer(value);
  final fractionParts = compact.split('/');
  if (fractionParts.length == 2) {
    final numerator = double.tryParse(fractionParts[0]);
    final denominator = double.tryParse(fractionParts[1]);
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return numerator / denominator;
  }
  return double.tryParse(compact);
}

/// Topic names as published by the server; the questions themselves are only
/// ever read from the server.
const List<String> allTopics = [
  'Maths for Primary Students',
  'Maths for Secondary Students',
  'Maths for Higher Education',
  'Tourism Melaka',
];
