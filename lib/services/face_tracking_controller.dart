import 'dart:async';
import 'dart:math';
import 'dart:ui' show Rect;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';

/// 카메라 프레임에서 계산한 표정 값과 얼굴 위치입니다.
/// eyeOpenLeft/Right, mouthOpen, smile, browRaiseLeft/Right 는 0.0 ~ 1.0.
/// faceRect 는 카메라 원본 이미지 기준 0.0 ~ 1.0 정규화 좌표입니다.
class FaceExpression {
  const FaceExpression({
    this.eyeOpenLeft = 1.0,
    this.eyeOpenRight = 1.0,
    this.mouthOpen = 0.0,
    this.smile = 0.3,
    this.browRaiseLeft = 0.0,
    this.browRaiseRight = 0.0,
    this.faceRect,
    this.faceFound = false,
  });

  final double eyeOpenLeft;
  final double eyeOpenRight;
  final double mouthOpen;
  final double smile;
  final double browRaiseLeft;
  final double browRaiseRight;
  final Rect? faceRect;
  final bool faceFound;
}

/// 카메라 + face_detection_tflite 를 연결해 실시간 표정 값을 계산합니다.
///
/// 참고사항
/// - 눈 뜬 정도는 face_detection_tflite가 제공하는 15포인트 눈꺼풀 윤곽(eye
///   contour)의 세로/가로 비율로 계산합니다. FaceDetectionMode.full에서만
///   제공되는 데이터라 mode를 full로 고정했습니다.
/// - 입 모양과 눈썹은 MediaPipe 표준 468포인트 얼굴 메시의 인덱스를 사용합니다.
///   (13: 윗입술 안쪽, 14: 아랫입술 안쪽, 61/291: 입꼬리, 105/334: 눈썹)
///   눈썹 좌우가 반대로 느껴지면 105와 334를 서로 바꿔보세요.
/// - faceRect는 face.boundingBox를 카메라 원본 프레임 크기로 나눠 정규화한
///   값입니다. 프레임 간 흔들림을 줄이기 위해 지수이동평균으로 부드럽게
///   보정합니다.
/// - 아래 임계값/보정 상수들은 시작점일 뿐이라, 실제 기기·조명에서 테스트하며
///   조정이 필요할 수 있어요.
class FaceTrackingController extends ChangeNotifier {
  CameraController? _camera;
  FaceDetector? _detector;
  bool _isBusy = false;
  bool _disposed = false;

  double? _neutralMouthRatio;
  double? _neutralBrowGapLeft;
  double? _neutralBrowGapRight;
  int _calibrationFrames = 0;
  static const int _calibrationTarget = 20; // 시작 후 약 20프레임을 '중립 표정'으로 간주해 자동 보정

  FaceExpression expression = const FaceExpression();
  String? error;

  CameraController? get cameraController => _camera;
  bool get isReady => _camera != null && _camera!.value.isInitialized;

  // ---- 튜닝 가능한 상수 (실제 기기에서 테스트하며 조정하세요) ----
  static const double _mouthOpenMax = 0.55; // 이 이상 벌어지면 '완전히 벌림'(1.0)으로 간주
  static const double _eyeCloseThreshold = 0.18; // 이 비율 이하는 '감음'(0.0)
  static const double _eyeOpenThreshold = 0.34; // 이 비율 이상은 '완전히 뜸'(1.0)
  static const double _smileSensitivity = 0.15; // 중립 대비 입 너비가 몇 % 늘어나야 최대 미소인지
  static const double _browSensitivity = 0.12; // 중립 대비 눈썹이 얼마나 올라가야 최대치인지
  static const double _rectSmoothing = 0.35; // 얼굴 박스 추적 반응 속도(클수록 빠르고 덜 부드러움)

  Future<void> start() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _camera!.initialize();

      _detector = await FaceDetector.create(model: FaceDetectionModel.frontCamera);

      await _camera!.startImageStream(_onFrame);
      notifyListeners();
    } catch (e) {
      error = '카메라를 사용할 수 없어요. 설정에서 카메라 권한을 확인해주세요.';
      notifyListeners();
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_isBusy || _disposed || _detector == null) return;
    _isBusy = true;
    try {
      final faces = await _detector!.detectFacesFromCameraImage(
        image,
        // rotation: rotationForFrame(...), // 화면이 회전돼 보이면 패키지 문서를 참고해 추가하세요.
        mode: FaceDetectionMode.full, // eyes(눈꺼풀 윤곽) 데이터를 얻으려면 full 모드가 필요합니다.
        maxDim: 480,
      );

      if (faces.isEmpty) {
        expression = FaceExpression(
          eyeOpenLeft: expression.eyeOpenLeft,
          eyeOpenRight: expression.eyeOpenRight,
          mouthOpen: expression.mouthOpen,
          smile: expression.smile,
          browRaiseLeft: expression.browRaiseLeft,
          browRaiseRight: expression.browRaiseRight,
          faceRect: expression.faceRect,
          faceFound: false,
        );
      } else {
        final computed = _computeExpression(faces.first, image.width, image.height);
        if (computed != null) expression = computed;
      }

      if (!_disposed) notifyListeners();
    } catch (_) {
      // 프레임 하나가 실패해도 무시하고 다음 프레임을 계속 처리합니다.
    } finally {
      _isBusy = false;
    }
  }

  FaceExpression? _computeExpression(Face face, int imageWidth, int imageHeight) {
    final mesh = face.mesh;
    final eyes = face.eyes;
    final landmarks = face.landmarks;
    if (mesh == null || eyes == null) return null;

    final leftEyePt = landmarks.leftEye;
    final rightEyePt = landmarks.rightEye;
    if (leftEyePt == null || rightEyePt == null) return null;

    double dist(num x1, num y1, num x2, num y2) {
      final dx = x1 - x2, dy = y1 - y2;
      return sqrt(dx * dx + dy * dy);
    }

    // 두 눈 사이 거리를 기준 척도로 사용 (카메라와의 거리에 영향을 받지 않도록 정규화)
    final interOcular = dist(leftEyePt.x, leftEyePt.y, rightEyePt.x, rightEyePt.y);
    if (interOcular <= 0) return null;

    double eyeOpenRatio(Eye? eye) {
      if (eye == null || eye.contour.isEmpty) return 1.0;
      double minX = double.infinity, maxX = -double.infinity;
      double minY = double.infinity, maxY = -double.infinity;
      for (final p in eye.contour) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
      final width = maxX - minX;
      final height = maxY - minY;
      if (width <= 0) return 1.0;
      final ratio = height / width;
      final t = (ratio - _eyeCloseThreshold) / (_eyeOpenThreshold - _eyeCloseThreshold);
      return t.clamp(0.0, 1.0);
    }

    double eyeTopY(Eye? eye) {
      if (eye == null || eye.contour.isEmpty) return 0;
      double minY = double.infinity;
      for (final p in eye.contour) {
        if (p.y < minY) minY = p.y;
      }
      return minY;
    }

    final pts = mesh.points;
    if (pts.length < 335) return null;

    final upperLip = pts[13];
    final lowerLip = pts[14];
    final mouthLeft = pts[61];
    final mouthRight = pts[291];
    final browLeftPt = pts[105];
    final browRightPt = pts[334];

    final mouthGap = dist(upperLip.x, upperLip.y, lowerLip.x, lowerLip.y);
    final mouthWidthRatio = dist(mouthLeft.x, mouthLeft.y, mouthRight.x, mouthRight.y) / interOcular;

    final browGapLeft = eyeTopY(eyes.leftEye) - browLeftPt.y;
    final browGapRight = eyeTopY(eyes.rightEye) - browRightPt.y;

    // 시작 후 얼마간의 입 너비/눈썹 위치를 '중립 표정' 기준으로 자동 보정합니다.
    // 사람마다 생김새가 달라 고정값보다 이 방식이 더 안정적이에요.
    if (_calibrationFrames < _calibrationTarget) {
      _neutralMouthRatio = ((_neutralMouthRatio ?? mouthWidthRatio) * _calibrationFrames + mouthWidthRatio) /
          (_calibrationFrames + 1);
      _neutralBrowGapLeft = ((_neutralBrowGapLeft ?? browGapLeft) * _calibrationFrames + browGapLeft) /
          (_calibrationFrames + 1);
      _neutralBrowGapRight = ((_neutralBrowGapRight ?? browGapRight) * _calibrationFrames + browGapRight) /
          (_calibrationFrames + 1);
      _calibrationFrames++;
    }
    final mouthBaseline = _neutralMouthRatio ?? mouthWidthRatio;
    final browBaselineLeft = _neutralBrowGapLeft ?? browGapLeft;
    final browBaselineRight = _neutralBrowGapRight ?? browGapRight;

    final mouthOpen = (mouthGap / interOcular / _mouthOpenMax).clamp(0.0, 1.0);
    final smile = (((mouthWidthRatio - mouthBaseline) / mouthBaseline) / _smileSensitivity).clamp(0.0, 1.0);
    final browRaiseLeft = (((browGapLeft - browBaselineLeft) / interOcular) / _browSensitivity).clamp(0.0, 1.0);
    final browRaiseRight = (((browGapRight - browBaselineRight) / interOcular) / _browSensitivity).clamp(0.0, 1.0);

    // 얼굴 위치·크기 (0~1 정규화) — 아바타를 얼굴에 맞춰 표시하는 데 사용
    final box = face.boundingBox;
    final rawRect = Rect.fromLTWH(
      box.topLeft.x / imageWidth,
      box.topLeft.y / imageHeight,
      box.width / imageWidth,
      box.height / imageHeight,
    );

    return FaceExpression(
      eyeOpenLeft: eyeOpenRatio(eyes.leftEye),
      eyeOpenRight: eyeOpenRatio(eyes.rightEye),
      mouthOpen: mouthOpen,
      smile: smile,
      browRaiseLeft: browRaiseLeft,
      browRaiseRight: browRaiseRight,
      faceRect: _smoothRect(rawRect),
      faceFound: true,
    );
  }

  Rect _smoothRect(Rect raw) {
    final prev = expression.faceRect;
    if (prev == null) return raw;
    return Rect.fromLTWH(
      prev.left + (raw.left - prev.left) * _rectSmoothing,
      prev.top + (raw.top - prev.top) * _rectSmoothing,
      prev.width + (raw.width - prev.width) * _rectSmoothing,
      prev.height + (raw.height - prev.height) * _rectSmoothing,
    );
  }

  Future<void> stop() async {
    try {
      await _camera?.stopImageStream();
    } catch (_) {}
    await _camera?.dispose();
    await _detector?.dispose();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
