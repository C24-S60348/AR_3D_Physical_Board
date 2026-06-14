class Question {
  final int? id;
  final int? topicId;
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

  Iterable<String> get allAcceptedAnswers =>
      acceptedAnswers.isNotEmpty ? acceptedAnswers : [correctAnswer];

  bool matchesAnswer(String submitted) {
    return allAcceptedAnswers.any(
      (accepted) => answersAreEquivalent(submitted, accepted),
    );
  }

  factory Question.fromApiJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int?,
      topicId: json['topic_id'] as int?,
      topic: json['topic_name'] as String? ?? '',
      question: json['prompt'] as String? ?? '',
      options: const [],
      correctIndex: 0,
      landmark: json['topic_name'] as String? ?? 'i.-GB',
      emoji: '❓',
      imageUrl: json['image_url'] as String?,
      acceptedAnswers: (json['accepted_answers'] as List<dynamic>? ?? const [])
          .map((answer) => answer.toString())
          .toList(),
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

String _normalizeAnswer(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

double? _parseNumber(String value) {
  final compact = _normalizeAnswer(value).replaceAll(' ', '');
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

final Map<String, List<Question>> questionsByTopic = {
  'Maths for Primary Students': [
    const Question(
      topic: 'Maths for Primary Students',
      question: 'Siapakah pengasas Kesultanan Melaka?',
      options: ['Parameswara', 'Sultan Mahmud Shah', 'Hang Tuah', 'Tun Perak'],
      correctIndex: 0,
      landmark: 'Muzium Kesultanan Melaka',
      emoji: '👑',
    ),
    const Question(
      topic: 'Maths for Primary Students',
      question: 'Pada tahun berapa Portugis menakluki Melaka?',
      options: ['1511', '1641', '1824', '1957'],
      correctIndex: 0,
      landmark: 'Kota A-Famosa',
      emoji: '🏰',
    ),
    const Question(
      topic: 'Maths for Primary Students',
      question: 'Kuasa Eropah manakah yang membina Kota A-Famosa?',
      options: ['Portugis', 'Belanda', 'British', 'Sepanyol'],
      correctIndex: 0,
      landmark: 'Kota A-Famosa',
      emoji: '🏰',
    ),
    const Question(
      topic: 'Maths for Primary Students',
      question: 'Pada tahun berapa Melaka diisytiharkan Tapak Warisan UNESCO?',
      options: ['2008', '2000', '1995', '2012'],
      correctIndex: 0,
      landmark: 'Pusat Bandar Melaka',
      emoji: '🌏',
    ),
    const Question(
      topic: 'Maths for Primary Students',
      question: 'Kuasa manakah yang menawan Melaka dari Portugis pada 1641?',
      options: ['Belanda', 'British', 'Sepanyol', 'Perancis'],
      correctIndex: 0,
      landmark: 'Stadthuys',
      emoji: '🏛️',
    ),
    const Question(
      topic: 'Maths for Primary Students',
      question: 'Di manakah Perjanjian Melaka 1824 ditandatangani?',
      options: ['London', 'Melaka', 'Batavia', 'Singapore'],
      correctIndex: 0,
      landmark: 'Muzium Sejarah',
      emoji: '📜',
    ),
  ],
  'Maths for Secondary Students': [
    const Question(
      topic: 'Maths for Secondary Students',
      question: 'Apakah warna bangunan Stadthuys yang terkenal?',
      options: ['Merah', 'Putih', 'Kuning', 'Biru'],
      correctIndex: 0,
      landmark: 'Stadthuys',
      emoji: '🏛️',
    ),
    const Question(
      topic: 'Maths for Secondary Students',
      question: 'Apakah maksud "Stadthuys" dalam bahasa Belanda?',
      options: [
        'Dewan Bandaraya',
        'Istana Raja',
        'Rumah Penjara',
        'Gereja Lama',
      ],
      correctIndex: 0,
      landmark: 'Stadthuys',
      emoji: '🏛️',
    ),
    const Question(
      topic: 'Maths for Secondary Students',
      question: 'Di bukit manakah terletaknya Gereja St. Paul?',
      options: ['Bukit St. Paul', 'Bukit Belanda', 'Bukit Cina', 'Bukit Merah'],
      correctIndex: 0,
      landmark: 'Gereja St. Paul',
      emoji: '⛪',
    ),
    const Question(
      topic: 'Maths for Secondary Students',
      question: 'Apakah nama menara putar di Bandar Hilir Melaka?',
      options: [
        'Menara Taming Sari',
        'Menara Melaka',
        'Menara Warisan',
        'Menara KL',
      ],
      correctIndex: 0,
      landmark: 'Menara Taming Sari',
      emoji: '🗼',
    ),
    const Question(
      topic: 'Maths for Secondary Students',
      question: 'Bahan apakah yang digunakan untuk membina Kota A-Famosa?',
      options: ['Batu laterit', 'Bata merah', 'Kayu jati', 'Konkrit'],
      correctIndex: 0,
      landmark: 'Kota A-Famosa',
      emoji: '🏰',
    ),
    const Question(
      topic: 'Maths for Secondary Students',
      question: 'Berapa tingkatkah bangunan Stadthuys?',
      options: ['2 tingkat', '3 tingkat', '4 tingkat', '5 tingkat'],
      correctIndex: 0,
      landmark: 'Stadthuys',
      emoji: '🏛️',
    ),
  ],
  'Maths for Higher Education': [
    const Question(
      topic: 'Maths for Higher Education',
      question: 'Apakah yang dimaksudkan dengan komuniti "Baba Nyonya"?',
      options: [
        'Peranakan Cina',
        'Peranakan India',
        'Peranakan Arab',
        'Peranakan Bugis',
      ],
      correctIndex: 0,
      landmark: 'Muzium Baba Nyonya',
      emoji: '🎎',
    ),
    const Question(
      topic: 'Maths for Higher Education',
      question: 'Apakah makanan Melaka yang paling terkenal?',
      options: [
        'Nasi Ayam Bola',
        'Nasi Lemak',
        'Char Kuey Teow',
        'Laksa Penang',
      ],
      correctIndex: 0,
      landmark: 'Jalan Hang Jebat',
      emoji: '🍚',
    ),
    const Question(
      topic: 'Maths for Higher Education',
      question: 'Apakah Jalan Jonker paling terkenal?',
      options: [
        'Barangan antik & makanan',
        'Beli belah moden',
        'Pasar ikan',
        'Pertanian',
      ],
      correctIndex: 0,
      landmark: 'Jalan Jonker',
      emoji: '🛍️',
    ),
    const Question(
      topic: 'Maths for Higher Education',
      question: 'Apakah kenderaan ikonik di bandar Melaka?',
      options: ['Beca berhias', 'Kereta lembu', 'Bot nelayan', 'Monorail'],
      correctIndex: 0,
      landmark: 'Bandar Hilir',
      emoji: '🛺',
    ),
    const Question(
      topic: 'Maths for Higher Education',
      question: 'Apakah nama komuniti India Peranakan di Melaka?',
      options: ['Chitty', 'Jawi Peranakan', 'Serani', 'Bugis'],
      correctIndex: 0,
      landmark: 'Kampung Chitty',
      emoji: '🎉',
    ),
    const Question(
      topic: 'Maths for Higher Education',
      question: 'Bahasa apakah yang digunakan oleh komuniti Baba Nyonya?',
      options: ['Bahasa Melayu-Cina Kreol', 'Mandarin', 'Hokkien', 'Kantonis'],
      correctIndex: 0,
      landmark: 'Muzium Baba Nyonya',
      emoji: '🗣️',
    ),
  ],
  'Tourism Melaka': [
    const Question(
      topic: 'Tourism Melaka',
      question: 'Bagaimana cara terbaik menikmati pemandangan Sungai Melaka?',
      options: [
        'Bot pelancong sungai',
        'Menaiki feri',
        'Berenang',
        'Berjalan kaki',
      ],
      correctIndex: 0,
      landmark: 'Sungai Melaka',
      emoji: '🚤',
    ),
    const Question(
      topic: 'Tourism Melaka',
      question: 'Apakah nama roda pemerhatian besar di Melaka?',
      options: ['Melaka Eye', 'Melaka Wheel', 'Melaka Star', 'Melaka Orbit'],
      correctIndex: 0,
      landmark: 'Dataran Pahlawan',
      emoji: '🎡',
    ),
    const Question(
      topic: 'Tourism Melaka',
      question: 'Di manakah terletaknya Masjid Selat Melaka yang unik?',
      options: [
        'Di atas air',
        'Di bukit',
        'Di tengah bandar',
        'Di dalam hutan',
      ],
      correctIndex: 0,
      landmark: 'Masjid Selat Melaka',
      emoji: '🕌',
    ),
    const Question(
      topic: 'Tourism Melaka',
      question: 'Status UNESCO apakah yang diterima Melaka pada 2008?',
      options: [
        'Bandar Warisan Dunia',
        'Taman Warisan',
        'Tapak Semula Jadi',
        'Warisan Tak Ketara',
      ],
      correctIndex: 0,
      landmark: 'Pusat Melaka',
      emoji: '🌏',
    ),
    const Question(
      topic: 'Tourism Melaka',
      question: 'Di manakah Proclamation of Independence Memorial terletak?',
      options: ['Bandar Hilir', 'Ayer Keroh', 'Bukit Beruang', 'Klebang'],
      correctIndex: 0,
      landmark: 'Bandar Hilir',
      emoji: '🏛️',
    ),
    const Question(
      topic: 'Tourism Melaka',
      question: 'Apakah nama pantai yang terkenal di Melaka?',
      options: [
        'Pantai Klebang',
        'Pantai Batu Feringgi',
        'Pantai Cenang',
        'Pantai Morib',
      ],
      correctIndex: 0,
      landmark: 'Klebang',
      emoji: '🏖️',
    ),
  ],
};

List<Question> getQuestionsForTopic(String topic) =>
    questionsByTopic[topic] ?? [];

List<String> get allTopics => questionsByTopic.keys.toList();
