import 'dart:async';
import 'dart:js' as js;
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

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
  Timer? _processingTimer;
  bool _disposed = false;
  String? error;
  FaceExpression expression = const FaceExpression();

  CameraController? get cameraController => _camera;
  bool get isReady => _camera != null && _camera!.value.isInitialized;

  Future<void> start() async {
    try {
      final cameras = await availableCameras();
      _camera = CameraController(
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front),
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _camera!.initialize();
      
      // Initialize MediaPipe JS
      await js.context.callMethod('initTracking');
      
      // Start polling JS for data
      _processingTimer = Timer.periodic(const Duration(milliseconds: 30), (_) => _updateTracking());
      
      notifyListeners();
    } catch (e) {
      error = '카메라를 시작할 수 없습니다. HTTPS 환경인지 확인해주세요.';
      notifyListeners();
    }
  }

  void _updateTracking() {
    if (_disposed || !isReady) return;

    final data = js.context.callMethod('getFaceData');
    
    if (data == null) {
      if (expression.faceFound) {
        expression = FaceExpression(faceFound: false, faceRect: expression.faceRect);
        notifyListeners();
      }
      return;
    }

    final landmarks = data['landmarks'] as List;
    final blendshapes = data['blendshapes'] as List;

    // 1. Calculate Bounding Box from landmarks
    double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    for (var pt in landmarks) {
      double x = pt['x']; double y = pt['y'];
      if (x < minX) minX = x; if (x > maxX) maxX = x;
      if (y < minY) minY = y; if (y > maxY) maxY = y;
    }

    // 2. Map AI Blendshapes to Expression
    // MediaPipe scores are 0.0 - 1.0
    Map<String, double> scores = {};
    for (var b in blendshapes) {
      scores[b['categoryName']] = b['score'];
    }

    expression = FaceExpression(
      faceFound: true,
      faceRect: Rect.fromLTRB(minX, minY, maxX, maxY),
      eyeOpenLeft: 1.0 - (scores['eyeBlinkLeft'] ?? 0),
      eyeOpenRight: 1.0 - (scores['eyeBlinkRight'] ?? 0),
      mouthOpen: (scores['jawOpen'] ?? 0) * 1.8,
      smile: ((scores['mouthSmileLeft'] ?? 0) + (scores['mouthSmileRight'] ?? 0)) / 2,
      browRaiseLeft: scores['browInnerUp'] ?? 0,
      browRaiseRight: scores['browInnerUp'] ?? 0,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _processingTimer?.cancel();
    _camera?.dispose();
    super.dispose();
  }
}