import 'package:flutter/material.dart';

import '../data/survey_items.dart';
import '../services/ar3d_api.dart';

/// Borang Soal Selidik i-GB.
///
/// Answers post to /api/ar3d/survey so they land in the database and show under
/// Survey in the Lecturer Admin screen. See lib/data/survey_items.dart for the
/// items themselves.
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  static const _red = Color(0xFF8B1A1A);

  String? _gender;
  String? _ageGroup;
  String? _status;

  /// item code -> score 1..4
  final Map<String, int> _ratings = {};

  int _starRating = 0;
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _submitted = false;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  int get _answeredCount => _ratings.length;
  int get _totalItems => surveyItemCodes.length;

  bool get _canSubmit =>
      _gender != null &&
      _ageGroup != null &&
      _status != null &&
      _answeredCount == _totalItems &&
      _starRating > 0;

  String? get _missingSummary {
    if (_gender == null || _ageGroup == null || _status == null) {
      return 'Sila lengkapkan Bahagian A (maklumat demografi).';
    }
    if (_answeredCount < _totalItems) {
      final left = _totalItems - _answeredCount;
      return 'Tinggal $left item lagi untuk dijawab.';
    }
    if (_starRating == 0) return 'Sila beri penilaian bintang.';
    return null;
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await Ar3dApi.submitSurvey(
        gender: _gender!,
        ageGroup: _ageGroup!,
        status: _status!,
        ratings: _ratings,
        starRating: _starRating,
        comment: _commentCtrl.text.trim(),
      );
      if (mounted) setState(() => _submitted = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _submitError =
              'Tidak dapat menghantar jawapan. Sila semak sambungan internet '
              'anda, kemudian cuba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: const Text('Soal Selidik i-GB'),
      ),
      body: _submitted ? _buildThanks() : _buildForm(),
      bottomNavigationBar: _submitted ? null : _buildSubmitBar(),
    );
  }

  Widget _buildThanks() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 84),
            const SizedBox(height: 20),
            const Text(
              'Terima kasih!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Maklum balas anda telah dihantar dan akan digunakan untuk '
              'menambah baik proses pembelajaran & pengajaran.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _card(
          child: const Text(
            'Soal selidik ini dijalankan untuk mengenal pasti rekabentuk papan '
            'permainan dan aplikasi Interactive Game Board (i-GB). Dapatan '
            'kajian ini akan digunakan untuk meningkatkan proses pembelajaran '
            '& pengajaran. Terima kasih atas kesediaan anda.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
        ),

        _sectionHeading('A. MAKLUMAT DEMOGRAFI'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _choiceGroup('Jantina', surveyGenders, _gender,
                  (v) => setState(() => _gender = v)),
              const SizedBox(height: 16),
              _choiceGroup('Umur', surveyAgeGroups, _ageGroup,
                  (v) => setState(() => _ageGroup = v)),
              const SizedBox(height: 16),
              _choiceGroup('Status', surveyStatuses, _status,
                  (v) => setState(() => _status = v)),
            ],
          ),
        ),

        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GRED SKOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _red,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < surveyScale.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '${i + 1} — ${surveyScale[i]}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
            ],
          ),
        ),

        for (final section in surveySections) ...[
          _sectionHeading(section.title),
          for (final construct in section.constructs)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    construct.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final item in construct.items) _likertRow(item),
                ],
              ),
            ),
        ],

        _sectionHeading('PENILAIAN KESELURUHAN'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Berapa bintang anda beri kepada i-GB?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      onPressed: () => setState(() => _starRating = star),
                      iconSize: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        star <= _starRating ? Icons.star : Icons.star_border,
                        color: star <= _starRating
                            ? Colors.amber.shade700
                            : Colors.grey.shade400,
                      ),
                      tooltip: '$star bintang',
                    ),
                ],
              ),
            ],
          ),
        ),

        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Komen / ulasan mengenai i-GB',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Pilihan — tulis cadangan anda di sini',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),

        if (_submitError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _submitError!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: _red,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }

  Widget _choiceGroup(
    String label,
    List<String> options,
    String? selected,
    ValueChanged<String> onPick,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text(option),
                selected: selected == option,
                onSelected: (_) => onPick(option),
                selectedColor: _red.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: selected == option
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: selected == option ? _red : Colors.black87,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: selected == option
                        ? _red
                        : Colors.grey.withValues(alpha: 0.4),
                  ),
                ),
                backgroundColor: Colors.white,
                showCheckmark: false,
              ),
          ],
        ),
      ],
    );
  }

  Widget _likertRow(SurveyItem item) {
    final score = _ratings[item.code];
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.text, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var value = 1; value <= surveyScale.length; value++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          setState(() => _ratings[item.code] = value),
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: score == value
                              ? _red
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: score == value
                                ? _red
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: score == value
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    final missing = _missingSummary;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 28 items is a long form, so show how far along the reader is.
            LinearProgressIndicator(
              value: _totalItems == 0 ? 0 : _answeredCount / _totalItems,
              minHeight: 5,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(_red),
            ),
            const SizedBox(height: 8),
            Text(
              missing ?? 'Semua item telah dijawab.',
              style: TextStyle(
                fontSize: 12,
                color: missing == null ? Colors.green.shade700 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit && !_submitting ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Hantar ($_answeredCount/$_totalItems)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
