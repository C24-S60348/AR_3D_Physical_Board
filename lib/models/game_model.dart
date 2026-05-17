class GameSquare {
  final int id;
  final String name;
  final String landmark;
  final String emoji;
  final String? topic;
  final int? snakeTo;
  final int? ladderTo;
  final bool isStart;
  final bool isFinish;

  const GameSquare({
    required this.id,
    required this.name,
    required this.landmark,
    required this.emoji,
    this.topic,
    this.snakeTo,
    this.ladderTo,
    this.isStart = false,
    this.isFinish = false,
  });

  bool get hasQuestion => topic != null;
  bool get hasSnake => snakeTo != null;
  bool get hasLadder => ladderTo != null;
}

const List<GameSquare> gameBoard = [
  GameSquare(id: 1,  name: 'MULA',          landmark: 'Padang Pahlawan',           emoji: '🚩', isStart: true),
  GameSquare(id: 2,  name: 'Stadthuys',      landmark: 'Bangunan Merah Belanda',    emoji: '🏛️'),
  GameSquare(id: 3,  name: 'Gereja Christ',  landmark: 'Christ Church Melaka',      emoji: '⛪'),
  GameSquare(id: 4,  name: 'SOALAN ❓',      landmark: 'Pekan Lama',                emoji: '❓', topic: 'Sejarah Melaka'),
  GameSquare(id: 5,  name: 'Jalan Jonker',   landmark: 'Jonker Street — ULAR! 🐍',  emoji: '🛍️', snakeTo: 1),
  GameSquare(id: 6,  name: 'Muzium Baba Nyonya', landmark: 'Baba Nyonya Museum',   emoji: '🎎'),
  GameSquare(id: 7,  name: 'Sungai Melaka',  landmark: 'Melaka River Cruise',       emoji: '🚤'),
  GameSquare(id: 8,  name: 'SOALAN ❓',      landmark: 'Jambatan Lama',             emoji: '❓', topic: 'Budaya'),
  GameSquare(id: 9,  name: 'Kota A-Famosa',  landmark: 'A-Famosa Fortress Gate',    emoji: '🏰'),
  GameSquare(id: 10, name: 'Bukit St. Paul', landmark: 'St. Paul\'s Hill',          emoji: '⛰️'),
  GameSquare(id: 11, name: 'Tangga Warisan', landmark: 'Heritage Stairs — TANGGA! 🪜', emoji: '🪜', ladderTo: 20),
  GameSquare(id: 12, name: 'SOALAN ❓',      landmark: 'Tapak Warisan UNESCO',       emoji: '❓', topic: 'Seni Bina'),
  GameSquare(id: 13, name: 'Menara Taming Sari', landmark: 'Gyrotower Melaka',      emoji: '🗼'),
  GameSquare(id: 14, name: 'Melaka Eye',     landmark: 'Giant Observation Wheel',   emoji: '🎡'),
  GameSquare(id: 15, name: 'Cheng Hoon Teng', landmark: 'Tokong Cina Tertua',       emoji: '🛕'),
  GameSquare(id: 16, name: 'SOALAN ❓',      landmark: 'Lorong Budaya',             emoji: '❓', topic: 'Pelancongan'),
  GameSquare(id: 17, name: 'Masjid Kampung Kling', landmark: 'Masjid Bersejarah',   emoji: '🕌'),
  GameSquare(id: 18, name: 'Ular Besar!',    landmark: 'Balik ke Sq 7 — ULAR! 🐍', emoji: '🐍', snakeTo: 7),
  GameSquare(id: 19, name: 'Masjid Selat',   landmark: 'Floating Mosque',           emoji: '🕌'),
  GameSquare(id: 20, name: 'Proklamasi',      landmark: 'Independence Memorial',     emoji: '🏛️'),
  GameSquare(id: 21, name: 'SOALAN ❓',      landmark: 'Dataran Kemerdekaan',       emoji: '❓', topic: 'Sejarah Melaka'),
  GameSquare(id: 22, name: 'Istana Lama',    landmark: 'Sultanic Palace — ULAR! 🐍', emoji: '🏯', snakeTo: 14),
  GameSquare(id: 23, name: 'Taman Bunga',    landmark: 'Botanical Garden Melaka',   emoji: '🌺'),
  GameSquare(id: 24, name: 'SOALAN ❓',      landmark: 'Pusat Budaya',              emoji: '❓', topic: 'Budaya'),
  GameSquare(id: 25, name: 'Tangga Emas!',   landmark: 'Naik ke Sq 29 — TANGGA! 🪜', emoji: '🪜', ladderTo: 29),
  GameSquare(id: 26, name: 'Zoo Melaka',     landmark: 'Melaka Zoological Park',    emoji: '🦁'),
  GameSquare(id: 27, name: 'SOALAN ❓',      landmark: 'Kawasan Warisan',           emoji: '❓', topic: 'Seni Bina'),
  GameSquare(id: 28, name: 'Pantai Klebang', landmark: 'Klebang Beach',             emoji: '🏖️'),
  GameSquare(id: 29, name: 'Muzium Negeri',  landmark: 'Muzium Negeri Melaka',      emoji: '🏛️'),
  GameSquare(id: 30, name: 'TAMAT! 🏆',      landmark: 'Taman Negara Melaka',       emoji: '🏆', isFinish: true),
];

class PlayerResult {
  final String playerName;
  final String topic;
  int correctAnswers;
  int wrongAnswers;
  int finalPosition;

  PlayerResult({
    required this.playerName,
    required this.topic,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.finalPosition = 1,
  });

  int get totalAnswered => correctAnswers + wrongAnswers;
  double get accuracy =>
      totalAnswered == 0 ? 0.0 : correctAnswers / totalAnswered;
  int get score => correctAnswers * 10;
}
