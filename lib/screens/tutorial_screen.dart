import 'dart:math';

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
      description:
          'Buka kamera dan hala ke kotak pada papan permainan fizikal i.-GB. Pastikan imej kotak kelihatan jelas dalam bingkai.',
      icon: Icons.qr_code_scanner,
      tag: '01',
    ),
    _TutorialStep(
      title: 'Kad Tempat Muncul',
      description:
          'Apabila imej dikesan, kamera akan membeku dan kad tempat bersejarah Melaka akan muncul secara animasi 3D.',
      icon: Icons.style_rounded,
      tag: '02',
    ),
    _TutorialStep(
      title: 'Jawab Soalan',
      description:
          'Ketik kad untuk balikkan ke soalan. Baca soalan dengan teliti dan pilih jawapan yang betul.',
      icon: Icons.quiz_rounded,
      tag: '03',
    ),
    _TutorialStep(
      title: 'Kumpul Ganjaran',
      description:
          'Setiap jawapan betul memberikan markah kepada anda! Kumpul sebanyak mungkin markah untuk menang.',
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_red, Color(0xFF3a0a0a)],
          ),
        ),
        child: SafeArea(
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
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tutorial',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    // Step counter chip
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Container(
                        key: ValueKey(_currentPage),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${_steps.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Page content with subtle parallax scale
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) => AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double distance = 0;
                      if (_pageController.position.haveDimensions) {
                        distance = ((_pageController.page ?? 0) - i).abs();
                      }
                      final scale = (1 - distance * 0.06).clamp(0.9, 1.0);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: _StepPage(step: _steps[i], index: i),
                  ),
                ),
              ),

              // Dots + nav
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(
                        _steps.length,
                        (i) => GestureDetector(
                          onTap: () => _pageController.animateToPage(
                            i,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 6),
                            width: _currentPage == i ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? Colors.amber
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
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
                      icon: Icon(
                        _currentPage == _steps.length - 1
                            ? Icons.sports_esports
                            : Icons.arrow_forward,
                        size: 18,
                      ),
                      label: Text(
                        _currentPage == _steps.length - 1
                            ? 'Mula Bermain!'
                            : 'Seterusnya',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPage == _steps.length - 1
                            ? _gold
                            : Colors.white,
                        foregroundColor: _currentPage == _steps.length - 1
                            ? Colors.white
                            : _red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
  static const _gold = Color(0xFFB8860B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _gold.withValues(alpha: 0.55), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // Illustration area
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFF8EC), Color(0xFFFFEFD6)],
                  ),
                ),
                child: _buildIllustration(index),
              ),
            ),

            // Text area — fades and slides up on page entry
            Expanded(
              flex: 3,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(index),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - t)),
                    child: child,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_red, Color(0xFFB03030)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'LANGKAH ${step.tag}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(step.icon, color: _gold, size: 20),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        step.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
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

  Widget _buildIllustration(int index) {
    switch (index) {
      case 0:
        return const _PhoneScanIllustration();
      case 1:
        return const _FlipCardIllustration();
      case 2:
        return const _QuestionIllustration();
      case 3:
        return const _RewardIllustration();
      default:
        return const SizedBox();
    }
  }
}

// ── Illustration: Phone scanning (animated beam + blinking dot) ──────────────

class _PhoneScanIllustration extends StatefulWidget {
  const _PhoneScanIllustration();

  @override
  State<_PhoneScanIllustration> createState() => _PhoneScanIllustrationState();
}

class _PhoneScanIllustrationState extends State<_PhoneScanIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2d5a27),
                                    Color(0xFF1a3a17),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.account_balance,
                                  color: Color(0xFF8B1A1A),
                                  size: 22,
                                ),
                              ),
                            ),
                            // Pulsing scan brackets
                            AnimatedBuilder(
                              animation: _ctrl,
                              builder: (context, _) => Transform.scale(
                                scale: 1 + 0.06 * _ctrl.value,
                                child: CustomPaint(
                                  size: const Size(70, 52),
                                  painter: _ScanBracketPainter(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Sweeping scan beam
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => Positioned(
                  top: 50 + 105 * _ctrl.value,
                  child: Container(
                    width: 90,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.55),
                          blurRadius: 8,
                        ),
                      ],
                    ),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Blinking recording dot
                FadeTransition(
                  opacity: _ctrl,
                  child: const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.red,
                    size: 10,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Mengimbas...',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
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
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Illustration: Flip card (3D wobble flip) ─────────────────────────────────

class _FlipCardIllustration extends StatefulWidget {
  const _FlipCardIllustration();

  @override
  State<_FlipCardIllustration> createState() => _FlipCardIllustrationState();
}

class _FlipCardIllustrationState extends State<_FlipCardIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
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
          // Main card with a gentle 3D sway
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final sway = sin(_ctrl.value * 2 * pi) * 0.22;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(sway),
                child: child,
              );
            },
            child: Container(
              width: 160,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFe8d5c4),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.account_balance,
                          color: Color(0xFF8B1A1A),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B1A1A),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "A'Famosa",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Spinning flip badge
          Positioned(
            right: 40,
            top: 25,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Transform.rotate(
                angle: _ctrl.value * 2 * pi,
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF8B1A1A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flip, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustration: Question (animated option select) ─────────────────────────

class _QuestionIllustration extends StatefulWidget {
  const _QuestionIllustration();

  @override
  State<_QuestionIllustration> createState() => _QuestionIllustrationState();
}

class _QuestionIllustrationState extends State<_QuestionIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // Cycles the "selected" option: A -> B -> C -> A ...
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final selectedIndex = (_ctrl.value * 3).floor() % 3;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Soalan tentang A'Famosa?",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                _FakeOption(label: 'A. 1511', selected: selectedIndex == 0),
                _FakeOption(label: 'B. 1488', selected: selectedIndex == 1),
                _FakeOption(label: 'C. 1400', selected: selectedIndex == 2),
              ],
            );
          },
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF8B1A1A).withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? const Color(0xFF8B1A1A) : Colors.grey.shade300,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? const Color(0xFF8B1A1A) : Colors.black87,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: selected ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF8B1A1A),
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Illustration: Reward (bouncing trophy + sparkles) ────────────────────────

class _RewardIllustration extends StatefulWidget {
  const _RewardIllustration();

  @override
  State<_RewardIllustration> createState() => _RewardIllustrationState();
}

class _RewardIllustrationState extends State<_RewardIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bounce = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Sparkles orbiting the trophy
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) => Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 30 - 8 * _ctrl.value,
                        top: 12 + 6 * _ctrl.value,
                        child: Opacity(
                          opacity: 0.5 + 0.5 * _ctrl.value,
                          child: const Text(
                            '✨',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 26 - 6 * (1 - _ctrl.value),
                        top: 30 - 10 * _ctrl.value,
                        child: Opacity(
                          opacity: 1 - 0.5 * _ctrl.value,
                          child: const Text(
                            '⭐',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 55,
                        bottom: -2 - 6 * _ctrl.value,
                        child: Opacity(
                          opacity: 0.4 + 0.6 * _ctrl.value,
                          child: const Text(
                            '✨',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouncing trophy
                AnimatedBuilder(
                  animation: bounce,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, -8 * bounce.value),
                    child: child,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFB8860B),
                    size: 72,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Pulsing reward badge
          AnimatedBuilder(
            animation: bounce,
            builder: (context, child) => Transform.scale(
              scale: 1 + 0.05 * bounce.value,
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1A1A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B1A1A).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '+1 Ganjaran!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Skor: 3 / 4',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
