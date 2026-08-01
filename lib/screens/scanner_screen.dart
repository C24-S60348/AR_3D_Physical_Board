import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import '../data/questions_data.dart';
import '../services/ar3d_api.dart';
import '../utils/emulator_check.dart';

// Server topic holding the Sejarah Melaka questions for the scanned landmarks.
const _sejarahTopic = 'Tourism Melaka';

// The Soal Selidik button opens the shared i-GB questionnaire in the browser
// rather than the in-app form; SurveyScreen is kept for the /survey route.
const _surveyFormUrl =
    'https://docs.google.com/document/d/1ChbU4IMW7VhZlvz1j5wR8oxkaac9YKgXy23pBwzAZAg/edit?usp=sharing';

// Map from ARCore image name → (display name, asset path, place code, level)
const _placeInfo = <String, Map<String, String>>{
  'kotaafamosa-new': {
    'name': "Kota A'Famosa",
    'asset': 'assets/imagesscan/kotaafamosa-new.png',
    'place': 'kota-a-famosa',
    'topic': 'APLIKASI',
  },
  'kotaafamosa-new2': {
    'name': "Kota A'Famosa",
    'asset': 'assets/imagesscan/kotaafamosa-new2.png',
    'place': 'kota-a-famosa',
    'topic': 'APLIKASI',
  },
  'masjidcina-new': {
    'name': 'Masjid Cina Melaka',
    'asset': 'assets/imagesscan/masjidcina-new.png',
    'place': 'masjid-cina',
    'topic': 'ASAS',
  },
  'masjidcina-new2': {
    'name': 'Masjid Cina Melaka',
    'asset': 'assets/imagesscan/masjidcina-new2.png',
    'place': 'masjid-cina',
    'topic': 'ASAS',
  },
  'masjidselatmelaka-new': {
    'name': 'Masjid Selat Melaka',
    'asset': 'assets/imagesscan/masjidselatmelaka-new.png',
    'place': 'masjid-selat',
    'topic': 'SEDERHANA',
  },
  'masjidselatmelaka-new2': {
    'name': 'Masjid Selat Melaka',
    'asset': 'assets/imagesscan/masjidselatmelaka-new2.png',
    'place': 'masjid-selat',
    'topic': 'SEDERHANA',
  },
  'menaratamingsari-new': {
    'name': 'Menara Taming Sari',
    'asset': 'assets/imagesscan/menaratamingsari-new.png',
    'place': 'menara-taming-sari',
    'topic': 'APLIKASI',
  },
  'menaratamingsari-new2': {
    'name': 'Menara Taming Sari',
    'asset': 'assets/imagesscan/menaratamingsari-new2.png',
    'place': 'menara-taming-sari',
    'topic': 'APLIKASI',
  },
  'muziumsamudera-new': {
    'name': 'Muzium Samudera',
    'asset': 'assets/imagesscan/muziumsamudera-new.png',
    'place': 'muzium-samudera',
    'topic': 'ASAS',
  },
  'muziumsamudera-new2': {
    'name': 'Muzium Samudera',
    'asset': 'assets/imagesscan/muziumsamudera-new2.png',
    'place': 'muzium-samudera',
    'topic': 'ASAS',
  },
  'pantaiklebang-new': {
    'name': 'Pantai Klebang',
    'asset': 'assets/imagesscan/pantaiklebang-new.png',
    'place': 'pantai-klebang',
    'topic': 'ANALISIS',
  },
  'pantaiklebang-new2': {
    'name': 'Pantai Klebang',
    'asset': 'assets/imagesscan/pantaiklebang-new2.png',
    'place': 'pantai-klebang',
    'topic': 'ANALISIS',
  },
  'stadiumhangjebat-new': {
    'name': 'Stadium Hang Jebat',
    'asset': 'assets/imagesscan/stadiumhangjebat-new.png',
    'place': 'stadium-hang-jebat',
    'topic': 'CABARAN',
  },
  'stadiumhangjebat-new2': {
    'name': 'Stadium Hang Jebat',
    'asset': 'assets/imagesscan/stadiumhangjebat-new2.png',
    'place': 'stadium-hang-jebat',
    'topic': 'CABARAN',
  },
};

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  ARSessionManager? _sessionManager;

  String _playerName = '';
  String _topic = 'Sejarah Melaka';

  bool _isEmulator = false;
  bool _deviceChecked = false;

  // Flip card state
  bool _showingFlipCard = false;
  bool _isHandlingDetection = false;
  bool _openingSurvey = false;
  bool _cameraActive = true;
  int _cameraGeneration = 0;
  int _detectionGeneration = 0;
  String? _detectedImageName;
  late AnimationController _flipController;
  late Animation<double> _flipAnim;

  // Question card state
  bool _showingQuestion = false;
  int _score = 0;
  int _questionsAnswered = 0;
  Question? _currentQuestion;
  final TextEditingController _answerController = TextEditingController();
  String? _submittedAnswer;
  bool? _answerCorrect;
  // The public question API hides the answers, so the server tells us what the
  // correct one was when it grades a submission.
  String? _revealedAnswer;
  bool _answered = false;
  bool _submittingAnswer = false;
  ImageProvider? _frozenFrame;

  late AnimationController _cardAnimController;
  late Animation<double> _cardScale;

  static const _red = Color(0xFF8B1A1A);

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _cardAnimController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _cardScale = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.elasticOut,
    );

    _checkIfEmulator();
  }

  Future<void> _checkIfEmulator() async {
    final emulator = await isRunningOnEmulator();
    if (mounted) {
      setState(() {
        _isEmulator = emulator;
        _deviceChecked = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _playerName = args['playerName'] as String? ?? '';
      _topic = args['topic'] as String? ?? 'Sejarah Melaka';
    }
  }

  @override
  void dispose() {
    _sessionManager?.dispose();
    _answerController.dispose();
    _flipController.dispose();
    _cardAnimController.dispose();
    super.dispose();
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    if (!_cameraActive) {
      sessionManager.dispose();
      return;
    }
    _sessionManager = sessionManager;
    sessionManager.onInitialize(
      showAnimatedGuide: false,
      showPlanes: false,
      showFeaturePoints: false,
      handleTaps: false,
    );
    sessionManager.onImageDetected = (String imageName) {
      if (!_isHandlingDetection &&
          !_showingFlipCard &&
          !_showingQuestion &&
          mounted) {
        _triggerFlipCard(imageName);
      }
    };
  }

  Future<void> _triggerFlipCard(String imageName) async {
    _isHandlingDetection = true;
    final generation = ++_detectionGeneration;

    ImageProvider? frozen;
    try {
      frozen = await _sessionManager?.snapshot();
    } catch (_) {}

    if (!mounted || generation != _detectionGeneration) {
      _isHandlingDetection = false;
      return;
    }

    // Removing ARView releases ARCore and the camera while the result is shown.
    setState(() {
      _frozenFrame = frozen;
      _cameraActive = false;
      _sessionManager = null;
    });

    final normalizedName = imageName.toLowerCase().replaceAll(
      RegExp(r'\.(png|jpg|jpeg)$'),
      '',
    );
    final place = _placeInfo[normalizedName]?['place'];
    // The card sets the difficulty (ASAS..CABARAN); the topic picked on the
    // home screen sets the subject. Only Tourism Melaka is answered from the
    // landmark's own bank.
    final cardLevel = _placeInfo[normalizedName]?['topic'];
    final wantsSejarah = _topic == _sejarahTopic;
    // Level buckets only exist under the secondary-school bank on the server;
    // Primary and Higher Education are drawn whole.
    final useLevel =
        _topic == 'Maths for Secondary Students' &&
        cardLevel != null &&
        questionsByLevel.containsKey(cardLevel);

    List<Question> questions = const [];
    try {
      // Landmarks carry their own Sejarah Melaka question bank; fall back to
      // the topic bank when the server has none for this place yet.
      if (wantsSejarah && place != null) {
        final placeQuestions = await Ar3dApi.getQuestions(
          _sejarahTopic,
          place: place,
        );
        // An older server ignores the filter and returns the whole topic.
        questions = placeQuestions.where((q) => q.place == place).toList();
      }
      if (questions.isEmpty) {
        questions = useLevel
            ? await Ar3dApi.getQuestions(_topic, level: cardLevel)
            : await Ar3dApi.getQuestions(_topic);
        if (useLevel) {
          questions = questions.where((q) => q.level == cardLevel).toList();
        }
      }
    } catch (_) {
      // Keep scanning available when the configured server cannot be reached.
    }
    if (questions.isEmpty) {
      questions = useLevel
          ? getQuestionsForTopic(cardLevel)
          : getQuestionsForTopic(_topic);
    }
    if (questions.isEmpty) {
      if (mounted && generation == _detectionGeneration) {
        setState(() {
          _isHandlingDetection = false;
          _frozenFrame = null;
          _cameraActive = true;
          _cameraGeneration++;
        });
      }
      return;
    }
    final q = questions[Random().nextInt(questions.length)];

    if (!mounted || generation != _detectionGeneration) {
      _isHandlingDetection = false;
      return;
    }
    setState(() {
      _detectedImageName = normalizedName;
      _showingFlipCard = true;
      _currentQuestion = q;
      _answerController.clear();
      _submittedAnswer = null;
      _answerCorrect = null;
      _revealedAnswer = null;
      _answered = false;
      _submittingAnswer = false;
    });
    _isHandlingDetection = false;

    _flipController.reset();
    // Auto-flip to back after 1.8 seconds
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && _showingFlipCard && generation == _detectionGeneration) {
        _flipController.forward();
      }
    });
  }

  void _goToQuestion() {
    setState(() {
      _showingFlipCard = false;
      _showingQuestion = true;
    });
    _cardAnimController.forward(from: 0);
  }

  void _scanAgain() {
    _detectionGeneration++;
    _isHandlingDetection = false;
    _flipController.reset();
    setState(() {
      _showingFlipCard = false;
      _showingQuestion = false;
      _frozenFrame = null;
      _detectedImageName = null;
      _currentQuestion = null;
      _answerController.clear();
      _submittedAnswer = null;
      _answerCorrect = null;
      _revealedAnswer = null;
      _answered = false;
      _submittingAnswer = false;
      _cameraActive = true;
      _cameraGeneration++;
    });
  }

  Future<void> _submitAnswer(String answer) async {
    final submitted = answer.trim();
    if (_answered || _submittingAnswer || submitted.isEmpty) return;
    final question = _currentQuestion!;
    setState(() => _submittingAnswer = true);

    var isCorrect = question.matchesAnswer(submitted);
    var revealed = question.correctAnswer;
    try {
      final result = await Ar3dApi.submitAnswer(
        playerName: _playerName,
        question: question,
        answer: submitted,
        detectedImageName: _detectedImageName,
      );
      if (result != null) {
        isCorrect = result.isCorrect;
        if (result.correctAnswer.isNotEmpty) revealed = result.correctAnswer;
      }
    } catch (_) {
      // Use local grading if the server becomes unavailable mid-session.
    }

    if (!mounted) return;
    setState(() {
      _submittedAnswer = submitted;
      _answerCorrect = isCorrect;
      _revealedAnswer = revealed;
      _answered = true;
      _submittingAnswer = false;
      if (isCorrect) _score++;
      _questionsAnswered++;
    });
  }

  Future<void> _openSurvey() async {
    if (_openingSurvey) return;
    _openingSurvey = true;
    try {
      final opened = await launchUrl(
        Uri.parse(_surveyFormUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka borang soal selidik.')),
        );
      }
    } finally {
      _openingSurvey = false;
    }
  }

  void _dismissQuestion() {
    _cardAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showingQuestion = false;
          _frozenFrame = null;
          _detectedImageName = null;
          _cameraActive = true;
          _cameraGeneration++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_deviceChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_isEmulator) {
      return _buildEmulatorPlaceholder(context);
    }
    return Scaffold(
      body: Stack(
        children: [
          // AR camera
          if (_cameraActive)
            ARView(
              key: ValueKey(_cameraGeneration),
              onARViewCreated: _onARViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.none,
            ),

          // Back button
          if (_cameraActive && !_showingFlipCard && !_showingQuestion)
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

          // Soal Selidik button
          if (_cameraActive && !_showingFlipCard && !_showingQuestion)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: _openSurvey,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Soal Selidik',
                    style: TextStyle(
                      color: _red,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),

          // Scan instruction
          if (_cameraActive && !_showingFlipCard && !_showingQuestion)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hala kamera ke papan permainan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Imbas kotak papan untuk dapatkan soalan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    if (_questionsAnswered > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Skor: $_score / $_questionsAnswered',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          if (_cameraActive && !_showingFlipCard && !_showingQuestion)
            const _ViewfinderOverlay(),

          // Frozen frame blur (behind both flip card and question)
          if (!_cameraActive && _frozenFrame != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Image(image: _frozenFrame!, fit: BoxFit.cover),
              ),
            ),

          if (!_cameraActive && _frozenFrame == null)
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),

          if (_isHandlingDetection && !_showingFlipCard)
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 3D Flip card
          if (_showingFlipCard)
            Center(
              child: _FlipPlaceCard(
                flipAnim: _flipAnim,
                imageName: _detectedImageName ?? '',
                placeInfo:
                    _placeInfo[_detectedImageName] ??
                    {'name': 'Tempat Melaka', 'asset': ''},
                onFlipManual: () {
                  if (_flipController.status == AnimationStatus.dismissed) {
                    _flipController.forward();
                  }
                },
                onGoToQuestion: _goToQuestion,
                onScanAgain: _scanAgain,
              ),
            ),

          // Question overlay
          if (_showingQuestion && _currentQuestion != null)
            ScaleTransition(
              scale: _cardScale,
              child: _QuestionOverlay(
                question: _currentQuestion!,
                answerController: _answerController,
                submittedAnswer: _submittedAnswer,
                answerCorrect: _answerCorrect,
                revealedAnswer: _revealedAnswer,
                answered: _answered,
                submitting: _submittingAnswer,
                score: _score,
                total: _questionsAnswered,
                onSubmit: _submitAnswer,
                onDismiss: _dismissQuestion,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmulatorPlaceholder(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        size: 80,
                        color: Colors.white30,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Pengimbas AR Tidak Disokong',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Ciri pengimbas memerlukan kamera peranti fizikal.\n\nSila gunakan telefon sebenar untuk mengimbas papan permainan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          '🖥️ Emulator dikesan — Kamera tidak tersedia',
                          style: TextStyle(
                            color: Colors.yellowAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3D Flip Card ─────────────────────────────────────────────────────────────

class _FlipPlaceCard extends StatelessWidget {
  final Animation<double> flipAnim;
  final String imageName;
  final Map<String, String> placeInfo;
  final VoidCallback onFlipManual;
  final VoidCallback onGoToQuestion;
  final VoidCallback onScanAgain;

  const _FlipPlaceCard({
    required this.flipAnim,
    required this.imageName,
    required this.placeInfo,
    required this.onFlipManual,
    required this.onGoToQuestion,
    required this.onScanAgain,
  });

  static const _red = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flipAnim,
      builder: (context, _) {
        final angle = flipAnim.value;
        final isFront = angle < pi / 2;

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        // Mirror back face so text/image isn't reversed
        final displayTransform = isFront
            ? transform
            : (Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle - pi));

        return GestureDetector(
          onTap: isFront ? onFlipManual : null,
          child: Transform(
            transform: displayTransform,
            alignment: Alignment.center,
            child: isFront ? _buildFront() : _buildBack(),
          ),
        );
      },
    );
  }

  Widget _buildFront() {
    final asset = placeInfo['asset'] ?? '';
    final name = placeInfo['name'] ?? 'Tempat Melaka';

    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Place image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: asset.isNotEmpty
                ? Image.asset(
                    asset,
                    width: 300,
                    height: 200,
                    fit: BoxFit.fitHeight,
                  )
                : Container(
                    width: 300,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
          ),
          // Place name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: const BoxDecoration(
              color: _red,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ketik untuk soalan →',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    final name = placeInfo['name'] ?? 'Tempat Melaka';

    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_red, Color(0xFF3a0a0a)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.quiz_rounded, color: Colors.amber, size: 52),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adakah ini gambar yang betul?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sahkan sebelum memulakan soalan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGoToQuestion,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'Ya, Mulakan Soalan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onScanAgain,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text(
                'Bukan, Imbas Semula',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Viewfinder ────────────────────────────────────────────────────────────────

class _ViewfinderOverlay extends StatelessWidget {
  const _ViewfinderOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(painter: _BracketPainter()),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 28.0;
    final corners = [
      [Offset(0, len), Offset.zero, Offset(len, 0)],
      [
        Offset(size.width - len, 0),
        Offset(size.width, 0),
        Offset(size.width, len),
      ],
      [
        Offset(size.width, size.height - len),
        Offset(size.width, size.height),
        Offset(size.width - len, size.height),
      ],
      [
        Offset(len, size.height),
        Offset(0, size.height),
        Offset(0, size.height - len),
      ],
    ];
    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Question overlay ──────────────────────────────────────────────────────────

class _QuestionOverlay extends StatelessWidget {
  final Question question;
  final TextEditingController answerController;
  final String? submittedAnswer;
  final bool? answerCorrect;
  final String? revealedAnswer;
  final bool answered;
  final bool submitting;
  final int score;
  final int total;
  final Future<void> Function(String) onSubmit;
  final VoidCallback onDismiss;

  const _QuestionOverlay({
    required this.question,
    required this.answerController,
    required this.submittedAnswer,
    required this.answerCorrect,
    required this.revealedAnswer,
    required this.answered,
    required this.submitting,
    required this.score,
    required this.total,
    required this.onSubmit,
    required this.onDismiss,
  });

  static const _red = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      alignment: Alignment.center,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height - 40,
        ),
        margin: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Text(question.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        question.landmark,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.topic,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Question
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  children: [
                    if (question.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          question.imageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              if (question.isMultipleChoice)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(children: _buildChoices()),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      TextField(
                        controller: answerController,
                        enabled: !answered && !submitting,
                        textInputAction: TextInputAction.done,
                        onSubmitted: onSubmit,
                        decoration: InputDecoration(
                          labelText: 'Taip jawapan anda',
                          hintText: 'Contoh: 0.5 atau 1/2',
                          prefixIcon: const Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!answered)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: submitting
                                ? null
                                : () => onSubmit(answerController.text),
                            icon: submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              submitting ? 'Menyemak...' : 'Hantar Jawapan',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              if (answered)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: answerCorrect == true
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          answerCorrect == true
                              ? 'Betul! Markah ditambah.'
                              : _wrongAnswerMessage(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: answerCorrect == true
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onDismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Imbas Seterusnya',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Pilih jawapan anda',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _wrongAnswerMessage() {
    final answer = revealedAnswer?.trim().isNotEmpty == true
        ? revealedAnswer!.trim()
        : question.correctAnswer;
    return answer.isEmpty ? 'Salah.' : 'Salah. Jawapan: $answer';
  }

  List<Widget> _buildChoices() {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    final revealed = revealedAnswer?.trim() ?? '';

    return List.generate(question.options.length, (index) {
      final option = question.options[index];
      final isChosen = submittedAnswer == option;
      final isAnswer =
          answered &&
          revealed.isNotEmpty &&
          answersAreEquivalent(option, revealed);

      Color border = Colors.grey.shade300;
      Color background = Colors.white;
      Color badge = _red;
      if (isAnswer) {
        border = Colors.green;
        background = Colors.green.shade50;
        badge = Colors.green.shade700;
      } else if (isChosen) {
        border = Colors.red;
        background = Colors.red.shade50;
        badge = Colors.red.shade700;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: answered || submitting ? null : () => onSubmit(option),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
                width: isChosen || isAnswer ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badge,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    index < letters.length ? letters[index] : '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
                if (isAnswer)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else if (isChosen)
                  const Icon(Icons.cancel, color: Colors.red, size: 20),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Soal Selidik Screen ───────────────────────────────────────────────────────

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  static const _red = Color(0xFF8B1A1A);

  static const _statusOptions = [
    'Pelajar',
    'Guru / Pendidik',
    'Pelancong',
    'Lain-lain',
  ];
  static const _ageGroupOptions = [
    '7 – 12 tahun',
    '13 – 17 tahun',
    '18 – 25 tahun',
    '26 tahun ke atas',
  ];
  static const _easinessOptions = ['Sangat Mudah', 'Mudah', 'Sederhana', 'Sukar'];
  static const _arExperienceOptions = [
    'Sangat Menarik',
    'Menarik',
    'Biasa-biasa Sahaja',
    'Tidak Menarik',
  ];
  static const _questionFitOptions = [
    'Sangat Sesuai',
    'Sesuai',
    'Kurang Sesuai',
    'Tidak Sesuai',
  ];

  // Section 1 — Maklumat Responden
  int? _status; // index into _statusOptions
  int? _ageGroup; // index into _ageGroupOptions

  // Section 2 — Pengalaman App
  int? _easiness; // index into _easinessOptions
  int? _arExperience; // index into _arExperienceOptions
  int? _questionFit; // index into _questionFitOptions

  // Section 3 — Penilaian & Cadangan
  int _starRating = 0;
  final _commentCtrl = TextEditingController();

  bool _submitted = false;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _status != null &&
      _ageGroup != null &&
      _easiness != null &&
      _arExperience != null &&
      _questionFit != null &&
      _starRating > 0;

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await Ar3dApi.submitSurvey(
        status: _statusOptions[_status!],
        ageGroup: _ageGroupOptions[_ageGroup!],
        easiness: _easinessOptions[_easiness!],
        arExperience: _arExperienceOptions[_arExperience!],
        questionFit: _questionFitOptions[_questionFit!],
        starRating: _starRating,
        comment: _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitError =
              'Tidak dapat menghantar maklum balas ke pelayan. Sila cuba lagi.';
          _submitting = false;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: _red,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Icon(
                    Icons.assignment_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soal Selidik i.-GB',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Maklum balas anda amat kami hargai',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _submitted ? _buildThankYou() : _buildForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // ── Section 1: Maklumat Responden ─────────────────────────────────
        _sectionTitle('📋 Bahagian A — Maklumat Responden'),
        const SizedBox(height: 12),

        _questionLabel('1. Apakah status anda?', required: true),
        _radioGroup(
          options: _statusOptions,
          selected: _status,
          onChanged: (v) => setState(() => _status = v),
        ),

        _questionLabel('2. Peringkat umur anda?', required: true),
        _radioGroup(
          options: _ageGroupOptions,
          selected: _ageGroup,
          onChanged: (v) => setState(() => _ageGroup = v),
        ),

        const Divider(height: 32),

        // ── Section 2: Pengalaman Menggunakan App ─────────────────────────
        _sectionTitle('📱 Bahagian B — Pengalaman Menggunakan App'),
        const SizedBox(height: 12),

        _questionLabel('3. Adakah app i.-GB mudah digunakan?', required: true),
        _radioGroup(
          options: _easinessOptions,
          selected: _easiness,
          onChanged: (v) => setState(() => _easiness = v),
        ),

        _questionLabel(
          '4. Adakah pengalaman AR (Augmented Reality) menarik?',
          required: true,
        ),
        _radioGroup(
          options: _arExperienceOptions,
          selected: _arExperience,
          onChanged: (v) => setState(() => _arExperience = v),
        ),

        _questionLabel(
          '5. Adakah soalan dalam app sesuai dengan topik?',
          required: true,
        ),
        _radioGroup(
          options: _questionFitOptions,
          selected: _questionFit,
          onChanged: (v) => setState(() => _questionFit = v),
        ),

        const Divider(height: 32),

        // ── Section 3: Penilaian & Cadangan ──────────────────────────────
        _sectionTitle('⭐ Bahagian C — Penilaian & Cadangan'),
        const SizedBox(height: 12),

        _questionLabel('6. Penilaian keseluruhan app i.-GB:', required: true),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final filled = i < _starRating;
            return GestureDetector(
              onTap: () => setState(() => _starRating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? Colors.amber : Colors.grey.shade400,
                  size: 40,
                ),
              ),
            );
          }),
        ),
        if (_starRating > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              [
                '',
                'Sangat Buruk',
                'Buruk',
                'Sederhana',
                'Baik',
                'Sangat Baik',
              ][_starRating],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _starRating >= 4
                    ? Colors.green.shade700
                    : _starRating == 3
                    ? Colors.orange
                    : Colors.red.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        const SizedBox(height: 20),

        _questionLabel('7. Cadangan atau komen anda: (Pilihan)'),
        const SizedBox(height: 8),
        TextField(
          controller: _commentCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Tulis cadangan anda di sini...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _red),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),

        if (_submitError != null) ...[
          const SizedBox(height: 12),
          Text(
            _submitError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ],

        const SizedBox(height: 28),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canSubmit && !_submitting ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _canSubmit
                        ? 'Hantar Maklum Balas'
                        : 'Sila lengkapkan semua soalan (★)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildThankYou() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Terima Kasih!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Maklum balas anda telah berjaya dihantar.\nPenilaian anda: ${'⭐' * _starRating}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tutup',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: _red,
      ),
    );
  }

  Widget _questionLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
          children: required
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: _red),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _radioGroup({
    required List<String> options,
    required int? selected,
    required void Function(int) onChanged,
  }) {
    return Column(
      children: List.generate(options.length, (i) {
        final isSelected = selected == i;
        return GestureDetector(
          onTap: () => onChanged(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _red.withOpacity(0.08) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? _red : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? _red : Colors.grey.shade400,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? _red : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
