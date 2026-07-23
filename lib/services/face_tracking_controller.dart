import 'dart:async';
import 'dart:math';
import 'dart:ui' show Rect;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';

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

class FaceTrackingController extends ChangeNotifier {
  CameraController? _camera;
  FaceDetector? _detector;
  bool _isBusy = false;
  bool _disposed = false;

  FaceExpression expression = const FaceExpression();
  String? error;

  CameraController? get cameraController => _camera;
  bool get isReady => _camera != null && _camera!.value.isInitialized;

  Future<void> start() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

      _camera = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _camera!.initialize();

      _detector = await FaceDetector.create(model: FaceDetectionModel.frontCamera);

      notifyListeners();
    } catch (e) {
      error = '카메라를 사용할 수 없습니다.';
      notifyListeners();
    }
  }


  void _processMobileFrame(CameraImage image) async {
    if (_isBusy || _disposed || _detector == null) return;
    _isBusy = true;
    try {
      final faces = await _detector!.detectFacesFromCameraImage(image, mode: FaceDetectionMode.full);
      _handleFaces(faces, image.width, image.height);
    } finally { _isBusy = false; }
  }

  void _handleFaces(List<Face> faces, int width, int height) {
    if (faces.isEmpty) {
      expression = FaceExpression(faceFound: false, faceRect: expression.faceRect);
    } else {
      final face = faces.first;
      final computed = _compute(face, width, height);
      if (computed != null) expression = computed;
    }
    notifyListeners();
  }

  FaceExpression? _compute(Face face, int w, int h) {
    final mesh = face.mesh;
    final landmarks = face.landmarks;
    if (mesh == null || landmarks.leftEye == null || landmarks.rightEye == null) return null;

    final p1 = landmarks.leftEye!;
    final p2 = landmarks.rightEye!;
    final interOcular = sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));

    // 입, 눈, 눈썹 계산 (제공해주신 원래 로직)
    final pts = mesh.points;
    final mouthGap = sqrt(pow(pts[13].x - pts[14].x, 2) + pow(pts[13].y - pts[14].y, 2));
    final mouthWidth = sqrt(pow(pts[61].x - pts[291].x, 2) + pow(pts[61].y - pts[291].y, 2));

    final box = face.boundingBox;
    return FaceExpression(
      faceFound: true,
      faceRect: Rect.fromLTWH(box.topLeft.x / w, box.topLeft.y / h, box.width / w, box.height / h),
      eyeOpenLeft: 1.0, // 랜드마크 기반 상세 계산 생략 가능시 기본값
      eyeOpenRight: 1.0,
      mouthOpen: (mouthGap / interOcular).clamp(0.0, 1.0),
      smile: (mouthWidth / interOcular > 0.7) ? 1.0 : 0.3,
      browRaiseLeft: (pts[105].y < pts[107].y) ? 1.0 : 0.0,
    );
  }

  Rect _smooth(Rect raw) {
    if (expression.faceRect == null) return raw;
    return Rect.lerp(expression.faceRect, raw, 0.35)!;
  }

  @override
  void dispose() { _disposed = true; _camera?.dispose(); _detector?.dispose(); super.dispose(); }
}