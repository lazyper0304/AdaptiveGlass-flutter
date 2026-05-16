import 'package:flutter/material.dart';

class AdaptiveGlassBackdrop extends StatelessWidget {
  const AdaptiveGlassBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF171A1F), Color(0xFF12161A), Color(0xFF101217)]
              : const [Color(0xFFF6FAF6), Color(0xFFEAF3F4), Color(0xFFF5F1E8)],
        ),
      ),
      child: CustomPaint(painter: _AmbientGlowPainter(isDark: isDark)),
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  const _AmbientGlowPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.shader =
        RadialGradient(
          colors: [
            (isDark ? const Color(0xFF355D43) : const Color(0xFF8CCF9A))
                .withValues(alpha: isDark ? 0.38 : 0.3),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.56, size.height * 0.84),
            radius: size.width * 0.55,
          ),
        );
    canvas.drawRect(Offset.zero & size, paint);

    paint.shader =
        RadialGradient(
          colors: [
            (isDark ? const Color(0xFF31505D) : const Color(0xFF8AD6E2))
                .withValues(alpha: isDark ? 0.24 : 0.34),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.55, 0),
            radius: size.width * 0.72,
          ),
        );
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
