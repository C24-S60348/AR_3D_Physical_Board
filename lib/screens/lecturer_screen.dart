import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/checkpoints.dart';
import '../data/questions_data.dart';
import '../services/ar3d_api.dart';

class LecturerScreen extends StatefulWidget {
  const LecturerScreen({super.key});

  @override
  State<LecturerScreen> createState() => _LecturerScreenState();
}

class _LecturerScreenState extends State<LecturerScreen> {
  static const _red = Color(0xFF8B1A1A);
  final _passwordController = TextEditingController();
  String? _password;
  bool _busy = false;
  String? _error;
  List<ApiTopic> _topics = const [];
  List<Question> _questions = const [];
  List<GameNote> _notes = const [];
  List<AdminResponse> _responses = const [];
  List<SurveyResponse> _surveyResponses = const [];

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final password = _passwordController.text;
    if (password.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Ar3dApi.adminLogin(password);
      _password = password;
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    final password = _password;
    if (password == null) return;
    final results = await Future.wait([
      Ar3dApi.getTopics(),
      Ar3dApi.getAdminQuestions(password),
      Ar3dApi.getAdminResponses(password),
    ]);
    List<GameNote> notes = const [];
    String? notesError;
    try {
      notes = await Ar3dApi.getAdminNotes(password);
    } catch (error) {
      notesError =
          'Questions and responses loaded, but notes are unavailable. '
          '${_message(error)}';
    }
    List<SurveyResponse> surveyResponses = const [];
    try {
      surveyResponses = await Ar3dApi.getAdminSurveyResponses(password);
    } catch (error) {
      notesError ??= 'Survey responses are unavailable. ${_message(error)}';
    }
    if (!mounted) return;
    setState(() {
      _topics = results[0] as List<ApiTopic>;
      _questions = results[1] as List<Question>;
      _responses = results[2] as List<AdminResponse>;
      _notes = notes;
      _surveyResponses = surveyResponses;
      _error = notesError;
    });
  }

  Future<void> _openEditor([Question? question]) async {
    if (_topics.isEmpty) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _QuestionEditor(
        topics: _topics,
        question: question,
        onSave:
            ({
              required topicId,
              required prompt,
              required acceptedAnswers,
              required isActive,
              required checkpoint,
              image,
            }) => Ar3dApi.saveAdminQuestion(
              password: _password!,
              questionId: question?.id,
              topicId: topicId,
              prompt: prompt,
              acceptedAnswers: acceptedAnswers,
              isActive: isActive,
              checkpoint: checkpoint,
              image: image,
            ),
      ),
    );
    if (saved == true) await _runRefresh();
  }

  Future<void> _archive(Question question) async {
    if (question.id == null) return;
    await Ar3dApi.archiveAdminQuestion(
      password: _password!,
      questionId: question.id!,
    );
    await _runRefresh();
  }

  Future<void> _openNoteEditor([GameNote? note]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _NoteEditor(
        note: note,
        onSave:
            ({
              required emoji,
              required title,
              required points,
              required externalUrl,
              required sortOrder,
              required isActive,
              image,
            }) => Ar3dApi.saveAdminNote(
              password: _password!,
              noteId: note?.id,
              emoji: emoji,
              title: title,
              points: points,
              externalUrl: externalUrl,
              sortOrder: sortOrder,
              isActive: isActive,
              image: image,
            ),
      ),
    );
    if (saved == true) await _runRefresh();
  }

  Future<void> _archiveNote(GameNote note) async {
    if (note.id == null) return;
    await Ar3dApi.archiveAdminNote(password: _password!, noteId: note.id!);
    await _runRefresh();
  }

  Future<void> _runRefresh() async {
    setState(() => _busy = true);
    try {
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('HttpException: ', '')
      .replaceFirst('Bad state: ', '');

  @override
  Widget build(BuildContext context) {
    if (_password == null) return _buildLogin();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lecturer Admin'),
          backgroundColor: _red,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _busy ? null : _runRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            IconButton(
              onPressed: () => setState(() {
                _password = null;
                _passwordController.clear();
                _questions = const [];
                _notes = const [];
                _responses = const [];
                _surveyResponses = const [];
              }),
              icon: const Icon(Icons.logout),
              tooltip: 'Log out',
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.quiz_outlined), text: 'Questions'),
              Tab(icon: Icon(Icons.notes_outlined), text: 'Notes'),
              Tab(icon: Icon(Icons.assessment_outlined), text: 'Responses'),
              Tab(icon: Icon(Icons.poll_outlined), text: 'Survey'),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (tabContext) {
            final tab = DefaultTabController.of(tabContext).index;
            if (tab >= 2) return const SizedBox.shrink();
            return FloatingActionButton.extended(
              onPressed: _busy
                  ? null
                  : () {
                      if (tab == 1) {
                        _openNoteEditor();
                      } else {
                        _openEditor();
                      }
                    },
              backgroundColor: _red,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            );
          },
        ),
        body: Column(
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              MaterialBanner(
                content: Text(_error!),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: const Text('Close'),
                  ),
                ],
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildQuestions(),
                  _buildNotes(),
                  _buildResponses(),
                  _buildSurvey(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Login'),
        backgroundColor: _red,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_red, Color(0xFF3a0a0a)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: _red,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Lecturer Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage questions, notes, and learner responses',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      decoration: const InputDecoration(
                        labelText: 'Lecturer password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _login,
                        icon: _busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login, size: 20),
                        label: Text(
                          _busy ? 'Connecting...' : 'Log in',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Question>> get _questionsByTopic {
    final grouped = <String, List<Question>>{};
    for (final topic in _topics) {
      grouped[topic.name] = [];
    }
    for (final question in _questions) {
      grouped.putIfAbsent(question.topic, () => []).add(question);
    }
    grouped.removeWhere((_, questions) => questions.isEmpty);
    return grouped;
  }

  Widget _buildQuestions() {
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions yet.'));
    }
    final active = _questions.where((q) => q.isActive).length;
    final grouped = _questionsByTopic;
    final topicNames = grouped.keys.toList();
    return RefreshIndicator(
      onRefresh: _runRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: topicNames.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statChip(
                    icon: Icons.quiz_outlined,
                    label: '${_questions.length} questions',
                    color: _red,
                  ),
                  _statChip(
                    icon: Icons.check_circle_outline,
                    label: '$active active',
                    color: Colors.green.shade700,
                  ),
                  if (_questions.length - active > 0)
                    _statChip(
                      icon: Icons.archive_outlined,
                      label: '${_questions.length - active} archived',
                      color: Colors.grey.shade600,
                    ),
                ],
              ),
            );
          }
          final topicName = topicNames[index - 1];
          final topicQuestions = grouped[topicName]!;
          final topicActive = topicQuestions.where((q) => q.isActive).length;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              initiallyExpanded: topicNames.length == 1,
              title: Text(
                topicName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${topicQuestions.length} question(s) · $topicActive active',
              ),
              leading: CircleAvatar(
                backgroundColor: _red.withValues(alpha: 0.1),
                child: Text(
                  '${topicQuestions.length}',
                  style: const TextStyle(
                    color: _red,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              children: topicQuestions
                  .map((question) => _questionCard(question))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _questionCard(Question question) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: question.isActive
              ? Colors.green.withValues(alpha: 0.25)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: question.isActive
              ? Colors.green.shade100
              : Colors.grey.shade300,
          child: Icon(
            question.isActive ? Icons.check : Icons.archive_outlined,
            color: question.isActive ? Colors.green : Colors.grey,
          ),
        ),
        title: Text(
          question.question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  question.topic,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _red,
                  ),
                ),
              ),
              if (question.level != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    question.level!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              Text(
                question.acceptedAnswers.join(' | '),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        onTap: () => _openEditor(question),
        trailing: question.isActive
            ? IconButton(
                onPressed: () => _archive(question),
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Archive',
              )
            : null,
      ),
    );
  }

  Widget _buildResponses() {
    if (_responses.isEmpty) {
      return const Center(child: Text('No learner responses yet.'));
    }
    final correct = _responses.where((r) => r.isCorrect).length;
    final players = _responses.map((r) => r.playerName).toSet().length;
    final rate = (correct / _responses.length * 100).round();
    return RefreshIndicator(
      onRefresh: _runRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _responses.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statChip(
                    icon: Icons.assessment_outlined,
                    label: '${_responses.length} answers',
                    color: _red,
                  ),
                  _statChip(
                    icon: Icons.percent,
                    label: '$rate% correct',
                    color: rate >= 50
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                  _statChip(
                    icon: Icons.people_outline,
                    label: '$players player(s)',
                    color: Colors.blueGrey.shade700,
                  ),
                ],
              ),
            );
          }
          final response = _responses[index - 1];
          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: (response.isCorrect ? Colors.green : Colors.red)
                    .withValues(alpha: 0.25),
              ),
            ),
            child: ListTile(
              leading: Icon(
                response.isCorrect ? Icons.check_circle : Icons.cancel,
                color: response.isCorrect ? Colors.green : Colors.red,
              ),
              title: Text(
                response.playerName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${response.questionText}\n'
                'Answer: ${response.submittedAnswer}'
                '${response.isCorrect ? '' : '  (correct: ${response.correctAnswer})'}\n'
                '${response.topicName} | ${response.answeredAt}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSurvey() {
    if (_surveyResponses.isEmpty) {
      return const Center(child: Text('No survey responses yet.'));
    }
    final totalStars = _surveyResponses.fold<int>(
      0,
      (sum, r) => sum + r.starRating,
    );
    final average = totalStars / _surveyResponses.length;
    return RefreshIndicator(
      onRefresh: _runRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _surveyResponses.length + 1,
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statChip(
                    icon: Icons.poll_outlined,
                    label: '${_surveyResponses.length} response(s)',
                    color: _red,
                  ),
                  _statChip(
                    icon: Icons.star_rounded,
                    label: '${average.toStringAsFixed(1)} avg rating',
                    color: Colors.amber.shade800,
                  ),
                ],
              ),
            );
          }
          final response = _surveyResponses[index - 1];
          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.amber.withValues(alpha: 0.15),
                child: Text(
                  '${response.starRating}★',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              title: Text(
                '${response.status} · ${response.ageGroup}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Kemudahan: ${response.easiness} | AR: ${response.arExperience}\n'
                'Kesesuaian soalan: ${response.questionFit}'
                '${response.comment == null ? '' : '\n"${response.comment}"'}\n'
                '${response.submittedAt}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotes() {
    if (_notes.isEmpty) {
      return const Center(child: Text('No notes yet.'));
    }
    return RefreshIndicator(
      onRefresh: _runRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: _notes.length,
        itemBuilder: (_, index) {
          final note = _notes[index];
          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: note.isActive
                    ? _red.withValues(alpha: 0.18)
                    : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _red.withValues(alpha: 0.08),
                child: Text(note.emoji),
              ),
              title: Text(
                note.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${note.points.length} point(s)'
                '${note.externalUrl == null ? '' : '\nExternal link added'}',
              ),
              isThreeLine: note.externalUrl != null,
              onTap: () => _openNoteEditor(note),
              trailing: note.isActive
                  ? IconButton(
                      onPressed: () => _archiveNote(note),
                      icon: const Icon(Icons.archive_outlined),
                      tooltip: 'Archive',
                    )
                  : const Icon(Icons.archive_outlined, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

class _NoteEditor extends StatefulWidget {
  final GameNote? note;
  final Future<void> Function({
    required String emoji,
    required String title,
    required List<String> points,
    required String externalUrl,
    required int sortOrder,
    required bool isActive,
    AdminQuestionImage? image,
  })
  onSave;

  const _NoteEditor({required this.note, required this.onSave});

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final TextEditingController _emojiController;
  late final TextEditingController _titleController;
  late final TextEditingController _pointsController;
  late final TextEditingController _urlController;
  late final TextEditingController _orderController;
  late bool _isActive;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _selectingImage = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _emojiController = TextEditingController(text: note?.emoji ?? '📚');
    _titleController = TextEditingController(text: note?.title ?? '');
    _pointsController = TextEditingController(
      text: note?.points.join('\n') ?? '',
    );
    _urlController = TextEditingController(text: note?.externalUrl ?? '');
    _orderController = TextEditingController(
      text: (note?.sortOrder ?? 0).toString(),
    );
    _isActive = note?.isActive ?? true;
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _titleController.dispose();
    _pointsController.dispose();
    _urlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectingImage) return;
    setState(() {
      _selectingImage = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 65,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 900 * 1024) {
        if (!mounted) return;
        setState(() {
          _error =
              'The selected image is still too large to upload. '
              'Please choose a smaller image.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _error =
            'Image picker is not registered. Fully stop and rebuild the app.';
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not open the photo library: ${error.message ?? error.code}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not choose an image: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _selectingImage = false);
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final points = _pointsController.text
        .split('\n')
        .map((point) => point.trim())
        .where((point) => point.isNotEmpty)
        .toList();
    final url = _urlController.text.trim();
    final order = int.tryParse(_orderController.text.trim());
    // A note made only of an image is valid, so the points are optional once
    // one is attached — either newly picked or already stored.
    final hasImage =
        _selectedImageBytes != null || widget.note?.imageUrl != null;
    if (title.isEmpty || (points.isEmpty && url.isEmpty && !hasImage)) {
      setState(() {
        _error = 'Add a title, then at least one point, an image, or a link.';
      });
      return;
    }
    if (order == null) {
      setState(() => _error = 'Display order must be a number.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        emoji: _emojiController.text.trim().isEmpty
            ? '📚'
            : _emojiController.text.trim(),
        title: title,
        points: points,
        externalUrl: url,
        sortOrder: order,
        isActive: _isActive,
        image: _selectedImageBytes == null
            ? null
            : AdminQuestionImage(
                filename: _selectedImageName ?? 'note.jpg',
                bytes: _selectedImageBytes!,
              ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString().replaceFirst('HttpException: ', '');
        });
      }
    }
  }

  Widget _buildImagePicker() {
    final selectedBytes = _selectedImageBytes;
    final currentImageUrl = widget.note?.imageUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Note image (optional)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          if (selectedBytes != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                selectedBytes,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(_selectedImageName ?? 'Selected image'),
          ] else if (currentImageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                currentImageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Text('Current image could not be loaded.'),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Current image'),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _saving || _selectingImage ? null : _pickImage,
            icon: _selectingImage
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image_outlined),
            label: Text(
              _selectingImage
                  ? 'Opening gallery...'
                  : selectedBytes == null && currentImageUrl == null
                  ? 'Choose image'
                  : 'Change image',
            ),
          ),
          const Text(
            'PNG, JPG, GIF, or WEBP. Images are compressed for upload.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder();
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emojiController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Emoji',
                  border: border,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: border,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pointsController,
                enabled: !_saving,
                minLines: 4,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Note points, one per line',
                  border: border,
                ),
              ),
              const SizedBox(height: 12),
              _buildImagePicker(),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                enabled: !_saving,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Google Drive or website link (optional)',
                  border: border,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _orderController,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Display order',
                  border: border,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}

class _QuestionEditor extends StatefulWidget {
  final List<ApiTopic> topics;
  final Question? question;
  final Future<void> Function({
    required int topicId,
    required String prompt,
    required List<String> acceptedAnswers,
    required bool isActive,
    required int? checkpoint,
    AdminQuestionImage? image,
  })
  onSave;

  const _QuestionEditor({
    required this.topics,
    required this.question,
    required this.onSave,
  });

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late final TextEditingController _promptController;
  late final TextEditingController _answersController;
  late int _topicId;
  int? _checkpoint;
  late bool _isActive;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _selectingImage = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _promptController = TextEditingController(text: question?.question ?? '');
    _answersController = TextEditingController(
      text: question?.acceptedAnswers.join('\n') ?? '',
    );
    _topicId = question?.topicId ?? widget.topics.first.id;
    _checkpoint = question?.checkpoint;
    _isActive = question?.isActive ?? true;
  }

  @override
  void dispose() {
    _promptController.dispose();
    _answersController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectingImage) return;
    setState(() {
      _selectingImage = true;
      _error = null;
    });
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 65,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 900 * 1024) {
        if (!mounted) return;
        setState(() {
          _error =
              'The selected image is still too large to upload. '
              'Please choose a smaller image.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _error =
            'Image picker is not registered. Fully stop and rebuild the app.';
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not open the photo library: ${error.message ?? error.code}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not choose an image: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _selectingImage = false);
      }
    }
  }

  Future<void> _save() async {
    final prompt = _promptController.text.trim();
    final answers = _answersController.text
        .split('\n')
        .map((answer) => answer.trim())
        .where((answer) => answer.isNotEmpty)
        .toList();
    if (prompt.isEmpty || answers.isEmpty) {
      setState(() => _error = 'Question and at least one answer are required.');
      return;
    }
    if (_checkpoint == null) {
      setState(() => _error = 'Choose the checkpoint this question belongs to.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        topicId: _topicId,
        prompt: prompt,
        acceptedAnswers: answers,
        isActive: _isActive,
        checkpoint: _checkpoint,
        image: _selectedImageBytes == null
            ? null
            : AdminQuestionImage(
                filename: _selectedImageName ?? 'question.jpg',
                bytes: _selectedImageBytes!,
              ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString().replaceFirst('HttpException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(widget.question == null ? 'New Question' : 'Edit Question'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _topicId,
                isExpanded: true,
                decoration: _fieldDecoration(
                  'Topic',
                  helperText: _selectedTopicName,
                ),
                selectedItemBuilder: (context) => widget.topics
                    .map(
                      (topic) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          topic.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                items: widget.topics
                    .map(
                      (topic) => DropdownMenuItem(
                        value: topic.id,
                        child: Text(
                          topic.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _topicId = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _checkpoint,
                isExpanded: true,
                decoration: _fieldDecoration(
                  'Checkpoint',
                  helperText: 'The later the square, the harder the question',
                ),
                items: boardCheckpoints
                    .map(
                      (checkpoint) => DropdownMenuItem(
                        value: checkpoint.square,
                        child: Text(
                          checkpoint.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _checkpoint = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                enabled: !_saving,
                maxLines: 3,
                decoration: _fieldDecoration(
                  'Question',
                  hintText: 'Type the question here',
                ),
              ),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 16),
              TextField(
                controller: _answersController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 7,
                decoration: _fieldDecoration(
                  'Accepted answers, one per line',
                  hintText: '0.5\n0.50\n1/2',
                ),
              ),
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Example: 0.5, 0.50, and 1/2 can be entered on separate lines.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final selectedBytes = _selectedImageBytes;
    final currentImageUrl = widget.question?.imageUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question image (optional)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          if (selectedBytes != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                selectedBytes,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Text(_selectedImageName ?? 'Selected image'),
          ] else if (currentImageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                currentImageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Text('Current image could not be loaded.'),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Current image'),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _saving || _selectingImage ? null : _pickImage,
            icon: _selectingImage
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image_outlined),
            label: Text(
              _selectingImage
                  ? 'Opening gallery...'
                  : selectedBytes == null && currentImageUrl == null
                  ? 'Choose image'
                  : 'Change image',
            ),
          ),
          const Text(
            'PNG, JPG, GIF, or WEBP. Images are compressed for upload.',
          ),
        ],
      ),
    );
  }

  String get _selectedTopicName {
    for (final topic in widget.topics) {
      if (topic.id == _topicId) {
        return 'Selected topic: ${topic.name}';
      }
    }
    return '';
  }

  InputDecoration _fieldDecoration(
    String label, {
    String? hintText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      helperText: helperText,
      helperMaxLines: 2,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _LecturerScreenState._red,
          width: 2,
        ),
      ),
    );
  }
}
