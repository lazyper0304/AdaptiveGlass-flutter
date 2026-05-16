import 'package:flutter/material.dart';

class PhotoScenePainter extends CustomPainter {
  const PhotoScenePainter({required this.variant});

  final int variant;

  @override
  void paint(Canvas canvas, Size size) {
    switch (variant % 9) {
      case 0:
        _paintCoast(canvas, size);
      case 1:
        _paintCave(canvas, size);
      case 2:
        _paintRoom(canvas, size);
      case 3:
        _paintBridge(canvas, size);
      case 4:
        _paintRace(canvas, size);
      case 5:
        _paintCity(canvas, size);
      case 6:
        _paintMinimal(canvas, size);
      case 7:
        _paintDarkroom(canvas, size);
      default:
        _paintForestBlur(canvas, size);
    }
  }

  void _paintCoast(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE6EDF0), Color(0xFF79DCE5), Color(0xFF204B52)],
        ).createShader(rect),
    );
    _drawHills(canvas, size, const Color(0xFF647A6A), 0.34);
    _drawHills(canvas, size, const Color(0xFF31413C), 0.43);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.42)
        ..cubicTo(
          size.width * 0.18,
          size.height * 0.38,
          size.width * 0.33,
          size.height * 0.46,
          size.width * 0.48,
          size.height * 0.38,
        )
        ..lineTo(size.width, size.height * 0.32)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFF159CB1).withValues(alpha: 0.68),
    );
    final cliff = Path()
      ..moveTo(size.width * 0.45, size.height)
      ..lineTo(size.width * 0.58, size.height * 0.56)
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.45,
        size.width * 0.76,
        size.height * 0.62,
      )
      ..lineTo(size.width, size.height * 0.54)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(cliff, Paint()..color = const Color(0xFF6B472C));
    canvas.drawPath(
      cliff.shift(Offset(0, -size.height * 0.04)),
      Paint()..color = const Color(0xFF344A31).withValues(alpha: 0.82),
    );
    _drawLighthouse(canvas, size, Offset(size.width * 0.73, size.height * 0.2));
    _drawClouds(canvas, size);
  }

  void _paintCave(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071211), Color(0xFF102521), Color(0xFF07100E)],
        ).createShader(rect),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.68),
        width: size.width * 0.78,
        height: size.height * 0.24,
      ),
      Paint()..color = const Color(0xFF0E5E58),
    );
    final opening = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.42,
        -size.height * 0.05,
        size.width * 0.78,
        size.height * 0.52,
      )
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 0.4,
        size.width * 0.18,
        size.height * 0.52,
      );
    canvas.drawPath(opening, Paint()..color = const Color(0xFF6FAE79));
    _drawLightBeam(canvas, size, Offset(size.width * 0.55, 0), 0.2);
    _drawLightBeam(canvas, size, Offset(size.width * 0.62, 0), 0.32);
  }

  void _paintRoom(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFD8C7A8), Color(0xFFF2EBDC), Color(0xFFB49A78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.38, 0, size.width * 0.22, size.height),
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.43,
        size.height * 0.1,
        size.width * 0.12,
        size.height * 0.44,
      ),
      Paint()..color = const Color(0xFF9EC3D2).withValues(alpha: 0.48),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.63, size.height * 0.7),
        width: size.width * 0.18,
        height: size.height * 0.2,
      ),
      Paint()..color = const Color(0xFFEAE2D4),
    );
    canvas.drawCircle(
      Offset(size.width * 0.56, size.height * 0.56),
      size.width * 0.025,
      Paint()..color = const Color(0xFF3E312B),
    );
  }

  void _paintBridge(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB9D0D9), Color(0xFF506955), Color(0xFF253127)],
        ).createShader(rect),
    );
    _drawHills(canvas, size, const Color(0xFF455A4D), 0.44);
    final bridgePaint = Paint()
      ..color = const Color(0xFFE7DCC7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height),
      Offset(size.width * 0.48, size.height * 0.52),
      bridgePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.9, size.height),
      Offset(size.width * 0.52, size.height * 0.52),
      bridgePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.63),
      size.width * 0.035,
      Paint()..color = const Color(0xFFFFC857),
    );
  }

  void _paintRace(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF181A1B));
    final colors = [
      const Color(0xFF7EFCF3),
      const Color(0xFFF74B4B),
      const Color(0xFFB6E25C),
      const Color(0xFFEAEAEA),
    ];
    for (var i = 0; i < 12; i++) {
      final y = size.height * (i / 11);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.55)
        ..strokeWidth = 8 + (i % 3) * 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(-size.width * 0.1, y + size.height * 0.34),
        Offset(size.width * 1.1, y - size.height * 0.38),
        paint,
      );
    }
    final car = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.56, size.height * 0.58),
        width: size.width * 0.22,
        height: size.height * 0.1,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(car, Paint()..color = const Color(0xFF0B1720));
    canvas.drawRRect(
      car.deflate(5),
      Paint()..color = const Color(0xFF16D9D3).withValues(alpha: 0.65),
    );
  }

  void _paintCity(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB45D3D), Color(0xFF332142), Color(0xFF11131C)],
        ).createShader(rect),
    );
    for (var i = 0; i < 8; i++) {
      final x = size.width * i / 8;
      final h = size.height * (0.24 + (i % 4) * 0.08);
      canvas.drawRect(
        Rect.fromLTWH(x, size.height - h, size.width * 0.1, h),
        Paint()..color = const Color(0xFF11131C),
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.24),
      size.width * 0.08,
      Paint()..color = const Color(0xFFFFC778).withValues(alpha: 0.82),
    );
  }

  void _paintMinimal(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF1EEE7));
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.08,
        size.width * 0.84,
        size.height * 0.66,
      ),
      Paint()..color = const Color(0xFF2D4F57),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.36),
        width: size.width * 0.44,
        height: size.height * 0.24,
      ),
      Paint()..color = const Color(0xFFCAD6D1),
    );
  }

  void _paintDarkroom(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF111016), Color(0xFF33221E), Color(0xFF09090D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.38),
      size.width * 0.18,
      Paint()..color = const Color(0xFFFFC579).withValues(alpha: 0.28),
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.46,
        size.width * 0.56,
        size.height * 0.16,
      ),
      Paint()..color = const Color(0xFF111016),
    );
  }

  void _paintForestBlur(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF20332B), Color(0xFF6F8B68), Color(0xFF111A16)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    for (var i = 0; i < 9; i++) {
      final x = size.width * (i / 8);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.width * 0.16, size.height),
        Paint()
          ..color = const Color(0xFF121A13).withValues(alpha: 0.45)
          ..strokeWidth = 10,
      );
    }
    _drawLightBeam(canvas, size, Offset(size.width * 0.3, 0), 0.24);
  }

  void _drawHills(Canvas canvas, Size size, Color color, double top) {
    final path = Path()
      ..moveTo(0, size.height * top)
      ..cubicTo(
        size.width * 0.22,
        size.height * (top - 0.14),
        size.width * 0.42,
        size.height * (top + 0.09),
        size.width * 0.66,
        size.height * (top - 0.03),
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * (top - 0.12),
        size.width,
        size.height * (top + 0.03),
        size.width,
        size.height * top,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawLighthouse(Canvas canvas, Size size, Offset top) {
    final body = Path()
      ..moveTo(top.dx - size.width * 0.03, top.dy + size.height * 0.42)
      ..lineTo(top.dx + size.width * 0.03, top.dy + size.height * 0.42)
      ..lineTo(top.dx + size.width * 0.02, top.dy + size.height * 0.04)
      ..lineTo(top.dx - size.width * 0.02, top.dy + size.height * 0.04)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFECEBE6));
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(top.dx, top.dy + size.height * 0.05),
        width: size.width * 0.06,
        height: size.height * 0.035,
      ),
      Paint()..color = const Color(0xFFD5342D),
    );
  }

  void _drawClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * (0.1 + i * 0.18), size.height * 0.12),
          width: size.width * 0.18,
          height: size.height * 0.045,
        ),
        paint,
      );
    }
  }

  void _drawLightBeam(Canvas canvas, Size size, Offset origin, double angle) {
    final path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(size.width * (angle + 0.18), size.height)
      ..lineTo(size.width * (angle + 0.34), size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant PhotoScenePainter oldDelegate) {
    return oldDelegate.variant != variant;
  }
}
