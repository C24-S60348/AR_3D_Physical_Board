import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../data/questions_data.dart';
import '../services/ar3d_api.dart';
import 'splash_screen.dart';

/// Topic image → asset path mapping (shared with home screen)
const Map<String, String> topicImageAssets = {
  'Maths for Primary Students':   'assets/images/topics/topic_maths_primary.png',
  'Maths for Secondary Students': 'assets/images/topics/topic_maths_secondary.png',
  'Maths for Higher Education':   'assets/images/topics/topic_maths_higher.png',
  'Tourism Melaka':               'assets/images/topics/topic_tourism_melaka.png',
};

/// Generic loading screen with coin-flip logo.
/// Pass arguments as: { 'destination': '/route', 'topic': 'TopicName' (optional), 'arguments': <anything> }
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fade;
  late AnimationController _flipController;
  late Animation<double> _flipAngle;
  String? _topic;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // Pause at front, then full spin — no stop at mirrored side
    _flipAngle = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 2 * pi)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_flipController);

    // Navigate after a short delay (enough to see one flip cycle)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final destination = args?['destination'] as String? ?? '/home';
      final destArgs = args?['arguments'];
      // Read topic for flipping image
      final topic = args?['topic'] as String?;
      setState(() => _topic = topic);

      // Warm the offline copy while the animation plays, so a scan later in
      // the game still has the lecturer's questions if the network drops.
      if (topic != null) {
        unawaited(
          Ar3dApi.getQuestions(topic).catchError((_) => const <Question>[]),
        );
      }

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, destination,
            arguments: destArgs);
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B1A1A),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _flipAngle,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(_flipAngle.value),
                    child: child,
                  );
                },
                child: _topic != null && topicImageAssets.containsKey(_topic)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          topicImageAssets[_topic!]!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const CoinLogoWidget(size: 200),
              ),
              const SizedBox(height: 28),
              const _PulsingDots(),
            ],
          ),
        ),
      ),
    );
  }
}

// Three pulsing dots to indicate loading
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _controllers.add(ctrl);
      _anims.add(
        Tween<double>(begin: 0.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut))
            .animate(ctrl),
      );
      // Stagger each dot by 200 ms
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Opacity(
            opacity: _anims[i].value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
