import 'package:flutter/material.dart';


class AvatarPainter extends CustomPainter {
  AvatarPainter({
    required this.baseId,
    required this.hairId,
    required this.baseColor,
    this.eyeShapeId = 'round',
    this.faceShapeId = 'round',
    this.noseShapeId = 'none',
    this.hasGlasses = false,
    this.hasLashes = false,
    this.blushColor = const Color(0xFFFF9B9B),
    this.eyeOpenLeft = 1.0,
    this.eyeOpenRight = 1.0,
    this.mouthOpen = 0.0,
    this.smile = 0.3,
    this.browRaiseLeft = 0.0,
    this.browRaiseRight = 0.0,
  });

  final String baseId;
  final String hairId;
  final Color baseColor;
  final String eyeShapeId;
  final String faceShapeId;
  final String noseShapeId;
  final bool hasGlasses;
  final bool hasLashes;
  final Color blushColor;
  final double eyeOpenLeft;
  final double eyeOpenRight;
  final double mouthOpen;
  final double smile;
  final double browRaiseLeft;
  final double browRaiseRight;

  static const _ink = Color(0xFF26302A);
  static const _hairColor = Color(0xFF3B322A);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 240;
    Offset p(double x, double y) => Offset(x * s, y * s);
    double u(double v) => v * s;

    final effectiveFaceShape = baseId == 'human' ? faceShapeId : 'round';

    _drawEars(canvas, p, u);
    _drawHair(canvas, p, u);

    _drawHeadShape(canvas, p, u, effectiveFaceShape);

    _drawAnimalFeatures(canvas, p, u);

    final cheek = Paint()..color = blushColor.withOpacity(0.45);
    canvas.drawCircle(p(83, 132), u(8), cheek);
    canvas.drawCircle(p(157, 132), u(8), cheek);

    _drawEyebrows(canvas, p, u);

    _drawNose(canvas, p, u);

    _drawEye(canvas, p(100, 113), u, eyeOpenLeft, isLeft: true);
    _drawEye(canvas, p(140, 113), u, eyeOpenRight, isLeft: false);

    if (hasGlasses) _drawGlasses(canvas, p, u);

    _drawMouth(canvas, p, u);
  }

  void _drawHeadShape(
    Canvas canvas,
    Offset Function(double, double) p,
    double Function(double) u,
    String faceShapeId,
  ) {
    final paint = Paint()..color = baseColor;
    switch (faceShapeId) {
      case 'oval':
        canvas.drawOval(Rect.fromCenter(center: p(120, 120), width: u(132), height: u(160)), paint);
        break;
      case 'heart':
        final path = Path()
          ..moveTo(p(120, 52).dx, p(120, 52).dy)
          ..cubicTo(p(192, 40).dx, p(192, 40).dy, p(202, 112).dx, p(202, 112).dy, p(120, 196).dx, p(120, 196).dy)
          ..cubicTo(p(38, 112).dx, p(38, 112).dy, p(48, 40).dx, p(48, 40).dy, p(120, 52).dx, p(120, 52).dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'square':
        final rect = Rect.fromCenter(center: p(120, 118), width: u(142), height: u(140));
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(u(34))), paint);
        break;
      default:
        canvas.drawCircle(p(120, 118), u(70), paint);
    }
  }

  void _drawEars(Canvas canvas, Offset Function(double, double) p, double Function(double) u) {
    switch (baseId) {
      case 'bear':
        canvas.drawCircle(p(58, 48), u(24), Paint()..color = baseColor);
        canvas.drawCircle(p(182, 48), u(24), Paint()..color = baseColor);
        canvas.drawCircle(p(58, 48), u(11), Paint()..color = const Color(0xFFFFF3E6));
        canvas.drawCircle(p(182, 48), u(11), Paint()..color = const Color(0xFFFFF3E6));
        break;
      case 'rabbit':
        canvas.drawOval(Rect.fromCenter(center: p(86, 22), width: u(28), height: u(110)), Paint()..color = baseColor);
        canvas.drawOval(Rect.fromCenter(center: p(154, 22), width: u(28), height: u(110)), Paint()..color = baseColor);
        canvas.drawOval(
          Rect.fromCenter(center: p(86, 26), width: u(12), height: u(84)),
          Paint()..color = const Color(0xFFFBEAEF),
        );
        canvas.drawOval(
          Rect.fromCenter(center: p(154, 26), width: u(12), height: u(84)),
          Paint()..color = const Color(0xFFFBEAEF),
        );
        break;
      case 'cat':
        _triangle(canvas, [p(65, 68), p(55, 25), p(95, 58)], baseColor);
        _triangle(canvas, [p(175, 68), p(185, 25), p(145, 58)], baseColor);
        break;
      default:
        break;
    }
  }

  void _drawHair(Canvas canvas, Offset Function(double, double) p, double Function(double) u) {
    final paint = Paint()..color = _hairColor.withOpacity(0.88);
    switch (hairId) {
      case 'short':
        canvas.drawOval(Rect.fromCenter(center: p(120, 88), width: u(152), height: u(116)), paint);
        break;
      case 'bun':
        canvas.drawOval(Rect.fromCenter(center: p(120, 88), width: u(152), height: u(116)), paint);
        canvas.drawCircle(p(120, 26), u(15), paint);
        break;
      case 'long':
        canvas.drawOval(Rect.fromCenter(center: p(120, 88), width: u(152), height: u(116)), paint);
        canvas.drawOval(Rect.fromCenter(center: p(66, 185), width: u(36), height: u(136)), paint);
        canvas.drawOval(Rect.fromCenter(center: p(174, 185), width: u(36), height: u(136)), paint);
        break;
      case 'ponytail':
        canvas.drawOval(Rect.fromCenter(center: p(120, 88), width: u(152), height: u(116)), paint);
        canvas.drawOval(Rect.fromCenter(center: p(182, 140), width: u(26), height: u(96)), paint);
        break;
      case 'curly':
        const curlPositions = [
          [65.0, 53.0],
          [90.0, 32.0],
          [120.0, 24.0],
          [150.0, 32.0],
          [175.0, 53.0],
          [48.0, 80.0],
          [192.0, 80.0],
        ];
        for (final pos in curlPositions) {
          canvas.drawCircle(p(pos[0], pos[1]), u(23), paint);
        }
        break;
      default:
        break;
    }
  }

  void _drawAnimalFeatures(Canvas canvas, Offset Function(double, double) p, double Function(double) u) {
    if (baseId == 'cat') {
      final whisker = Paint()
        ..color = const Color(0x30000000)
        ..strokeWidth = u(2);
      canvas.drawLine(p(42, 122), p(84, 118), whisker);
      canvas.drawLine(p(42, 134), p(84, 130), whisker);
      canvas.drawLine(p(198, 122), p(156, 118), whisker);
      canvas.drawLine(p(198, 134), p(156, 130), whisker);
    }
  }

  void _drawEyebrows(Canvas canvas, Offset Function(double, double) p, double Function(double) u) {
    final paint = Paint()
      ..color = _ink
      ..strokeWidth = u(4.2)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final liftLeft = u(browRaiseLeft.clamp(0.0, 1.0) * 16);
    final liftRight = u(browRaiseRight.clamp(0.0, 1.0) * 16);

    final leftBase = p(100, 96);
    canvas.drawLine(
      Offset(leftBase.dx - u(12), leftBase.dy - liftLeft),
      Offset(leftBase.dx + u(12), leftBase.dy - u(3) - liftLeft),
      paint,
    );

    final rightBase = p(140, 96);
    canvas.drawLine(
      Offset(rightBase.dx - u(12), rightBase.dy - u(3) - liftRight),
      Offset(rightBase.dx + u(12), rightBase.dy - liftRight),
      paint,
    );
  }

  void _drawNose(Canvas canvas, Offset Function(double, double) p, double Function(double) u) {
    final noseColor = _ink.withOpacity(0.5);
    switch (noseShapeId) {
      case 'dot':
        canvas.drawCircle(p(120, 127), u(2.8), Paint()..color = noseColor);
        break;
      case 'button':
        final path = Path()
          ..moveTo(p(115, 119).dx, p(115, 119).dy)
          ..quadraticBezierTo(p(120, 133).dx, p(120, 133).dy, p(125, 119).dx, p(125, 119).dy);
        canvas.drawPath(
          path,
          Paint()
            ..color = noseColor
            ..strokeWidth = u(2.6)
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
        break;
      case 'curve':
        canvas.drawLine(
          p(119, 116),
          p(122, 130),
          Paint()
            ..color = noseColor
            ..strokeWidth = u(2.4)
            ..strokeCap = StrokeCap.round,
        );
        break;
      default:
        break;
    }
  }

  void _drawGlasses(Canvas canvas, Offset Function(double, double) p, double Function(double) u) {
    final paint = Paint()
      ..color = _ink
      ..strokeWidth = u(3.2)
      ..style = PaintingStyle.stroke;

    final leftRect = Rect.fromCenter(center: p(100, 113), width: u(36), height: u(28));
    final rightRect = Rect.fromCenter(center: p(140, 113), width: u(36), height: u(28));
    canvas.drawRRect(RRect.fromRectAndRadius(leftRect, Radius.circular(u(9))), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightRect, Radius.circular(u(9))), paint);
    canvas.drawLine(p(118, 113), p(122, 113), paint);
    canvas.drawLine(p(82, 110), p(70, 104), paint);
    canvas.drawLine(p(158, 110), p(170, 104), paint);
  }

  void _drawEye(
    Canvas canvas,
    Offset c,
    double Function(double) u,
    double openAmount, {
    required bool isLeft,
  }) {
    var o = openAmount.clamp(0.0, 1.0);
    if (eyeShapeId == 'sleepy') o *= 0.6;

    if (o < 0.12) {
      final path = Path()
        ..moveTo(c.dx - u(9), c.dy)
        ..quadraticBezierTo(c.dx, c.dy + u(2.5), c.dx + u(9), c.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = _ink
          ..strokeWidth = u(4)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      return;
    }

    double eyeHeight = u(2.4) + u(9) * o;

    switch (eyeShapeId) {
      case 'almond':
        eyeHeight = u(2.0) + u(7) * o;
        final path = Path()
          ..moveTo(c.dx - u(9), c.dy)
          ..quadraticBezierTo(c.dx, c.dy - eyeHeight, c.dx + u(9), c.dy)
          ..quadraticBezierTo(c.dx, c.dy + eyeHeight, c.dx - u(9), c.dy)
          ..close();
        canvas.drawPath(path, Paint()..color = _ink);
        break;
      case 'sparkle':
        canvas.drawOval(Rect.fromCenter(center: c, width: u(14), height: eyeHeight), Paint()..color = _ink);
        canvas.drawCircle(Offset(c.dx + u(2.6), c.dy - eyeHeight * 0.16), u(2.2), Paint()..color = Colors.white);
        break;
      case 'catEye':
        final dir = isLeft ? -1 : 1;
        eyeHeight = u(2.0) + u(7) * o;
        final path = Path()
          ..moveTo(c.dx - dir * u(9), c.dy + u(1))
          ..quadraticBezierTo(c.dx, c.dy - eyeHeight, c.dx + dir * u(12), c.dy - eyeHeight * 0.7)
          ..quadraticBezierTo(c.dx, c.dy + eyeHeight * 0.5, c.dx - dir * u(9), c.dy + u(1))
          ..close();
        canvas.drawPath(path, Paint()..color = _ink);
        break;
      case 'doe':
        eyeHeight = u(3.4) + u(11) * o;
        canvas.drawOval(Rect.fromCenter(center: c, width: u(17), height: eyeHeight), Paint()..color = _ink);
        canvas.drawCircle(
          Offset(c.dx - u(2), c.dy - eyeHeight * 0.2),
          u(2.8),
          Paint()..color = Colors.white.withOpacity(0.85),
        );
        break;
      default: // round, sleepy
        canvas.drawOval(Rect.fromCenter(center: c, width: u(14), height: eyeHeight), Paint()..color = _ink);
    }

    if (hasLashes) _drawLashes(canvas, c, u, isLeft, eyeHeight);
  }

  void _drawLashes(Canvas canvas, Offset c, double Function(double) u, bool isLeft, double eyeHeight) {
    final paint = Paint()
      ..color = _ink
      ..strokeWidth = u(1.6)
      ..strokeCap = StrokeCap.round;
    final dir = isLeft ? -1 : 1;
    final topY = c.dy - eyeHeight / 2;
    const xOffsets = [-4.0, -1.0, 2.0];
    for (var i = 0; i < xOffsets.length; i++) {
      final baseX = c.dx + u(xOffsets[i]);
      final tipDx = dir * u(1.2 + i * 0.6);
      canvas.drawLine(
        Offset(baseX, topY),
        Offset(baseX + tipDx, topY - u(2.6)),
        paint,
      );
    }
  }

  void _drawMouth(Canvas canvas, Offset Function(double, double) p, double Function(double) u) {
    final openAmt = mouthOpen.clamp(0.0, 1.0);
    final smileAmt = smile.clamp(0.0, 1.0);
    final halfWidth = 12 + smileAmt * 6.0;
    final curve = 5 + smileAmt * 18.0;
    final anchor = p(120, 140);

    if (openAmt < 0.08) {
      final path = Path()
        ..moveTo(anchor.dx - u(halfWidth), anchor.dy)
        ..quadraticBezierTo(anchor.dx, anchor.dy + u(curve), anchor.dx + u(halfWidth), anchor.dy);
      canvas.drawPath(
        path,
        Paint()
          ..color = _ink
          ..strokeWidth = u(4)
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    } else {
      final h = u(5) + u(20) * openAmt;
      final rect = Rect.fromCenter(center: Offset(anchor.dx, anchor.dy + u(4)), width: u(halfWidth * 1.7), height: h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(h / 2)), Paint()..color = _ink);
    }
  }

  void _triangle(Canvas canvas, List<Offset> pts, Color color) {
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (final pt in pts.skip(1)) {
      path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant AvatarPainter oldDelegate) {
    return oldDelegate.baseId != baseId ||
        oldDelegate.hairId != hairId ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.eyeShapeId != eyeShapeId ||
        oldDelegate.faceShapeId != faceShapeId ||
        oldDelegate.noseShapeId != noseShapeId ||
        oldDelegate.hasGlasses != hasGlasses ||
        oldDelegate.hasLashes != hasLashes ||
        oldDelegate.blushColor != blushColor ||
        oldDelegate.eyeOpenLeft != eyeOpenLeft ||
        oldDelegate.eyeOpenRight != eyeOpenRight ||
        oldDelegate.mouthOpen != mouthOpen ||
        oldDelegate.smile != smile ||
        oldDelegate.browRaiseLeft != browRaiseLeft ||
        oldDelegate.browRaiseRight != browRaiseRight;
  }
}