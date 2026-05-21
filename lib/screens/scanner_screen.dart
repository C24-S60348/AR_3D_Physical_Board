import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import '../data/questions_data.dart';
import '../utils/emulator_check.dart';

// Map from ARCore image name → (display name, asset path)
const _placeInfo = <String, Map<String, String>>{
  'afamosa':              {'name': "A'Famosa",                   'asset': 'assets/imagesscan/afamosa.png'},
  'chenghoontengtemple': {'name': 'Cheng Hoon Teng Temple',      'asset': 'assets/imagesscan/chenghoontengtemple.png'},
  'christchurchmelaka':  {'name': 'Christ Church Melaka',        'asset': 'assets/imagesscan/christchurchmelaka.png'},
  'junkerstreetmelaka':  {'name': 'Jonker Street Melaka',        'asset': 'assets/imagesscan/junkerstreetmelaka.png'},
  'masjidselatmelaka':   {'name': 'Masjid Selat Melaka',         'asset': 'assets/imagesscan/masjidselatmelaka.png'},
  'menaratamingsari':    {'name': 'Menara Taming Sari',          'asset': 'assets/imagesscan/menaratamingsari.png'},
  'muziumkapalselammelaka': {'name': 'Muzium Kapal Selam Melaka','asset': 'assets/imagesscan/muziumkapalselammelaka.png'},
  'stadhuysmelaka':      {'name': 'Stadthuys Melaka',            'asset': 'assets/imagesscan/stadhuysmelaka.png'},
  'stpaulhillchurch':    {'name': "St. Paul's Hill Church",      'asset': 'assets/imagesscan/stpaulhillchurch.png'},
  'trishaw':             {'name': 'Beca Melaka',                 'asset': 'assets/imagesscan/trishaw.png'},
  'sampleimagetoscan':   {'name': 'Tempat Melaka',               'asset': 'assets/imagesscan/sampleimagetoscan.png'},
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
  String? _detectedImageName;
  late AnimationController _flipController;
  late Animation<double> _flipAnim;

  // Question card state
  bool _showingQuestion = false;
  int _score = 0;
  int _questionsAnswered = 0;
  Question? _currentQuestion;
  int? _selectedAnswer;
  bool _answered = false;
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
    if (mounted) setState(() { _isEmulator = emulator; _deviceChecked = true; });
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
    _sessionManager = sessionManager;
    sessionManager.onInitialize(
      showAnimatedGuide: false,
      showPlanes: false,
      showFeaturePoints: false,
      handleTaps: false,
    );
    sessionManager.onImageDetected = (String imageName) {
      if (!_showingFlipCard && !_showingQuestion && mounted) {
        _triggerFlipCard(imageName);
      }
    };
  }

  Future<void> _triggerFlipCard(String imageName) async {
    ImageProvider? frozen;
    try {
      frozen = await _sessionManager?.snapshot();
    } catch (_) {}

    final questions = getQuestionsForTopic(_topic);
    if (questions.isEmpty) return;
    final q = questions[Random().nextInt(questions.length)];

    if (!mounted) return;
    setState(() {
      _detectedImageName = imageName.toLowerCase().replaceAll(RegExp(r'\.(png|jpg|jpeg)$'), '');
      _frozenFrame = frozen;
      _showingFlipCard = true;
      _currentQuestion = q;
      _selectedAnswer = null;
      _answered = false;
    });

    _flipController.reset();
    // Auto-flip to back after 1.8 seconds
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted && _showingFlipCard) _flipController.forward();
    });
  }

  void _goToQuestion() {
    setState(() {
      _showingFlipCard = false;
      _showingQuestion = true;
    });
    _cardAnimController.forward(from: 0);
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    final isCorrect = index == _currentQuestion!.correctIndex;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (isCorrect) _score++;
      _questionsAnswered++;
    });
  }

  void _dismissQuestion() {
    _cardAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showingQuestion = false;
          _frozenFrame = null;
          _detectedImageName = null;
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
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.none,
          ),

          // Back button
          if (!_showingFlipCard && !_showingQuestion)
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
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
            ),

          // Score badge
          if (!_showingFlipCard && !_showingQuestion)
            Positioned(
              top: 16,
              right: 16,
              child: _ScoreBadge(score: _score, total: _questionsAnswered),
            ),

          // Scan instruction
          if (!_showingFlipCard && !_showingQuestion)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Hala kamera ke papan permainan',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Imbas kotak papan untuk dapatkan soalan',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                    if (_questionsAnswered > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Skor: $_score / $_questionsAnswered',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          if (!_showingFlipCard && !_showingQuestion)
            const _ViewfinderOverlay(),

          // Frozen frame blur (behind both flip card and question)
          if ((_showingFlipCard || _showingQuestion) && _frozenFrame != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Image(image: _frozenFrame!, fit: BoxFit.cover),
              ),
            ),

          if ((_showingFlipCard || _showingQuestion) && _frozenFrame == null)
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.7))),

          // 3D Flip card
          if (_showingFlipCard)
            Center(
              child: _FlipPlaceCard(
                flipAnim: _flipAnim,
                imageName: _detectedImageName ?? '',
                placeInfo: _placeInfo[_detectedImageName] ?? {'name': 'Tempat Melaka', 'asset': ''},
                onFlipManual: () {
                  if (_flipController.status == AnimationStatus.dismissed) {
                    _flipController.forward();
                  }
                },
                onGoToQuestion: _goToQuestion,
              ),
            ),

          // Question overlay
          if (_showingQuestion && _currentQuestion != null)
            ScaleTransition(
              scale: _cardScale,
              child: _QuestionOverlay(
                question: _currentQuestion!,
                selectedAnswer: _selectedAnswer,
                answered: _answered,
                score: _score,
                total: _questionsAnswered,
                onSelect: _selectAnswer,
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
                    decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                      const Icon(Icons.qr_code_scanner, size: 80, color: Colors.white30),
                      const SizedBox(height: 24),
                      const Text('Pengimbas AR Tidak Disokong',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      const Text(
                        'Ciri pengimbas memerlukan kamera peranti fizikal.\n\nSila gunakan telefon sebenar untuk mengimbas papan permainan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text('🖥️ Emulator dikesan — Kamera tidak tersedia',
                            style: TextStyle(color: Colors.yellowAccent, fontSize: 12)),
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

  const _FlipPlaceCard({
    required this.flipAnim,
    required this.imageName,
    required this.placeInfo,
    required this.onFlipManual,
    required this.onGoToQuestion,
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
          BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Place image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: asset.isNotEmpty
                ? Image.asset(asset, width: 300, height: 200, fit: BoxFit.fitHeight)
                : Container(
                    width: 300,
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 60, color: Colors.grey),
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
          BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 30, offset: const Offset(0, 10)),
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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adakah anda bersedia untuk menjawab soalan?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onGoToQuestion,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'Teruskan ke Soalan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
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
      [Offset(size.width - len, 0), Offset(size.width, 0), Offset(size.width, len)],
      [Offset(size.width, size.height - len), Offset(size.width, size.height), Offset(size.width - len, size.height)],
      [Offset(len, size.height), Offset(0, size.height), Offset(0, size.height - len)],
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
  final int? selectedAnswer;
  final bool answered;
  final int score;
  final int total;
  final void Function(int) onSelect;
  final VoidCallback onDismiss;

  const _QuestionOverlay({
    required this.question,
    required this.selectedAnswer,
    required this.answered,
    required this.score,
    required this.total,
    required this.onSelect,
    required this.onDismiss,
  });

  static const _red = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: const BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Text(question.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(question.landmark,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                    child: Text(question.topic,
                        style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ),
                ],
              ),
            ),

            // Question
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Text(question.question,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.4),
                  textAlign: TextAlign.center),
            ),

            // Answers
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: List.generate(question.options.length, (i) {
                  Color bg = Colors.grey.shade100;
                  Color border = Colors.grey.shade300;
                  Color textColor = Colors.black87;
                  if (answered) {
                    if (i == question.correctIndex) { bg = Colors.green.shade100; border = Colors.green; textColor = Colors.green.shade800; }
                    else if (i == selectedAnswer) { bg = Colors.red.shade100; border = Colors.red; textColor = Colors.red.shade800; }
                  } else if (i == selectedAnswer) {
                    bg = const Color(0xFF8B1A1A).withOpacity(0.08);
                    border = _red;
                  }
                  return GestureDetector(
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                      child: Row(
                        children: [
                          Text('${String.fromCharCode(65 + i)}.', style: TextStyle(fontWeight: FontWeight.w700, color: textColor)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(question.options[i], style: TextStyle(color: textColor, fontSize: 13))),
                          if (answered && i == question.correctIndex) const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          if (answered && i == selectedAnswer && i != question.correctIndex) const Icon(Icons.cancel, color: Colors.red, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
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
                        color: selectedAnswer == question.correctIndex ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        selectedAnswer == question.correctIndex ? '✅ Betul! Markah ditambah!' : '❌ Salah. Cuba lagi kali seterusnya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selectedAnswer == question.correctIndex ? Colors.green.shade700 : Colors.red.shade700,
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Imbas Seterusnya', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text('Pilih jawapan anda', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Score badge ───────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int score;
  final int total;

  const _ScoreBadge({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        total == 0 ? '🏆 0' : '🏆 $score/$total',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
