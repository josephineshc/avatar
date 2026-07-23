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
  Timer? _webTimer;

  double? _neutralMouthRatio;
  double? _neutralBrowGapLeft;
  double? _neutralBrowGapRight;
  int _calibrationFrames = 0;
  static const int _calibrationTarget = 20;

  FaceExpression expression = const FaceExpression();
  String? error;

  CameraController? get cameraController => _camera;
  bool get isReady => _camera != null && _camera!.value.isInitialized;

  static const double _mouthOpenMax = 0.55;
  static const double _eyeCloseThreshold = 0.18;
  static const double _eyeOpenThreshold = 0.34;
  static const double _smileSensitivity = 0.15;
  static const double _browSensitivity = 0.12;
  static const double _rectSmoothing = 0.35;

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
        imageFormatGroup: kIsWeb ? ImageFormatGroup.jpeg : ImageFormatGroup.yuv420,
      );
      await _camera!.initialize();

      _detector = await FaceDetector.create(model: FaceDetectionModel.frontCamera);

      if (kIsWeb) {
        // On Web, startImageStream is not supported.
        // For actual detection on Web, you would typically use a timer and 
        // a detector that supports HTML elements, but here we focus on keeping 
        // the code valid for compilation and macOS performance.
        Timer.periodic(const Duration(milliseconds: 100), (t) {
          if (_disposed) t.cancel();
          notifyListeners(); // Keep the mirror alive
        });
      } else {
        await _camera!.startImageStream(_onFrame);
      }
      
      notifyListeners();
    } catch (e) {
      error = '카메라 또는 감지기를 시작할 수 없습니다.';
      notifyListeners();
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_isBusy || _disposed || _detector == null) return;
    _isBusy = true;
    try {
      // Corrected method name: detectFacesFromCameraImage
      final faces = await _detector!.detectFacesFromCameraImage(
        image,
        mode: FaceDetectionMode.full,
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
      notifyListeners();
    } catch (_) {
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

    final mouthGap = dist(pts[13].x, pts[13].y, pts[14].x, pts[14].y);
    final mouthWidthRatio = dist(pts[61].x, pts[61].y, pts[291].x, pts[291].y) / interOcular;
    final browGapLeft = eyeTopY(eyes.leftEye) - pts[105].y;
    final browGapRight = eyeTopY(eyes.rightEye) - pts[334].y;

    if (_calibrationFrames < _calibrationTarget) {
      _neutralMouthRatio = ((_neutralMouthRatio ?? mouthWidthRatio) * _calibrationFrames + mouthWidthRatio) / (_calibrationFrames + 1);
      _neutralBrowGapLeft = ((_neutralBrowGapLeft ?? browGapLeft) * _calibrationFrames + browGapLeft) / (_calibrationFrames + 1);
      _neutralBrowGapRight = ((_neutralBrowGapRight ?? browGapRight) * _calibrationFrames + browGapRight) / (_calibrationFrames + 1);
      _calibrationFrames++;
    }

    final mouthBaseline = _neutralMouthRatio ?? mouthWidthRatio;
    final mouthOpen = (mouthGap / interOcular / _mouthOpenMax).clamp(0.0, 1.0);
    final smile = (((mouthWidthRatio - mouthBaseline) / mouthBaseline) / _smileSensitivity).clamp(0.0, 1.0);
    final browRaiseLeft = (((browGapLeft - (_neutralBrowGapLeft ?? browGapLeft)) / interOcular) / _browSensitivity).clamp(0.0, 1.0);
    final browRaiseRight = (((browGapRight - (_neutralBrowGapRight ?? browGapRight)) / interOcular) / _browSensitivity).clamp(0.0, 1.0);

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

  @override
  void dispose() {
    _disposed = true;
    _webTimer?.cancel();
    _camera?.dispose();
    _detector?.dispose();
    super.dispose();
  }
}