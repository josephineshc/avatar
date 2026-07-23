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

class _HairOption {
  const _HairOption(this.id, this.name);
  final String id;
  final String name;
}

class _MoodOption {
  const _MoodOption(this.id, this.label, this.color, this.icon);
  final String id;
  final String label;
  final Color color;
  final IconData icon;
}

const _bases = [
  _BaseOption('fox', '여우', Color(0xFFE8935B)),
  _BaseOption('bear', '곰', Color(0xFFA9764C)),
  _BaseOption('rabbit', '토끼', Color(0xFFF0DDE3)),
  _BaseOption('cat', '고양이', Color(0xFFB9B4C9)),
  _BaseOption('owl', '부엉이', Color(0xFF9C8265)),
  _BaseOption('human-a', '사람형 A', Color(0xFFF2C9A0)),
  _BaseOption('human-b', '사람형 B', Color(0xFFD9B38C)),
];

const _hairStyles = [
  _HairOption('none', '심플'),
  _HairOption('short', '짧은 머리'),
  _HairOption('long', '긴 머리'),
  _HairOption('bun', '묶음머리'),
];

const _moods = [
  _MoodOption('anxious', '불안해요', Color(0xFF8B85B8), Icons.air_rounded),
  _MoodOption('tired', '지쳤어요', Color(0xFF7E93AE), Icons.cloud_outlined),
  _MoodOption('calm', '잔잔해요', Color(0xFF4F6F5C), Icons.eco_outlined),
  _MoodOption('okay', '괜찮아요', Color(0xFFD9A24B), Icons.wb_sunny_outlined),
];

const _palette = [
  Color(0xFFF2C9A0), Color(0xFFE8935B), Color(0xFFD9A24B), Color(0xFF9BC49A),
  Color(0xFF4F6F5C), Color(0xFF8FAAD1), Color(0xFF8B85B8), Color(0xFFE39BC0),
  Color(0xFFB9B4C9), Color(0xFFF0DDE3),
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

/// STEP 2~4를 한 화면에 합친 커스터마이징 화면.
/// 좌측: 베이스·머리·색상·마음 선택 메뉴
/// 가운데: 카메라로 표정을 실시간 추적해 그대로 반영하는 '거울'
class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  final _tracking = FaceTrackingController();

  String _baseId = _bases.first.id;
  String _hairId = 'none';
  Color _baseColor = _bases.first.color;
  Color _outfitColor = _sageLight;
  String? _moodId;

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
      _baseColor = b.color;
    });
  }

  Color? get _moodColor {
    for (final m in _moods) {
      if (m.id == _moodId) return m.color;
    }
    return null;
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
          '나만의 캐릭터 만들기',
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
              baseColor: _baseColor,
              outfitColor: _outfitColor,
              moodId: _moodId,
              onSelectBase: _selectBase,
              onSelectHair: (id) => setState(() => _hairId = id),
              onBaseColor: (c) => setState(() => _baseColor = c),
              onOutfitColor: (c) => setState(() => _outfitColor = c),
              onSelectMood: (id) => setState(() => _moodId = _moodId == id ? null : id),
            ),
            Expanded(
              child: _MirrorPanel(
                tracking: _tracking,
                baseId: _baseId,
                hairId: _hairId,
                baseColor: _baseColor,
                moodColor: _moodColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------- 좌측 패널 ------------------------------- */

class _CustomizationPanel extends StatelessWidget {
  const _CustomizationPanel({
    required this.baseId,
    required this.hairId,
    required this.baseColor,
    required this.outfitColor,
    required this.moodId,
    required this.onSelectBase,
    required this.onSelectHair,
    required this.onBaseColor,
    required this.onOutfitColor,
    required this.onSelectMood,
  });

  final String baseId;
  final String hairId;
  final Color baseColor;
  final Color outfitColor;
  final String? moodId;
  final ValueChanged<_BaseOption> onSelectBase;
  final ValueChanged<String> onSelectHair;
  final ValueChanged<Color> onBaseColor;
  final ValueChanged<Color> onOutfitColor;
  final ValueChanged<String> onSelectMood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
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
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _hairStyles.map((h) {
                final active = hairId == h.id;
                return GestureDetector(
                  onTap: () => onSelectHair(h.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? _sageLight : _bg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: active ? _sage : _line),
                    ),
                    child: Text(h.name, style: TextStyle(fontSize: 11, color: active ? _sage : _inkSoft)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const _PanelLabel('바탕 색'),
            const SizedBox(height: 8),
            _ColorGrid(value: baseColor, onChanged: onBaseColor),
            const SizedBox(height: 20),
            const _PanelLabel('옷 색'),
            const SizedBox(height: 8),
            _ColorGrid(value: outfitColor, onChanged: onOutfitColor),
            const SizedBox(height: 20),
            const _PanelLabel('마음'),
            const SizedBox(height: 4),
            const Text('선택하지 않아도 괜찮아요', style: TextStyle(fontSize: 10, color: _inkSoft)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _moods.map((m) {
                final active = moodId == m.id;
                return GestureDetector(
                  onTap: () => onSelectMood(m.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? m.color.withOpacity(0.14) : _bg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: active ? m.color : _line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.icon, size: 12, color: active ? m.color : _inkSoft),
                        const SizedBox(width: 4),
                        Text(m.label, style: TextStyle(fontSize: 10, color: active ? m.color : _inkSoft)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
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

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.value, required this.onChanged});
  final Color value;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _palette.map((c) {
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

/* ------------------------------ 가운데 거울 ------------------------------ */

/// 화면 정중앙에 큰 '거울'(카메라 프리뷰)을 놓고, 그 위에 아바타를 겹쳐
/// 그려서 마치 거울에 비친 내 얼굴이 아바타로 바뀐 것처럼 보이게 합니다.
// ... (Keep all your Option classes and constants from your snippet)

class _MirrorPanel extends StatelessWidget {
  const _MirrorPanel({
    required this.tracking,
    required this.baseId,
    required this.hairId,
    required this.baseColor,
    required this.moodColor,
  });

  final FaceTrackingController tracking;
  final String baseId;
  final String hairId;
  final Color baseColor;
  final Color? moodColor;

  @override
  Widget build(BuildContext context) {
    if (tracking.error != null) {
      return Center(child: Text(tracking.error!));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double mirrorWidth = (constraints.maxWidth * 0.72).clamp(220.0, 340.0);
        final double mirrorHeight = (mirrorWidth * 1.3).clamp(280.0, constraints.maxHeight * 0.8);
        final camera = tracking.cameraController;
        final cameraReady = tracking.isReady && camera != null && camera.value.isInitialized;

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Real-time badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _lavenderLight, borderRadius: BorderRadius.circular(999)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: _lavender),
                    SizedBox(width: 4),
                    Text('실시간 거울', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _lavender)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Mirror Frame
              Container(
                width: mirrorWidth,
                height: mirrorHeight,
                decoration: BoxDecoration(
                  color: _sageLight,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _line, width: 1.5),
                  boxShadow: [BoxShadow(color: _ink.withOpacity(0.08), blurRadius: 28, offset: const Offset(0, 12))],
                ),
                clipBehavior: Clip.antiAlias,
                child: cameraReady
                    ? _FaceMirror(
                        camera: camera,
                        expression: tracking.expression,
                        baseId: baseId,
                        hairId: hairId,
                        baseColor: baseColor,
                        moodColor: moodColor,
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 14),
              Text(
                tracking.expression.faceFound ? '표정을 잘 따라가고 있어요' : '카메라에 얼굴을 비춰주세요',
                style: TextStyle(color: tracking.expression.faceFound ? _sage : _inkSoft, fontSize: 13),
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
    required this.baseColor,
    required this.moodColor,
  });

  final CameraController camera;
  final FaceExpression expression;
  final String baseId;
  final String hairId;
  final Color baseColor;
  final Color? moodColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double containerW = constraints.maxWidth;
      final double containerH = constraints.maxHeight;
      
      // Calculate Video Scaling (Cover)
      final previewSize = camera.value.previewSize!;
      final double previewAspect = previewSize.height / previewSize.width;
      
      double drawW, drawH;
      if (containerW / containerH > previewAspect) {
        drawW = containerW;
        drawH = containerW / previewAspect;
      } else {
        drawH = containerH;
        drawW = containerH * previewAspect;
      }

      final double offsetX = (containerW - drawW) / 2;
      final double offsetY = (containerH - drawH) / 2;

      Widget? avatarMask;
      if (expression.faceFound && expression.faceRect != null) {
        final rect = expression.faceRect!;
        final double cx = (rect.left + rect.width / 2) * drawW;
        final double cy = (rect.top + rect.height / 2) * drawH;
        
        // Face Mask scale (1.6 to cover hair/ears)
        final double avatarSize = rect.width * drawW * 1.6;

        avatarMask = Positioned(
          left: offsetX + cx - (avatarSize / 2),
          top: offsetY + cy - (avatarSize / 2),
          width: avatarSize,
          height: avatarSize,
          child: CustomPaint(
            painter: AvatarPainter(
              baseId: baseId,
              hairId: hairId,
              baseColor: baseColor,
              eyeOpenLeft: expression.eyeOpenLeft,
              eyeOpenRight: expression.eyeOpenRight,
              mouthOpen: expression.mouthOpen,
              smile: expression.smile,
              browRaiseLeft: expression.browRaiseLeft,
              browRaiseRight: expression.browRaiseRight,
              moodColor: moodColor,
            ),
          ),
        );
      }

      return Transform.scale(
        scaleX: -1, // Flip the entire mirror
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: drawW,
                height: drawH,
                child: CameraPreview(camera),
              ),
            ),
            if (avatarMask != null) avatarMask,
          ],
        ),
      );
    });
  }
}