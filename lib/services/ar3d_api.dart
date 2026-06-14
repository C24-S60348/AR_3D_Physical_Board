import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../data/questions_data.dart';

class Ar3dApi {
  static const String baseUrl = String.fromEnvironment(
    'AR3D_API_BASE_URL',
    defaultValue: '',
  );

  static bool get isConfigured => baseUrl.trim().isNotEmpty;

  static Uri _uri(String path, [Map<String, String>? query]) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path').replace(queryParameters: query);
  }

  static Future<String> testConnection() async {
    if (!isConfigured) {
      throw StateError(
        'AR3D_API_BASE_URL is not configured. Start Flutter with '
        '--dart-define=AR3D_API_BASE_URL=http://YOUR_SERVER_IP:5000',
      );
    }

    final client = HttpClient();
    try {
      final request = await client
          .getUrl(_uri('/api/ar3d/health'))
          .timeout(const Duration(seconds: 5));
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Health API returned ${response.statusCode}');
      }
      final payload = jsonDecode(body) as Map<String, dynamic>;
      if (payload['status'] != 'ok') {
        throw const FormatException('Unexpected health API response');
      }
      return payload['service'] as String? ?? 'ar3d';
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<Question>> getQuestions(String topic) async {
    if (!isConfigured) return const [];

    final client = HttpClient();
    try {
      final request = await client
          .getUrl(_uri('/api/ar3d/questions', {'topic': topic}))
          .timeout(const Duration(seconds: 5));
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Question API returned ${response.statusCode}');
      }
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return (payload['questions'] as List<dynamic>? ?? const [])
          .map((item) => Question.fromApiJson(item as Map<String, dynamic>))
          .where((question) => question.id != null)
          .toList();
    } finally {
      client.close(force: true);
    }
  }

  static Future<AnswerSubmissionResult?> submitAnswer({
    required String playerName,
    required Question question,
    required String answer,
    String? detectedImageName,
  }) async {
    if (!isConfigured || question.id == null) return null;

    final client = HttpClient();
    try {
      final request = await client
          .postUrl(_uri('/api/ar3d/answers'))
          .timeout(const Duration(seconds: 5));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'player_name': playerName,
          'question_id': question.id,
          'answer': answer,
          'detected_image_name': detectedImageName,
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.created) {
        throw HttpException('Answer API returned ${response.statusCode}');
      }
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return AnswerSubmissionResult(
        isCorrect: payload['is_correct'] as bool? ?? false,
        correctAnswer: payload['correct_answer'] as String? ?? '',
      );
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> adminLogin(String password) async {
    final payload = await _jsonRequest(
      'POST',
      '/api/ar3d/admin/login',
      body: {'password': password},
    );
    if (payload['authenticated'] != true) {
      throw const HttpException('Lecturer authentication failed');
    }
  }

  static Future<List<ApiTopic>> getTopics() async {
    final payload = await _jsonRequest('GET', '/api/ar3d/topics');
    return (payload['topics'] as List<dynamic>? ?? const [])
        .map((item) => ApiTopic.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Question>> getAdminQuestions(String password) async {
    final payload = await _jsonRequest(
      'GET',
      '/api/ar3d/admin/questions',
      adminPassword: password,
    );
    return (payload['questions'] as List<dynamic>? ?? const [])
        .map((item) => Question.fromApiJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<AdminResponse>> getAdminResponses(String password) async {
    final payload = await _jsonRequest(
      'GET',
      '/api/ar3d/admin/responses',
      adminPassword: password,
    );
    return (payload['responses'] as List<dynamic>? ?? const [])
        .map((item) => AdminResponse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveAdminQuestion({
    required String password,
    int? questionId,
    required int topicId,
    required String prompt,
    required List<String> acceptedAnswers,
    required bool isActive,
    AdminQuestionImage? image,
  }) async {
    if (image != null) {
      await _multipartQuestionRequest(
        questionId == null ? 'POST' : 'PUT',
        questionId == null
            ? '/api/ar3d/admin/questions'
            : '/api/ar3d/admin/questions/$questionId',
        adminPassword: password,
        topicId: topicId,
        prompt: prompt,
        acceptedAnswers: acceptedAnswers,
        isActive: isActive,
        image: image,
      );
      return;
    }
    await _jsonRequest(
      questionId == null ? 'POST' : 'PUT',
      questionId == null
          ? '/api/ar3d/admin/questions'
          : '/api/ar3d/admin/questions/$questionId',
      adminPassword: password,
      body: {
        'topic_id': topicId,
        'prompt': prompt,
        'accepted_answers': acceptedAnswers,
        'is_active': isActive,
      },
    );
  }

  static Future<void> _multipartQuestionRequest(
    String method,
    String path, {
    required String adminPassword,
    required int topicId,
    required String prompt,
    required List<String> acceptedAnswers,
    required bool isActive,
    required AdminQuestionImage image,
  }) async {
    if (!isConfigured) {
      throw StateError('AR3D_API_BASE_URL is not configured');
    }
    final boundary =
        'ar3d-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    final body = BytesBuilder(copy: false);

    void addTextField(String name, String value) {
      body.add(utf8.encode('--$boundary\r\n'));
      body.add(
        utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'),
      );
      body.add(utf8.encode('$value\r\n'));
    }

    addTextField('topic_id', topicId.toString());
    addTextField('prompt', prompt);
    addTextField('accepted_answers', jsonEncode(acceptedAnswers));
    addTextField('is_active', isActive.toString());
    final safeFilename = image.filename.replaceAll('"', '');
    body.add(utf8.encode('--$boundary\r\n'));
    body.add(
      utf8.encode(
        'Content-Disposition: form-data; name="image"; '
        'filename="$safeFilename"\r\n',
      ),
    );
    body.add(utf8.encode('Content-Type: ${image.contentType}\r\n\r\n'));
    body.add(image.bytes);
    body.add(utf8.encode('\r\n--$boundary--\r\n'));
    final requestBody = body.takeBytes();

    final client = HttpClient();
    try {
      final request = await client
          .openUrl(method, _uri(path))
          .timeout(const Duration(seconds: 8));
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      request.headers.set('X-Admin-Password', adminPassword);
      request.headers.contentType = ContentType(
        'multipart',
        'form-data',
        parameters: {'boundary': boundary},
      );
      request.contentLength = requestBody.length;
      request.add(requestBody);
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final responseBody = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = 'API returned ${response.statusCode}';
        if (responseBody.isNotEmpty) {
          final error = jsonDecode(responseBody) as Map<String, dynamic>;
          message = error['error'] as String? ?? message;
        }
        throw HttpException(message);
      }
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> archiveAdminQuestion({
    required String password,
    required int questionId,
  }) async {
    await _jsonRequest(
      'DELETE',
      '/api/ar3d/admin/questions/$questionId',
      adminPassword: password,
      allowEmpty: true,
    );
  }

  static Future<Map<String, dynamic>> _jsonRequest(
    String method,
    String path, {
    String? adminPassword,
    Map<String, dynamic>? body,
    bool allowEmpty = false,
  }) async {
    if (!isConfigured) {
      throw StateError('AR3D_API_BASE_URL is not configured');
    }
    final client = HttpClient();
    try {
      final request = await client
          .openUrl(method, _uri(path))
          .timeout(const Duration(seconds: 8));
      request.headers.set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      if (adminPassword != null) {
        request.headers.set('X-Admin-Password', adminPassword);
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      final responseBody = await utf8.decoder.bind(response).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = 'API returned ${response.statusCode}';
        if (responseBody.isNotEmpty) {
          final error = jsonDecode(responseBody) as Map<String, dynamic>;
          message = error['error'] as String? ?? message;
        }
        throw HttpException(message);
      }
      if (allowEmpty && responseBody.isEmpty) return const {};
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }
}

class AdminQuestionImage {
  final String filename;
  final Uint8List bytes;

  const AdminQuestionImage({required this.filename, required this.bytes});

  String get contentType {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}

class AnswerSubmissionResult {
  final bool isCorrect;
  final String correctAnswer;

  const AnswerSubmissionResult({
    required this.isCorrect,
    required this.correctAnswer,
  });
}

class ApiTopic {
  final int id;
  final String name;

  const ApiTopic({required this.id, required this.name});

  factory ApiTopic.fromJson(Map<String, dynamic> json) =>
      ApiTopic(id: json['id'] as int, name: json['name'] as String);
}

class AdminResponse {
  final int id;
  final String playerName;
  final String topicName;
  final String questionText;
  final String submittedAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String answeredAt;

  const AdminResponse({
    required this.id,
    required this.playerName,
    required this.topicName,
    required this.questionText,
    required this.submittedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory AdminResponse.fromJson(Map<String, dynamic> json) => AdminResponse(
    id: json['id'] as int,
    playerName: json['player_name'] as String,
    topicName: json['topic_name'] as String,
    questionText: json['question_text'] as String,
    submittedAnswer: json['selected_answer'] as String,
    correctAnswer: json['correct_answer'] as String,
    isCorrect: json['is_correct'] as bool,
    answeredAt: json['answered_at'] as String,
  );
}
