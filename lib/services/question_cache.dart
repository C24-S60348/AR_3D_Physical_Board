import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/questions_data.dart';

/// Keeps the last question payload the device downloaded for each topic.
///
/// A scan that cannot reach the server replays this instead of the small
/// sample bundled with the app, so an offline game still asks the questions
/// the lecturer actually published. The raw API JSON is stored rather than a
/// converted model, so `Question.fromApiJson` stays the single parser.
class QuestionCache {
  static Directory? _directory;

  static Future<Directory> _cacheDirectory() async {
    final existing = _directory;
    if (existing != null) return existing;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/question_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _directory = dir;
    return dir;
  }

  static String _key(String topic, String? level, String? place) => [
    topic,
    level ?? '',
    place ?? '',
  ].join('|').replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');

  static Future<File> _fileFor(String topic, String? level, String? place) async {
    final dir = await _cacheDirectory();
    return File('${dir.path}/${_key(topic, level, place)}.json');
  }

  static Future<void> save(
    String topic,
    List<dynamic> rawQuestions, {
    String? level,
    String? place,
  }) async {
    try {
      final file = await _fileFor(topic, level, place);
      await file.writeAsString(jsonEncode(rawQuestions));
    } catch (_) {
      // A failed cache write must never interrupt a game that is already
      // running on live data.
    }
  }

  static Future<List<Question>> load(
    String topic, {
    String? level,
    String? place,
  }) async {
    try {
      final file = await _fileFor(topic, level, place);
      if (!await file.exists()) return const [];
      final decoded = jsonDecode(await file.readAsString()) as List<dynamic>;
      return decoded
          .map((item) => Question.fromApiJson(item as Map<String, dynamic>))
          .where((question) => question.id != null)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
