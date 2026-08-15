import 'dart:math';

import 'package:flutter/material.dart';

enum _ConfettiShape { circle, square, triangle }

class _ConfettiParticle {
  _ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    required this.shape,
    required this.rotation,
    required this.rotationSpeed,
    required this.gravity,
    required this.drag,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double size;
  final _ConfettiShape shape;
  double rotation;
  final double rotationSpeed;
  final double gravity;
  final double drag;
}

/// Lightweight confetti burst + rain for onboarding completion.
class OnboardingCelebrationConfetti extends StatefulWidget {
  const OnboardingCelebrationConfetti({
    super.key,
    this.burstTrigger = 0,
    this.burstOriginFraction = 0.42,
    this.rainIntensity = 0,
  });

  final int burstTrigger;
  final double burstOriginFraction;
  final double rainIntensity;

  @override
  State<OnboardingCelebrationConfetti> createState() =>
      _OnboardingCelebrationConfettiState();
}

class _OnboardingCelebrationConfettiState
    extends State<OnboardingCelebrationConfetti>
    with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFFFF5252),
    Color(0xFFFF9800),
    Color(0xFFFFEB3B),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFE91E63),
  ];

  static const _maxParticles = 100;

  final _particles = <_ConfettiParticle>[];
  final _random = Random();
  late AnimationController _frameController;
  Duration _lastElapsed = Duration.zero;
  int _lastBurstTrigger = 0;
  bool _burstPending = false;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _lastBurstTrigger = widget.burstTrigger;
    _frameController = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_onFrame);
    _frameController.repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 480), () {
        if (mounted) _requestBurst();
      });
    });
  }

  @override
  void didUpdateWidget(OnboardingCelebrationConfetti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstTrigger != _lastBurstTrigger) {
      _lastBurstTrigger = widget.burstTrigger;
      _requestBurst();
    }
  }

  @override
  void dispose() {
    _frameController.dispose();
    super.dispose();
  }

  void _requestBurst() {
    if (_size == Size.zero) {
      _burstPending = true;
      return;
    }
    _emitBurst();
  }

  void _tryPendingBurst() {
    if (!_burstPending || _size == Size.zero) return;
    _burstPending = false;
    _emitBurst();
  }

  void _onFrame() {
    if (!mounted || _size == Size.zero) return;

    final elapsed = _frameController.lastElapsedDuration ?? Duration.zero;
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    var dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (dt <= 0) return;
    if (dt > 0.05) dt = 0.05;

    _updateParticles(dt);

    final rain = widget.rainIntensity.clamp(0.0, 1.0);
    if (rain > 0 && _random.nextDouble() < rain * 0.35) {
      _spawnRainParticle();
    }
  }

  void _emitBurst() {
    if (_size == Size.zero) {
      _burstPending = true;
      return;
    }

    final origin = Offset(
      _size.width / 2,
      _size.height * widget.burstOriginFraction,
    );

    for (var i = 0; i < 64; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * pi * 0.9;
      final speed = 280 + _random.nextDouble() * 360;
      _particles.add(
        _ConfettiParticle(
          position: origin + Offset((_random.nextDouble() - 0.5) * 20, 0),
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: _colors[_random.nextInt(_colors.length)],
          size: 6 + _random.nextDouble() * 7,
          shape: _ConfettiShape.values[_random.nextInt(3)],
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 8,
          gravity: 520 + _random.nextDouble() * 160,
          drag: 0.985,
        ),
      );
    }

    while (_particles.length > _maxParticles) {
      _particles.removeAt(0);
    }
  }

  void _spawnRainParticle() {
    if (_size == Size.zero || _particles.length >= _maxParticles) return;

    _particles.add(
      _ConfettiParticle(
        position: Offset(_random.nextDouble() * _size.width, -12),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 36,
          120 + _random.nextDouble() * 80,
        ),
        color: _colors[_random.nextInt(_colors.length)],
        size: 5 + _random.nextDouble() * 6,
        shape: _ConfettiShape.values[_random.nextInt(3)],
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 6,
        gravity: 300 + _random.nextDouble() * 100,
        drag: 0.99,
      ),
    );
  }

  void _updateParticles(double dt) {
    for (final particle in _particles) {
      particle.velocity = Offset(
        particle.velocity.dx * pow(particle.drag, dt * 60).toDouble(),
        particle.velocity.dy + particle.gravity * dt,
      );
      particle.position += particle.velocity * dt;
      particle.rotation += particle.rotationSpeed * dt;
    }

    _particles.removeWhere(
      (p) =>
          p.position.dy > _size.height + 40 ||
          p.position.dx < -40 ||
          p.position.dx > _size.width + 40,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nextSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (nextSize != _size) {
          _size = nextSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _tryPendingBurst();
          });
        }

        return RepaintBoundary(
          child: CustomPaint(
            painter: _ConfettiPainter(
              _particles,
              repaint: _frameController,
            ),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, {super.repaint});

  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()..color = particle.color;
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);

      switch (particle.shape) {
        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, particle.size / 2, paint);
        case _ConfettiShape.square:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size,
              height: particle.size,
            ),
            paint,
          );
        case _ConfettiShape.triangle:
          final path = Path()
            ..moveTo(0, -particle.size / 2)
            ..lineTo(particle.size / 2, particle.size / 2)
            ..lineTo(-particle.size / 2, particle.size / 2)
            ..close();
          canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
