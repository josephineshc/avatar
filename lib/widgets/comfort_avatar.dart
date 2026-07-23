import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 편안함을 주는 것을 목표로 설계한 아바타 위젯입니다.
///
/// 디자인 의도:
/// - 숨쉬듯 은은하게 커졌다 작아지는 오라 → 긴장을 낮추는 리듬감
/// - 완만한 곡선의 눈(무표정도 화난 표정도 아닌 '차분한' 눈) → 위협적이지 않은 인상
/// - 아주 천천히 위아래로 흔들리는 idle 모션 → 정적인 이미지보다 살아있는 느낌
/// - 일정 주기로 자연스럽게 눈을 깜빡임 → 지켜보고 있다는 느낌을 줄여 부담 완화
class ComfortAvatar extends StatefulWidget {
  const ComfortAvatar({
    super.key,
    this.size = 160,
    this.baseColor = const Color(0xFFE8935B),
    this.auraColor = const Color(0xFF4F6F5C),
  });

  final double size;
  final Color baseColor;
  final Color auraColor;

  @override
  State<ComfortAvatar> createState() => _ComfortAvatarState();
}

class _ComfortAvatarState extends State<ComfortAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _bobController;
  Timer? _blinkTimer;
  bool _blink = false;

  @override
  void initState() {
    super.initState();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 4200), (_) async {
      if (!mounted) return;
      setState(() => _blink = true);
      await Future.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      setState(() => _blink = false);
    });
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _bobController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breatheController, _bobController]),
        builder: (context, _) {
          final breatheScale = 1 + (_breatheController.value * 0.07);
          final bobOffset = math.sin(_bobController.value * math.pi) * 6;

          return Stack(
            alignment: Alignment.center,
            children: [
              // 숨쉬는 오라
              Transform.scale(
                scale: breatheScale,
                child: Container(
                  width: widget.size * 1.3,
                  height: widget.size * 1.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.auraColor.withOpacity(0.22),
                        widget.auraColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // 얼굴 (천천히 위아래로 흔들림)
              Transform.translate(
                offset: Offset(0, -bobOffset),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _FacePainter(
                      baseColor: widget.baseColor,
                      blink: _blink,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter({required this.baseColor, required this.blink});

  final Color baseColor;
  final bool blink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 얼굴
    canvas.drawCircle(center, radius, Paint()..color = baseColor);

    // 볼
    final cheekPaint = Paint()..color = const Color(0xFFFF9B9B).withOpacity(0.32);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.42, center.dy + radius * 0.12),
      radius * 0.11,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.42, center.dy + radius * 0.12),
      radius * 0.11,
      cheekPaint,
    );

    final linePaint = Paint()
      ..color = const Color(0xFF26302A)
      ..strokeWidth = radius * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 눈
    if (blink) {
      canvas.drawLine(
        Offset(center.dx - radius * 0.34, center.dy - radius * 0.05),
        Offset(center.dx - radius * 0.12, center.dy - radius * 0.05),
        linePaint,
      );
      canvas.drawLine(
        Offset(center.dx + radius * 0.12, center.dy - radius * 0.05),
        Offset(center.dx + radius * 0.34, center.dy - radius * 0.05),
        linePaint,
      );
    } else {
      _drawCalmEye(
        canvas,
        Offset(center.dx - radius * 0.23, center.dy - radius * 0.02),
        radius,
        linePaint,
      );
      _drawCalmEye(
        canvas,
        Offset(center.dx + radius * 0.23, center.dy - radius * 0.02),
        radius,
        linePaint,
      );
    }

    // 입 (부드러운 미소)
    final mouthPath = Path()
      ..moveTo(center.dx - radius * 0.17, center.dy + radius * 0.28)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.42,
        center.dx + radius * 0.17,
        center.dy + radius * 0.28,
      );
    canvas.drawPath(mouthPath, linePaint);
  }

  void _drawCalmEye(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..moveTo(center.dx - radius * 0.11, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy - radius * 0.11,
        center.dx + radius * 0.11,
        center.dy,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FacePainter oldDelegate) {
    return oldDelegate.blink != blink || oldDelegate.baseColor != baseColor;
  }
}
