/// The AR checkpoints on the printed 100-square i-GB board.
///
/// Each of the seven landmarks is printed twice, once early and once late, so
/// the square number — not the landmark — decides how hard the questions are.
/// The tier follows the card ranges in the primary question document:
/// 1-25 HIJAU, 26-50 BIRU, 51-75 UNGU, 76-100 EMAS.
///
/// Kept in step with `CHECKPOINTS` in `server/ar3d/db.py`.
class BoardCheckpoint {
  final int square;
  final String name;
  final String place;
  final String tier;

  const BoardCheckpoint({
    required this.square,
    required this.name,
    required this.place,
    required this.tier,
  });

  String get label => 'Square $square — $name ($tier)';
}

const boardCheckpoints = <BoardCheckpoint>[
  BoardCheckpoint(square: 8, name: 'Muzium Samudera', place: 'muzium-samudera', tier: 'HIJAU'),
  BoardCheckpoint(square: 18, name: 'Menara Taming Sari', place: 'menara-taming-sari', tier: 'HIJAU'),
  BoardCheckpoint(square: 25, name: 'Pantai Klebang', place: 'pantai-klebang', tier: 'HIJAU'),
  BoardCheckpoint(square: 35, name: 'Masjid Cina Melaka', place: 'masjid-cina', tier: 'BIRU'),
  BoardCheckpoint(square: 39, name: "Kota A'Famosa", place: 'kota-a-famosa', tier: 'BIRU'),
  BoardCheckpoint(square: 49, name: 'Masjid Selat Melaka', place: 'masjid-selat', tier: 'BIRU'),
  BoardCheckpoint(square: 55, name: 'Menara Taming Sari', place: 'menara-taming-sari', tier: 'UNGU'),
  BoardCheckpoint(square: 67, name: "Kota A'Famosa", place: 'kota-a-famosa', tier: 'UNGU'),
  BoardCheckpoint(square: 71, name: 'Stadium Hang Jebat', place: 'stadium-hang-jebat', tier: 'UNGU'),
  BoardCheckpoint(square: 79, name: 'Muzium Samudera', place: 'muzium-samudera', tier: 'EMAS'),
  BoardCheckpoint(square: 81, name: 'Masjid Selat Melaka', place: 'masjid-selat', tier: 'EMAS'),
  BoardCheckpoint(square: 85, name: 'Masjid Cina Melaka', place: 'masjid-cina', tier: 'EMAS'),
  BoardCheckpoint(square: 93, name: 'Pantai Klebang', place: 'pantai-klebang', tier: 'EMAS'),
  BoardCheckpoint(square: 98, name: 'Stadium Hang Jebat', place: 'stadium-hang-jebat', tier: 'EMAS'),
];
