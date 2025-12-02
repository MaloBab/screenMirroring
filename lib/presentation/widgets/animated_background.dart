import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundColor,
                AppTheme.surfaceColor,
                AppTheme.backgroundColor,
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: BackgroundPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    // Cercle 1
    paint.color = AppTheme.primaryColor.withAlpha(10);
    final offset1 = Offset(
      size.width * 0.2 + sin(animationValue * 2 * pi) * 50,
      size.height * 0.3 + cos(animationValue * 2 * pi) * 50,
    );
    canvas.drawCircle(offset1, 150, paint);

    // Cercle 2
    paint.color = AppTheme.secondaryColor.withAlpha(8);
    final offset2 = Offset(
      size.width * 0.8 + cos(animationValue * 2 * pi) * 30,
      size.height * 0.6 + sin(animationValue * 2 * pi) * 30,
    );
    canvas.drawCircle(offset2, 120, paint);

    // Cercle 3
    paint.color = AppTheme.primaryColor.withAlpha(6);
    final offset3 = Offset(
      size.width * 0.5 + sin(animationValue * 2 * pi + pi) * 40,
      size.height * 0.8 + cos(animationValue * 2 * pi + pi) * 40,
    );
    canvas.drawCircle(offset3, 100, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}