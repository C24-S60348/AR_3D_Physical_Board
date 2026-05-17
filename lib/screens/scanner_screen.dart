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

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  ARSessionManager? _sessionManager;

  String _playerName = '';
  String _topic = 'Sejarah Melaka';

  bool _isEmulator = false;
  bool _deviceChecked = false;

  bool _imageDetected = false;
  bool _showingCard = false;
  int _score = 0;
  int _questionsAnswered = 0;

  Question? _currentQuestion;
  int? _selectedAnswer;
  bool _answered = false;
  ImageProvider? _frozenFrame;

  late AnimationController _cardAnimController;
  late Animation<double> _cardScale;

  @override
  void initState() {
    super.initState();
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
                      const Text(
                        'Pengimbas AR Tidak Disokong',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
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
                        child: const Text(
                          '🖥️ Emulator dikesan — Kamera tidak tersedia',
                          style: TextStyle(color: Colors.yellowAccent, fontSize: 12),
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

  @override
  void dispose() {
    _sessionManager?.dispose();
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
      if (!_showingCard && mounted) {
        _triggerQuestion();
      }
    };
  }

  Future<void> _triggerQuestion() async {
    final questions = getQuestionsForTopic(_topic);
    if (questions.isEmpty || _showingCard) return;

    final q = questions[Random().nextInt(questions.length)];

    // Capture the current AR frame so we can show it blurred behind the card
    ImageProvider? frozen;
    try {
      frozen = await _sessionManager?.snapshot();
    } catch (_) {}

    if (!mounted || _showingCard) return;
    setState(() {
      _imageDetected = true;
      _showingCard = true;
      _currentQuestion = q;
      _selectedAnswer = null;
      _answered = false;
      _frozenFrame = frozen;
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

  void _dismissCard() {
    _cardAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showingCard = false;
          _imageDetected = false;
          _frozenFrame = null;
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
          // AR camera view fills entire screen
          ARView(
            onARViewCreated: _onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.none,
          ),

          // Floating back button (top-left)
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
          // Score badge (top-right)
          Positioned(
            top: 16,
            right: 16,
            child: _ScoreBadge(score: _score, total: _questionsAnswered),
          ),

          // Scan instruction banner (shown when not showing card)
          if (!_showingCard)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 32),
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

          // Viewfinder corner brackets
          if (!_showingCard) const _ViewfinderOverlay(),

          // Blurred frozen frame — shown when question card is open
          if (_showingCard)
            Positioned.fill(
              child: _frozenFrame != null
                  ? ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Image(
                        image: _frozenFrame!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(color: Colors.black.withOpacity(0.7)),
            ),

          // Question card overlay
          if (_showingCard && _currentQuestion != null)
            _QuestionOverlay(
              question: _currentQuestion!,
              selectedAnswer: _selectedAnswer,
              answered: _answered,
              scaleAnim: _cardScale,
              onSelect: _selectAnswer,
              onDismiss: _dismissCard,
            ),
        ],
      ),
    );
  }
}

// ── Viewfinder corner brackets ──────────────────────────────────────────────

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

// ── Question card overlay ────────────────────────────────────────────────────

class _QuestionOverlay extends StatelessWidget {
  final Question question;
  final int? selectedAnswer;
  final bool answered;
  final Animation<double> scaleAnim;
  final void Function(int) onSelect;
  final VoidCallback onDismiss;

  const _QuestionOverlay({
    required this.question,
    required this.selectedAnswer,
    required this.answered,
    required this.scaleAnim,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      alignment: Alignment.center,
      child: ScaleTransition(
        scale: scaleAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Card header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF8B1A1A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Text(
                      question.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

              // Question text
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Answer options
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: List.generate(question.options.length, (i) {
                    Color bg = Colors.grey.shade100;
                    Color border = Colors.grey.shade300;
                    Color textColor = Colors.black87;
                    if (answered) {
                      if (i == question.correctIndex) {
                        bg = Colors.green.shade100;
                        border = Colors.green;
                        textColor = Colors.green.shade800;
                      } else if (i == selectedAnswer) {
                        bg = Colors.red.shade100;
                        border = Colors.red;
                        textColor = Colors.red.shade800;
                      }
                    } else if (i == selectedAnswer) {
                      bg = const Color(0xFF8B1A1A).withOpacity(0.08);
                      border = const Color(0xFF8B1A1A);
                    }

                    return GestureDetector(
                      onTap: () => onSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${String.fromCharCode(65 + i)}.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                question.options[i],
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (answered && i == question.correctIndex)
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 18),
                            if (answered &&
                                i == selectedAnswer &&
                                i != question.correctIndex)
                              const Icon(Icons.cancel,
                                  color: Colors.red, size: 18),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Result + dismiss button
              if (answered)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selectedAnswer == question.correctIndex
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          selectedAnswer == question.correctIndex
                              ? '✅ Betul! Markah ditambah!'
                              : '❌ Salah. Cuba lagi kali seterusnya.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selectedAnswer == question.correctIndex
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
                            backgroundColor: const Color(0xFF8B1A1A),
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
}

// ── Score badge ──────────────────────────────────────────────────────────────

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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
