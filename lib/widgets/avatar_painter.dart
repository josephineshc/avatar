import 'package:flutter/material.dart';

/// 커스터마이징 값(베이스 종류, 머리 스타일, 색상)과
/// 실시간 표정 값(눈뜸 정도, 입벌림, 미소, 눈썹 올림)을 함께 받아 그리는
/// 통합 페인터입니다. 얼굴을 그대로 대체하는 '마스크' 용도이므로 옷/몸통은
/// 그리지 않습니다.
///
/// 좌표 기준은 240x240 정사각형이며, 실제 캔버스 크기에 맞춰 비율(s)로 스케일합니다.
class AvatarPainter extends CustomPainter {
  AvatarPainter({
    required this.baseId,
    required this.hairId,
    required this.baseColor,
    this.eyeOpenLeft = 1.0,
    this.eyeOpenRight = 1.0,
    this.mouthOpen = 0.0,
    this.smile = 0.3,
    this.browRaiseLeft = 0.0,
    this.browRaiseRight = 0.0,
    this.moodColor,
  });

  final String baseId;
  final String hairId;
  final Color baseColor;
  final double eyeOpenLeft;
  final double eyeOpenRight;
  final double mouthOpen;
  final double smile;
  final double browRaiseLeft;
  final double browRaiseRight;
  final Color? moodColor;

  static const _ink = Color(0xFF26302A);
  static const _hairColor = Color(0xFF3B322A);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0)
    final s = size.width / 240;
    Offset p(double x, double y) => Offset(x * s, y * s);
    double u(double v) => v * s;

    _drawEars(canvas, p, u);
    _drawHair(canvas, p, u);

    // 머리
    canvas.drawCircle(p(120, 118), u(70), Paint()..color = baseColor);

    _drawAnimalFeatures(canvas, p, u);

    // 볼
    final cheek = Paint()..color = const Color(0xFFFF9B9B).withOpacity(0.32);
    canvas.drawCircle(p(83, 132), u(8), cheek);
    canvas.drawCircle(p(157, 132), u(8), cheek);

    // 눈썹 (실시간 표정)
    _drawEyebrows(canvas, p, u);

    // 눈 (실시간 표정)
    _drawEye(canvas, p(100, 113), u, eyeOpenLeft);
    _drawEye(canvas, p(140, 113), u, eyeOpenRight);

    // 입 (실시간 표정)
    _drawMouth(canvas, p, u);

    if (moodColor != null) {
      canvas.drawCircle(p(176, 168), u(16), Paint()..color = moodColor!.withOpacity(0.18));
      canvas.drawCircle(p(176, 168), u(10), Paint()..color = moodColor!.withOpacity(0.9));
    }
  }

  void _drawEars(Canvas canvas, Offset Function(double, double) p, double Function(double) u) {
    switch (baseId) {
      case 'fox':
        _triangle(canvas, [p(55, 70), p(40, 15), p(95, 55)], baseColor);
        _triangle(canvas, [p(185, 70), p(200, 15), p(145, 55)], baseColor);
        _triangle(canvas, [p(60, 62), p(50, 32), p(85, 55)], const Color(0xFFFFF3E6));
        _triangle(canvas, [p(180, 62), p(190, 32), p(155, 55)], const Color(0xFFFFF3E6));
        break;
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
        break; // human-a / human-b: 귀 없음
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
      default:
        break; // none
    }
  }

  void _drawAnimalFeatures(Canvas canvas, Offset Function(double, double) p, double Function(double) u) {
    if (baseId == 'owl') {
      canvas.drawCircle(p(98, 112), u(24), Paint()..color = const Color(0xFFF5EFE2));
      canvas.drawCircle(p(142, 112), u(24), Paint()..color = const Color(0xFFF5EFE2));
      _triangle(canvas, [p(112, 132), p(128, 132), p(120, 150)], const Color(0xFFD9A24B));
    }
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

    // 올라간 정도에 비례해 눈썹이 눈에서 더 멀어지도록(위로 이동) 함
    final liftLeft = u(browRaiseLeft.clamp(0.0, 1.0) * 10);
    final liftRight = u(browRaiseRight.clamp(0.0, 1.0) * 10);

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

  void _drawEye(Canvas canvas, Offset c, double Function(double) u, double openAmount) {
    final o = openAmount.clamp(0.0, 1.0);
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
    final h = u(2.4) + u(9) * o;
    canvas.drawOval(Rect.fromCenter(center: c, width: u(14), height: h), Paint()..color = _ink);
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
        oldDelegate.eyeOpenLeft != eyeOpenLeft ||
        oldDelegate.eyeOpenRight != eyeOpenRight ||
        oldDelegate.mouthOpen != mouthOpen ||
        oldDelegate.smile != smile ||
        oldDelegate.browRaiseLeft != browRaiseLeft ||
        oldDelegate.browRaiseRight != browRaiseRight ||
        oldDelegate.moodColor != moodColor;
  }
}
