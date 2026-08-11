/// The i-GB Soal Selidik, following "BORANG SOAL SELIDIK IGB".
///
/// Four TAM constructs are asked twice: once about the printed board and once
/// about the app. Every item is scored 1-4 on the form's Gred Skor.
///
/// The paper form also asks for "Pengalaman mengajar". i-GB leaves it out —
/// most respondents are students, for whom the question means nothing.
///
/// Item codes must stay in step with SURVEY_ITEM_CODES in server/ar3d/db.py.
library;

class SurveyItem {
  final String code;
  final String text;

  const SurveyItem(this.code, this.text);
}

class SurveyConstruct {
  /// e.g. "Perceived Ease of Use (PEOU)"
  final String name;
  final List<SurveyItem> items;

  const SurveyConstruct(this.name, this.items);
}

class SurveySection {
  /// e.g. "B. REKABENTUK PAPAN PERMAINAN"
  final String title;
  final List<SurveyConstruct> constructs;

  const SurveySection(this.title, this.constructs);
}

/// The Gred Skor, in order. The index plus one is the stored score.
const surveyScale = <String>[
  'Sangat tidak setuju',
  'Tidak setuju',
  'Setuju',
  'Sangat setuju',
];

const surveyGenders = <String>['Lelaki', 'Perempuan'];
const surveyAgeGroups = <String>['18 – 23 tahun', '24 tahun ke atas'];
const surveyStatuses = <String>['Pensyarah', 'Pentadbir', 'Pelajar'];

const surveySections = <SurveySection>[
  SurveySection('B. REKABENTUK PAPAN PERMAINAN', [
    SurveyConstruct('Perceived Ease of Use (PEOU)', [
      SurveyItem('B-PEOU-1', 'Saya mudah memahami cara menggunakan papan i-GB.'),
      SurveyItem('B-PEOU-2', 'Interaksi dengan papan permainan adalah jelas dan mudah diikuti.'),
      SurveyItem('B-PEOU-3', 'Saya tidak menghadapi kesukaran menggunakan papan permainan.'),
      SurveyItem('B-PEOU-4', 'Saya dapat menggunakan papan permainan tanpa bantuan yang banyak.'),
    ]),
    SurveyConstruct('Perceived Usefulness (PU)', [
      SurveyItem('B-PU-1', 'Papan permainan membantu saya memahami topik pembelajaran dengan lebih baik.'),
      SurveyItem('B-PU-2', 'Penggunaan papan permainan meningkatkan penglibatan saya semasa pembelajaran.'),
      SurveyItem('B-PU-3', 'Papan permainan menjadikan proses pembelajaran lebih berkesan.'),
      SurveyItem('B-PU-4', 'Papan permainan membantu meningkatkan motivasi saya untuk belajar.'),
    ]),
    SurveyConstruct('Attitude Toward Using (ATU)', [
      SurveyItem('B-ATU-1', 'Saya seronok menggunakan papan permainan i-GB.'),
      SurveyItem('B-ATU-2', 'Saya berpendapat penggunaan papan permainan merupakan idea yang baik.'),
      SurveyItem('B-ATU-3', 'Saya berasa positif terhadap penggunaan papan permainan dalam pembelajaran.'),
    ]),
    SurveyConstruct('Behavioral Intention (BI)', [
      SurveyItem('B-BI-1', 'Saya ingin menggunakan papan permainan ini lagi pada masa hadapan.'),
      SurveyItem('B-BI-2', 'Saya akan mencadangkan penggunaan papan permainan ini kepada rakan.'),
      SurveyItem('B-BI-3', 'Saya bersedia menggunakan papan permainan ini dalam kelas lain.'),
    ]),
  ]),
  SurveySection('C. PENILAIAN APLIKASI i-GB', [
    SurveyConstruct('Perceived Ease of Use (PEOU)', [
      SurveyItem('C-PEOU-1', 'Aplikasi i-GB mudah digunakan.'),
      SurveyItem('C-PEOU-2', 'Proses mengimbas kod adalah mudah.'),
      SurveyItem('C-PEOU-3', 'Navigasi dalam aplikasi adalah jelas dan mudah difahami.'),
      SurveyItem('C-PEOU-4', 'Saya cepat mahir menggunakan aplikasi i-GB.'),
    ]),
    SurveyConstruct('Perceived Usefulness (PU)', [
      SurveyItem('C-PU-1', 'Aplikasi membantu saya memperoleh maklumat dengan cepat.'),
      SurveyItem('C-PU-2', 'Kandungan digital dalam aplikasi meningkatkan kefahaman saya.'),
      SurveyItem('C-PU-3', 'Maklum balas segera daripada aplikasi membantu proses pembelajaran.'),
      SurveyItem('C-PU-4', 'Aplikasi meningkatkan keberkesanan pembelajaran saya.'),
    ]),
    SurveyConstruct('Attitude Toward Using (ATU)', [
      SurveyItem('C-ATU-1', 'Saya suka menggunakan aplikasi i-GB.'),
      SurveyItem('C-ATU-2', 'Saya berpuas hati dengan pengalaman menggunakan aplikasi ini.'),
      SurveyItem('C-ATU-3', 'Saya berpendapat aplikasi ini sesuai digunakan dalam proses pembelajaran.'),
    ]),
    SurveyConstruct('Behavioral Intention (BI)', [
      SurveyItem('C-BI-1', 'Saya akan terus menggunakan aplikasi ini pada masa hadapan.'),
      SurveyItem('C-BI-2', 'Saya akan mengesyorkan aplikasi ini kepada rakan-rakan.'),
      SurveyItem('C-BI-3', 'Saya berharap lebih banyak kursus menggunakan aplikasi seperti ini.'),
    ]),
  ]),
];

/// Every item code the form must submit, in document order.
List<String> get surveyItemCodes => [
  for (final section in surveySections)
    for (final construct in section.constructs)
      for (final item in construct.items) item.code,
];
