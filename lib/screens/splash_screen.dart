import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fade;
  late AnimationController _flipController;
  late Animation<double> _flipAngle;

  @override
  void initState() {
    super.initState();

    // Fade in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // Coin flip: pause → flip → pause → flip back → repeat
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    // Pause at front, then full spin (0 → 2π) — no stop at mirrored side
    _flipAngle = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 2 * pi)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_flipController);

    Future.delayed(const Duration(milliseconds: 3200), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
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
          child: AnimatedBuilder(
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
            child: CoinLogoWidget(size: 200),
          ),
        ),
      ),
    );
  }
}

/// Shared coin logo widget used by both splash and loading screens.
class CoinLogoWidget extends StatelessWidget {
  final double size;
  const CoinLogoWidget({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: Image.asset(
            'assets/images/logo_igb.png',
            width: size + 14,
            height: size + 14,
          ),
        ),
        Image.asset(
          'assets/images/logo_igb.png',
          width: size,
          height: size,
        ),
      ],
    );
  }
}
