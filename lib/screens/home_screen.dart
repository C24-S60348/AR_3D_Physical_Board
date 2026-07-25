import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/questions_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  String _selectedTopic = 'Maths for Primary Students';
  final _formKey = GlobalKey<FormState>();
  late final PageController _topicPageController;
  double _currentPage = 0;

  // Logo tap effects
  late AnimationController _logoScaleCtrl;
  late Animation<double> _logoScale;
  late AnimationController _starsCtrl;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _showStars = false;
  final _diceRandom = Random();

  @override
  void initState() {
    super.initState();
    _topicPageController = PageController(viewportFraction: 0.58);
    _topicPageController.addListener(() {
      setState(() => _currentPage = _topicPageController.page ?? 0);
    });

    // Logo bounce: normal → big → normal
    _logoScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.10,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_logoScaleCtrl);

    // Stars burst: 0→1 (fly out) then fade
    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _starsCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showStars = false);
      }
    });
  }

  static const _red = Color(0xFF8B1A1A);
  static const _gold = Color(0xFFB8860B);

  void _onLogoTap() async {
    // Play sparkle sound
    await _audioPlayer.play(AssetSource('sounds/blinkingstar.mp3'));

    // Bounce logo
    _logoScaleCtrl.forward(from: 0);

    // Stars burst
    setState(() => _showStars = true);
    _starsCtrl.forward(from: 0);
  }

  /// 5 stars flying out from the logo edge outward — never over the logo face.
  List<Widget> _buildStars() {
    const directions = [
      Offset(0, -1), // top
      Offset(0.85, -0.85), // top-right
      Offset(1, 0.3), // right
      Offset(-0.8, 0.85), // bottom-left
      Offset(-0.9, -0.55), // top-left
    ];

    // Logo radius ~100px; stars start just outside the edge and travel further
    const logoEdge = 65.0;
    const travel = 65.0;

    return directions.map((dir) {
      return AnimatedBuilder(
        animation: _starsCtrl,
        builder: (context, child) {
          final t = _starsCtrl.value;
          // Start at logo edge, move outward
          final dist = logoEdge + travel * t;
          final dx = dir.dx * dist;
          final dy = dir.dy * dist;
          // Fade out in last 40%
          final opacity = t < 0.6
              ? 1.0
              : (1.0 - (t - 0.6) / 0.4).clamp(0.0, 1.0);

          return Transform.translate(
            offset: Offset(dx, dy),
            child: Opacity(opacity: opacity, child: child),
          );
        },
        child: const Text('⭐', style: TextStyle(fontSize: 16)),
      );
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _topicPageController.dispose();
    _logoScaleCtrl.dispose();
    _starsCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_off, color: _red),
              SizedBox(width: 8),
              Text(
                'Nama Diperlukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: const Text(
            'Sila masukkan nama pemain sebelum memulakan permainan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: _red, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      '/loading',
      arguments: {
        'destination': '/scanner',
        'topic': _selectedTopic,
        'arguments': {'playerName': name, 'topic': _selectedTopic},
      },
    );
  }

  void _rollDice() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => _DiceDialog(random: _diceRandom),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3a0a0a),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_red, Color(0xFF3a0a0a)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Header — tappable logo with star burst
                      Center(
                        child: GestureDetector(
                          onTap: _onLogoTap,
                          child: SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Logo with bounce scale
                                ScaleTransition(
                                  scale: _logoScale,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ColorFiltered(
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                        child: Image.asset(
                                          'assets/images/logo_igb.png',
                                          width: 138,
                                          height: 138,
                                        ),
                                      ),
                                      Image.asset(
                                        'assets/images/logo_igb.png',
                                        width: 128,
                                        height: 128,
                                      ),
                                    ],
                                  ),
                                ),
                                // Stars on top of logo
                                if (_showStars) ..._buildStars(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nama Pemain',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Taip nama disini',
                                prefixIcon: const Icon(
                                  Icons.person,
                                  color: _red,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: null,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Pilih Topik',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _red,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 160,
                              child: PageView.builder(
                                controller: _topicPageController,
                                itemCount: allTopics.length,
                                onPageChanged: (i) => setState(
                                  () => _selectedTopic = allTopics[i],
                                ),
                                itemBuilder: (context, i) {
                                  final distance = (_currentPage - i).abs();
                                  final scale = (1 - distance * 0.18).clamp(
                                    0.82,
                                    1.0,
                                  );
                                  return GestureDetector(
                                    onTap: () =>
                                        _topicPageController.animateToPage(
                                          i,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                        ),
                                    child: Transform.scale(
                                      scale: scale,
                                      child: _TopicCard(
                                        topic: allTopics[i],
                                        selected:
                                            _selectedTopic == allTopics[i],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Play button
                      ElevatedButton.icon(
                        onPressed: _startGame,
                        icon: const Icon(Icons.sports_esports, size: 24),
                        label: const Text(
                          'MAIN i.-GB',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/tutorial'),
                              icon: const Icon(Icons.menu_book, size: 20),
                              label: const Text(
                                'Tutorial',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white54,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/nota'),
                              icon: const Icon(Icons.notes, size: 20),
                              label: const Text(
                                'Nota',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white54,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _rollDice,
                        icon: const Icon(Icons.casino, size: 20),
                        label: const Text(
                          'Dice',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white70,
                          side: const BorderSide(
                            color: Colors.white54,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/lecturer'),
                        icon: const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 20,
                        ),
                        label: const Text(
                          'Lecturer Admin',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Colors.white54,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ? button top right
          Positioned(
            top: 12,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/about'),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final String topic;
  final bool selected;

  const _TopicCard({required this.topic, required this.selected});

  static const _topicImages = {
    'Maths for Primary Students':
        'assets/images/topics/topic_maths_primary.png',
    'Maths for Secondary Students':
        'assets/images/topics/topic_maths_secondary.png',
    'Maths for Higher Education': 'assets/images/topics/topic_maths_higher.png',
    'Tourism Melaka': 'assets/images/topics/topic_tourism_melaka.png',
  };

  @override
  Widget build(BuildContext context) {
    final imgPath = _topicImages[topic];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF8B1A1A) : Colors.transparent,
          width: selected ? 3 : 0,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF8B1A1A).withOpacity(0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(8),
          child: imgPath != null
              ? Image.asset(imgPath, fit: BoxFit.contain)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 44)),
                    Text(
                      topic,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Animated dice roll dialog: dice tumbles through random faces while
/// spinning and bouncing, then settles on the final roll with a pop.
class _DiceDialog extends StatefulWidget {
  final Random random;
  const _DiceDialog({required this.random});

  @override
  State<_DiceDialog> createState() => _DiceDialogState();
}

class _DiceDialogState extends State<_DiceDialog>
    with TickerProviderStateMixin {
  static const _red = Color(0xFF8B1A1A);
  static const _gold = Color(0xFFB8860B);

  late AnimationController _rollCtrl;
  late Animation<double> _spin;
  late Animation<double> _bounce;
  late AnimationController _popCtrl;
  late Animation<double> _pop;

  int _face = 1;
  int _result = 1;
  bool _rolling = false;

  @override
  void initState() {
    super.initState();

    _rollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _spin = Tween<double>(begin: 0, end: 4 * pi).animate(
      CurvedAnimation(parent: _rollCtrl, curve: Curves.easeOutCubic),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -40.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -40.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 75,
      ),
    ]).animate(_rollCtrl);

    _rollCtrl.addListener(() {
      // Cycle random faces while tumbling, lock final face near the end.
      if (_rollCtrl.value < 0.75) {
        final next = widget.random.nextInt(6) + 1;
        if (next != _face) setState(() => _face = next);
      } else if (_face != _result) {
        setState(() => _face = _result);
      }
    });
    _rollCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _rolling = false);
        _popCtrl.forward(from: 0);
      }
    });

    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pop = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 55,
      ),
    ]).animate(_popCtrl);

    _roll();
  }

  void _roll() {
    if (_rolling) return;
    _result = widget.random.nextInt(6) + 1;
    setState(() => _rolling = true);
    _rollCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _rollCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFF6E8)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎲 Lambung Dadu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _red,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_rollCtrl, _popCtrl]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _bounce.value),
                      child: Transform.rotate(
                        angle: _rolling ? _spin.value : 0,
                        child: Transform.scale(
                          scale: _rolling ? 1.0 : _pop.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _DiceFace(value: _face),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AnimatedOpacity(
              opacity: _rolling ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: Text(
                _rolling ? '...' : 'Anda dapat $_result!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _red,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _rolling ? null : _roll,
                    icon: const Icon(Icons.casino, size: 20),
                    label: const Text(
                      'Lambung',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _gold.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A dice face drawn with real pips (dots) instead of a unicode glyph.
class _DiceFace extends StatelessWidget {
  final int value;
  const _DiceFace({required this.value});

  static const _red = Color(0xFF8B1A1A);

  // Pip positions on a 3x3 grid (row, col) for faces 1-6.
  static const _pipLayouts = <int, List<List<int>>>{
    1: [[1, 1]],
    2: [[0, 2], [2, 0]],
    3: [[0, 2], [1, 1], [2, 0]],
    4: [[0, 0], [0, 2], [2, 0], [2, 2]],
    5: [[0, 0], [0, 2], [1, 1], [2, 0], [2, 2]],
    6: [[0, 0], [0, 2], [1, 0], [1, 2], [2, 0], [2, 2]],
  };

  @override
  Widget build(BuildContext context) {
    const size = 110.0;
    const pipSize = 18.0;
    const inset = 14.0;
    final pips = _pipLayouts[value] ?? const [[1, 1]];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFEDEDED)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _red, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          for (final pip in pips)
            Positioned(
              left: inset +
                  pip[1] * ((size - 2 * inset - pipSize) / 2),
              top: inset +
                  pip[0] * ((size - 2 * inset - pipSize) / 2),
              child: Container(
                width: pipSize,
                height: pipSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.3),
                    colors: [Color(0xFFC0392B), _red],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
