import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/face_tracking_controller.dart';
import '../widgets/avatar_painter.dart';

class _BaseOption {
  const _BaseOption(this.id, this.name, this.color);
  final String id;
  final String name;
  final Color color;
}

class _StyleOption {
  const _StyleOption(this.id, this.name);
  final String id;
  final String name;
}

const _bases = [
  _BaseOption('human', '사람', Color(0xFFF2C9A0)),
  _BaseOption('cat', '고양이', Color(0xFFB9B4C9)),
  _BaseOption('rabbit', '토끼', Color(0xFFF0DDE3)),
  _BaseOption('bear', '곰', Color(0xFFA9764C)),
];

const _hairStyles = [
  _StyleOption('none', '기본'),
  _StyleOption('short', '짧은 머리'),
  _StyleOption('long', '긴 머리'),
  _StyleOption('bun', '묶음머리'),
  _StyleOption('ponytail', '포니테일'),
  _StyleOption('curly', '곱슬머리'),
];

const _eyeShapes = [
  _StyleOption('round', '동그란 눈'),
  _StyleOption('almond', '아몬드 눈'),
  _StyleOption('sparkle', '반짝이는 눈'),
  _StyleOption('sleepy', '나른한 눈'),
  _StyleOption('doe', '큰 눈'),
];

const _faceShapes = [
  _StyleOption('round', '둥근형'),
  _StyleOption('oval', '계란형'),
];

const _skinTones = [
  Color(0xFFFFE0BD), Color(0xFFFFD5A6), Color(0xFFF2C9A0), Color(0xFFE8B589),
  Color(0xFFD9A272), Color(0xFFC68642), Color(0xFFA9714A), Color(0xFF8D5524),
  Color(0xFF6B4226), Color(0xFF4A2C17),
];

const _furPalette = [
  Color(0xFFF2C9A0), Color(0xFFE8935B), Color(0xFFD9A24B), Color(0xFF9BC49A),
  Color(0xFF4F6F5C), Color(0xFF8FAAD1), Color(0xFF8B85B8), Color(0xFFE39BC0),
  Color(0xFFB9B4C9), Color(0xFFF0DDE3),
];

const _blushPalette = [
  Color(0xFFFF9B9B), Color(0xFFFFB4A8), Color(0xFFFFC9B8),
  Color(0xFFF6A6C1), Color(0xFFE8829C), Color(0xFFD98A8A),
];

const _bg = Color(0xFFF3F6F1);
const _card = Colors.white;
const _ink = Color(0xFF26302A);
const _inkSoft = Color(0xFF5B6960);
const _sage = Color(0xFF4F6F5C);
const _sageLight = Color(0xFFDCE7DF);
const _lavender = Color(0xFF8B85B8);
const _lavenderLight = Color(0xFFEDEAF6);
const _line = Color(0xFFE1E6DF);

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  final _tracking = FaceTrackingController();

  String _baseId = _bases.first.id;
  String _hairId = 'none';
  String _eyeShapeId = 'round';
  String _noseShapeId = 'none';
  String _faceShapeId = 'round';
  bool _hasGlasses = false;
  bool _hasLashes = false;
  Color _baseColor = _bases.first.color;
  Color _blushColor = _blushPalette.first;

  @override
  void initState() {
    super.initState();
    _tracking.addListener(_onTrackingUpdate);
    _tracking.start();
  }

  void _onTrackingUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tracking.removeListener(_onTrackingUpdate);
    _tracking.dispose();
    super.dispose();
  }

  void _selectBase(_BaseOption b) {
    setState(() {
      _baseId = b.id;
      _baseColor = b.id == 'human' ? _skinTones.first : b.color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _ink),
        title: const Text(
          '나만의 아바타 만들기',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CustomizationPanel(
              baseId: _baseId,
              hairId: _hairId,
              eyeShapeId: _eyeShapeId,
              noseShapeId: _noseShapeId,
              faceShapeId: _faceShapeId,
              hasGlasses: _hasGlasses,
              hasLashes: _hasLashes,
              baseColor: _baseColor,
              blushColor: _blushColor,
              onSelectBase: _selectBase,
              onSelectHair: (id) => setState(() => _hairId = id),
              onSelectEyeShape: (id) => setState(() => _eyeShapeId = id),
              onSelectNoseShape: (id) => setState(() => _noseShapeId = id),
              onSelectFaceShape: (id) => setState(() => _faceShapeId = id),
              onToggleGlasses: () => setState(() => _hasGlasses = !_hasGlasses),
              onToggleLashes: () => setState(() => _hasLashes = !_hasLashes),
              onBaseColor: (c) => setState(() => _baseColor = c),
              onBlushColor: (c) => setState(() => _blushColor = c),
            ),
            Expanded(
              child: _MirrorPanel(
                tracking: _tracking,
                baseId: _baseId,
                hairId: _hairId,
                eyeShapeId: _eyeShapeId,
                noseShapeId: _noseShapeId,
                faceShapeId: _faceShapeId,
                hasGlasses: _hasGlasses,
                hasLashes: _hasLashes,
                baseColor: _baseColor,
                blushColor: _blushColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _CustomizationPanel extends StatelessWidget {
  const _CustomizationPanel({
    required this.baseId,
    required this.hairId,
    required this.eyeShapeId,
    required this.noseShapeId,
    required this.faceShapeId,
    required this.hasGlasses,
    required this.hasLashes,
    required this.baseColor,
    required this.blushColor,
    required this.onSelectBase,
    required this.onSelectHair,
    required this.onSelectEyeShape,
    required this.onSelectNoseShape,
    required this.onSelectFaceShape,
    required this.onToggleGlasses,
    required this.onToggleLashes,
    required this.onBaseColor,
    required this.onBlushColor,
  });

  final String baseId;
  final String hairId;
  final String eyeShapeId;
  final String noseShapeId;
  final String faceShapeId;
  final bool hasGlasses;
  final bool hasLashes;
  final Color baseColor;
  final Color blushColor;
  final ValueChanged<_BaseOption> onSelectBase;
  final ValueChanged<String> onSelectHair;
  final ValueChanged<String> onSelectEyeShape;
  final ValueChanged<String> onSelectNoseShape;
  final ValueChanged<String> onSelectFaceShape;
  final VoidCallback onToggleGlasses;
  final VoidCallback onToggleLashes;
  final ValueChanged<Color> onBaseColor;
  final ValueChanged<Color> onBlushColor;

  bool get _isHuman => baseId == 'human';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: _card,
        border: Border(right: BorderSide(color: _line)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelLabel('베이스'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _bases.map((b) {
                final active = baseId == b.id;
                return GestureDetector(
                  onTap: () => onSelectBase(b),
                  child: Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? _sageLight : _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: active ? _sage : _line, width: active ? 1.6 : 1),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(radius: 12, backgroundColor: b.color),
                        const SizedBox(height: 4),
                        Text(b.name, style: const TextStyle(fontSize: 10, color: _ink), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const _PanelLabel('머리'),
            const SizedBox(height: 8),
            _ChipGroup(options: _hairStyles, value: hairId, onChanged: onSelectHair),
            const SizedBox(height: 20),
            const _PanelLabel('눈 모양'),
            const SizedBox(height: 8),
            _ChipGroup(options: _eyeShapes, value: eyeShapeId, onChanged: onSelectEyeShape),
            const SizedBox(height: 20),
            const _PanelLabel('추가 요소'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _ToggleChip(label: '안경', active: hasGlasses, onTap: onToggleGlasses),
                _ToggleChip(label: '속눈썹', active: hasLashes, onTap: onToggleLashes),
              ],
            ),
            const SizedBox(height: 20),
            const _PanelLabel('코 모양'),
            const SizedBox(height: 8),
            _NosePicker(value: noseShapeId, onChanged: onSelectNoseShape),
            if (_isHuman) ...[
              const SizedBox(height: 20),
              const _PanelLabel('얼굴형'),
              const SizedBox(height: 8),
              _ChipGroup(options: _faceShapes, value: faceShapeId, onChanged: onSelectFaceShape),
            ],
            const SizedBox(height: 20),
            _PanelLabel(_isHuman ? '피부 톤' : '털 색'),
            const SizedBox(height: 8),
            _ColorGrid(colors: _isHuman ? _skinTones : _furPalette, value: baseColor, onChanged: onBaseColor),
            const SizedBox(height: 20),
            const _PanelLabel('블러셔 색'),
            const SizedBox(height: 8),
            _ColorGrid(colors: _blushPalette, value: blushColor, onChanged: onBlushColor),
          ],
        ),
      ),
    );
  }
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _ink, letterSpacing: 0.3),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.options, required this.value, required this.onChanged});

  final List<_StyleOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((o) {
        final active = value == o.id;
        return GestureDetector(
          onTap: () => onChanged(o.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: active ? _sageLight : _bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? _sage : _line),
            ),
            child: Text(o.name, style: TextStyle(fontSize: 11, color: active ? _sage : _inkSoft)),
          ),
        );
      }).toList(),
    );
  }
}

class _NosePicker extends StatelessWidget {
  const _NosePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _options = ['none', 'dot', 'button', 'curve'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((id) {
        final active = value == id;
        return GestureDetector(
          onTap: () => onChanged(id),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: active ? _sageLight : _bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? _sage : _line, width: active ? 1.6 : 1),
            ),
            child: CustomPaint(painter: _NosePreviewPainter(noseShapeId: id)),
          ),
        );
      }).toList(),
    );
  }
}

class _NosePreviewPainter extends CustomPainter {
  _NosePreviewPainter({required this.noseShapeId});
  final String noseShapeId;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // 작은 얼굴 힌트 배경
    canvas.drawCircle(center, size.width * 0.42, Paint()..color = const Color(0xFFF2C9A0));

    final s = size.width / 44;
    final noseColor = _ink.withOpacity(0.55);
    switch (noseShapeId) {
      case 'dot':
        canvas.drawCircle(center, 1.8 * s, Paint()..color = noseColor);
        break;
      case 'button':
        final path = Path()
          ..moveTo(center.dx - 3.6 * s, center.dy - 3 * s)
          ..quadraticBezierTo(center.dx, center.dy + 4.2 * s, center.dx + 3.6 * s, center.dy - 3 * s);
        canvas.drawPath(
          path,
          Paint()
            ..color = noseColor
            ..strokeWidth = 1.7 * s
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
        break;
      case 'curve':
        canvas.drawLine(
          Offset(center.dx - 0.5 * s, center.dy - 4.2 * s),
          Offset(center.dx + 1.2 * s, center.dy + 3.4 * s),
          Paint()
            ..color = noseColor
            ..strokeWidth = 1.6 * s
            ..strokeCap = StrokeCap.round,
        );
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _NosePreviewPainter oldDelegate) => oldDelegate.noseShapeId != noseShapeId;
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _lavenderLight : _bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? _lavender : _line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.check_circle : Icons.circle_outlined,
              size: 13,
              color: active ? _lavender : _inkSoft,
            ),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? _lavender : _inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.colors, required this.value, required this.onChanged});
  final List<Color> colors;
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: colors.map((c) {
        final active = c == value;
        return GestureDetector(
          onTap: () => onChanged(c),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: active ? _ink : Colors.transparent, width: 2),
            ),
          ),
        );
      }).toList(),
    );
  }
}


class _MirrorPanel extends StatelessWidget {
  const _MirrorPanel({
    required this.tracking,
    required this.baseId,
    required this.hairId,
    required this.eyeShapeId,
    required this.noseShapeId,
    required this.faceShapeId,
    required this.hasGlasses,
    required this.hasLashes,
    required this.baseColor,
    required this.blushColor,
  });

  final FaceTrackingController tracking;
  final String baseId;
  final String hairId;
  final String eyeShapeId;
  final String noseShapeId;
  final String faceShapeId;
  final bool hasGlasses;
  final bool hasLashes;
  final Color baseColor;
  final Color blushColor;

  @override
  Widget build(BuildContext context) {
    if (tracking.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tracking.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _inkSoft, height: 1.5),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mirrorWidth = (constraints.maxWidth * 0.72).clamp(220.0, 340.0);
        final mirrorHeight = (mirrorWidth * 1.3).clamp(280.0, constraints.maxHeight * 0.8);
        final camera = tracking.cameraController;
        final cameraReady = tracking.isReady && camera != null && camera.value.isInitialized;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _lavenderLight, borderRadius: BorderRadius.circular(999)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: _lavender),
                    SizedBox(width: 4),
                    Text('실시간 거울', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _lavender)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Container(
                width: mirrorWidth,
                height: mirrorHeight,
                decoration: BoxDecoration(
                  color: _sageLight,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _line, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: _ink.withOpacity(0.08), blurRadius: 28, offset: const Offset(0, 12)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: cameraReady
                    ? _FaceMirror(
                        camera: camera,
                        expression: tracking.expression,
                        baseId: baseId,
                        hairId: hairId,
                        eyeShapeId: eyeShapeId,
                        noseShapeId: noseShapeId,
                        faceShapeId: faceShapeId,
                        hasGlasses: hasGlasses,
                        hasLashes: hasLashes,
                        baseColor: baseColor,
                        blushColor: blushColor,
                      )
                    : const Center(child: CircularProgressIndicator(color: _sage)),
              ),

              const SizedBox(height: 14),
              Text(
                tracking.expression.faceFound ? '표정을 잘 따라가고 있어요' : '카메라에 얼굴을 비춰주세요',
                style: TextStyle(
                  color: tracking.expression.faceFound ? _sage : _inkSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FaceMirror extends StatelessWidget {
  const _FaceMirror({
    required this.camera,
    required this.expression,
    required this.baseId,
    required this.hairId,
    required this.eyeShapeId,
    required this.noseShapeId,
    required this.faceShapeId,
    required this.hasGlasses,
    required this.hasLashes,
    required this.baseColor,
    required this.blushColor,
  });

  final CameraController camera;
  final FaceExpression expression;
  final String baseId;
  final String hairId;
  final String eyeShapeId;
  final String noseShapeId;
  final String faceShapeId;
  final bool hasGlasses;
  final bool hasLashes;
  final Color baseColor;
  final Color blushColor;

  static const double _coverageScale = 1.6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerW = constraints.maxWidth;
        final containerH = constraints.maxHeight;
        final previewSize = camera.value.previewSize;
        final rect = expression.faceRect;

        Widget? avatarOverlay;

        if (previewSize != null && rect != null && expression.faceFound) {
          final scaleX = containerW / previewSize.width;
          final scaleY = containerH / previewSize.height;
          final scale = scaleX > scaleY ? scaleX : scaleY;
          final scaledW = previewSize.width * scale;
          final scaledH = previewSize.height * scale;
          final offsetX = (containerW - scaledW) / 2;
          final offsetY = (containerH - scaledH) / 2;

          final cx = rect.left + rect.width / 2;
          final cy = rect.top + rect.height / 2;
          final side = (rect.width > rect.height ? rect.width : rect.height) * _coverageScale;
          var avatarSize = side * scaledW;
          avatarSize = avatarSize.clamp(40.0, containerW * 2.0);

          final avatarLeft = offsetX + cx * scaledW - avatarSize / 2;
          final avatarTop = offsetY + cy * scaledH - avatarSize / 2;

          avatarOverlay = Positioned(
            left: avatarLeft,
            top: avatarTop,
            width: avatarSize,
            height: avatarSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _sage.withOpacity(0.32),
                        _sage.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size(avatarSize, avatarSize),
                  painter: AvatarPainter(
                    baseId: baseId,
                    hairId: hairId,
                    baseColor: baseColor,
                    eyeShapeId: eyeShapeId,
                    noseShapeId: noseShapeId,
                    faceShapeId: faceShapeId,
                    hasGlasses: hasGlasses,
                    hasLashes: hasLashes,
                    blushColor: blushColor,
                    eyeOpenLeft: expression.eyeOpenLeft,
                    eyeOpenRight: expression.eyeOpenRight,
                    mouthOpen: expression.mouthOpen,
                    smile: expression.smile,
                    browRaiseLeft: expression.browRaiseLeft,
                    browRaiseRight: expression.browRaiseRight,
                  ),
                ),
              ],
            ),
          );
        }

        return Transform.scale(
          scaleX: -1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (previewSize != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewSize.width,
                    height: previewSize.height,
                    child: CameraPreview(camera),
                  ),
                )
              else
                CameraPreview(camera),
              if (avatarOverlay != null) avatarOverlay,
            ],
          ),
        );
      },
    );
  }
}