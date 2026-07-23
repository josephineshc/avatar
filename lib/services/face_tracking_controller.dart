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
      if (cameras.isEmpty) throw '카메라를 찾을 수 없습니다.';

      _camera = CameraController(
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first),
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      // 1. 카메라 시작
      await _camera!.initialize();
      
      // 2. 중요: 카메라 화면이 브라우저에 렌더링될 때까지 잠깐 대기 (0.5초~1초)
      // 이 과정이 없으면 AI가 빈 화면을 읽으려고 시도하다가 에러가 납니다.
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 3. AI 초기화
      await js.context.callMethod('initTracking');
      
      _processingTimer = Timer.periodic(const Duration(milliseconds: 33), (_) => _updateTracking());
      
      error = null;
      notifyListeners();
    } catch (e) {
      print('Tracking Start Error: $e');
      // 에러 메시지를 더 구체적으로 변경하여 원인 파악을 돕습니다.
      error = '카메라 연결에 실패했습니다.\n잠시 후 다시 시도해주세요.';
      notifyListeners();
    }
  }

  void _updateTracking() {
  if (_disposed || !isReady) return;

  final data = js.context.callMethod('getFaceData');
  
  if (data == null) {
    // If face was lost, only notify if it was previously found
    if (expression.faceFound) {
      expression = FaceExpression(
        faceFound: false, 
        faceRect: expression.faceRect,
        eyeOpenLeft: 1.0, eyeOpenRight: 1.0, mouthOpen: 0.0 // Reset to neutral
      );
      notifyListeners();
    }
    return;
  }

  try {
    final landmarks = data['landmarks'] as List;
    final blendshapes = data['blendshapes'] as List;

    // Calculate Bounding Box with a small buffer
    double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    for (var pt in landmarks) {
      double x = pt['x'].toDouble(); 
      double y = pt['y'].toDouble();
      if (x < minX) minX = x; if (x > maxX) maxX = x;
      if (y < minY) minY = y; if (y > maxY) maxY = y;
    }

    // Convert blendshapes to a usable map
    Map<String, double> scores = {};
    for (var b in blendshapes) {
      scores[b['categoryName']] = b['score'].toDouble();
    }

    // Smooth the values slightly
    expression = FaceExpression(
      faceFound: true,
      faceRect: Rect.fromLTRB(minX, minY, maxX, maxY),
      eyeOpenLeft: 1.0 - (scores['eyeBlinkLeft'] ?? 0),
      eyeOpenRight: 1.0 - (scores['eyeBlinkRight'] ?? 0),
      mouthOpen: (scores['jawOpen'] ?? 0) * 1.5,
      smile: ((scores['mouthSmileLeft'] ?? 0) + (scores['mouthSmileRight'] ?? 0)) / 2,
      browRaiseLeft: scores['browInnerUp'] ?? 0,
      browRaiseRight: scores['browInnerUp'] ?? 0,
    );

    notifyListeners();
  } catch (e) {
    // If parsing fails, just ignore this frame
  }
}

  @override
  void dispose() {
    _disposed = true;
    _processingTimer?.cancel();
    _camera?.dispose();
    super.dispose();
  }
}