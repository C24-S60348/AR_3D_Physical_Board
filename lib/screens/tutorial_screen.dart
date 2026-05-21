import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _red = Color(0xFF8B1A1A);
  static const _gold = Color(0xFFB8860B);

  static const _steps = [
    _TutorialStep(
      title: 'Imbas Papan Permainan',
      description: 'Buka kamera dan hala ke kotak pada papan permainan fizikal i.-GB. Pastikan imej kotak kelihatan jelas dalam bingkai.',
      icon: Icons.qr_code_scanner,
      tag: '01',
    ),
    _TutorialStep(
      title: 'Kad Tempat Muncul',
      description: 'Apabila imej dikesan, kamera akan membeku dan kad tempat bersejarah Melaka akan muncul secara animasi 3D.',
      icon: Icons.style_rounded,
      tag: '02',
    ),
    _TutorialStep(
      title: 'Jawab Soalan',
      description: 'Ketik kad untuk balikkan ke soalan. Baca soalan dengan teliti dan pilih jawapan yang betul.',
      icon: Icons.quiz_rounded,
      tag: '03',
    ),
    _TutorialStep(
      title: 'Kumpul Ganjaran',
      description: 'Setiap jawapan betul memberikan markah kepada anda! Kumpul sebanyak mungkin markah untuk menang.',
      icon: Icons.emoji_events_rounded,
      tag: '04',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tutorial',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _StepPage(step: _steps[i], index: i),
              ),
            ),

            // Dots + nav
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicators
                  Row(
                    children: List.generate(_steps.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: _currentPage == i ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? Colors.amber : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),

                  // Next / Done button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _steps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentPage == _steps.length - 1 ? _gold : Colors.white,
                      foregroundColor: _currentPage == _steps.length - 1 ? Colors.white : _red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: Text(
                      _currentPage == _steps.length - 1 ? 'Mula Bermain!' : 'Seterusnya',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final String tag;

  const _TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.tag,
  });
}

class _StepPage extends StatelessWidget {
  final _TutorialStep step;
  final int index;

  const _StepPage({required this.step, required this.index});

  static const _red = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Illustration area
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _buildIllustration(index),
              ),
            ),

            // Text area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LANGKAH ${step.tag}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      step.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(int index) {
    switch (index) {
      case 0:
        return _PhoneScanIllustration();
      case 1:
        return _FlipCardIllustration();
      case 2:
        return _QuestionIllustration();
      case 3:
        return _RewardIllustration();
      default:
        return const SizedBox();
    }
  }
}

// ── Illustration: Phone scanning ─────────────────────────────────────────────

class _PhoneScanIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Phone frame
              Container(
                width: 140,
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Camera notch
                    Container(width: 40, height: 6, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(3))),
                    const SizedBox(height: 8),
                    // Screen
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Camera feed simulation
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2d5a27), Color(0xFF1a3a17)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            // Target card on "table"
                            Container(
                              width: 60,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                              ),
                              child: const Center(
                                child: Icon(Icons.account_balance, color: Color(0xFF8B1A1A), size: 22),
                              ),
                            ),
                            // Scan brackets
                            CustomPaint(
                              size: const Size(70, 52),
                              painter: _ScanBracketPainter(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Scan beam
              Positioned(
                top: 80,
                child: Container(
                  width: 90,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
                SizedBox(width: 6),
                Text('Mengimbas...', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    const len = 12.0;
    final corners = [
      [Offset(0, len), Offset.zero, Offset(len, 0)],
      [Offset(size.width - len, 0), Offset(size.width, 0), Offset(size.width, len)],
      [Offset(size.width, size.height - len), Offset(size.width, size.height), Offset(size.width - len, size.height)],
      [Offset(len, size.height), Offset(0, size.height), Offset(0, size.height - len)],
    ];
    for (final pts in corners) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy)..lineTo(pts[1].dx, pts[1].dy)..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Illustration: Flip card ───────────────────────────────────────────────────

class _FlipCardIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow card behind
          Positioned(
            top: 30,
            left: 60,
            child: Transform.rotate(
              angle: 0.1,
              child: Container(
                width: 160,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Main card
          Container(
            width: 160,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFe8d5c4),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: const Center(child: Icon(Icons.account_balance, color: Color(0xFF8B1A1A), size: 36)),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B1A1A),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: const Text("A'Famosa", textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ),
          // Flip arrow
          Positioned(
            right: 40,
            top: 25,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Color(0xFF8B1A1A), shape: BoxShape.circle),
              child: const Icon(Icons.flip, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustration: Question ────────────────────────────────────────────────────

class _QuestionIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF8B1A1A), borderRadius: BorderRadius.circular(10)),
              child: const Text('Soalan tentang A\'Famosa?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            _FakeOption(label: 'A. 1511', selected: false),
            _FakeOption(label: 'B. 1488', selected: true),
            _FakeOption(label: 'C. 1400', selected: false),
          ],
        ),
      ),
    );
  }
}

class _FakeOption extends StatelessWidget {
  final String label;
  final bool selected;
  const _FakeOption({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF8B1A1A).withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? const Color(0xFF8B1A1A) : Colors.grey.shade300),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        color: selected ? const Color(0xFF8B1A1A) : Colors.black87,
      )),
    );
  }
}

// ── Illustration: Reward ─────────────────────────────────────────────────────

class _RewardIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFB8860B), size: 72),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1A1A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFF8B1A1A).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Text(
              '+1 Ganjaran!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Skor: 3 / 4', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
