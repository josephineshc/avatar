import 'dart:async';
import 'dart:js' as js;
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// 얼굴 표정 및 위치 데이터 모델
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
  
  // 현재 상태 및 표정 데이터
  FaceExpression expression = const FaceExpression();
  String status = "카메라 준비 중...";

  CameraController? get cameraController => _camera;
  bool get isReady => _camera != null && _camera!.value.isInitialized;

  /// 카메라 및 AI 추적 시작
  Future<void> start() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw '카메라를 찾을 수 없습니다.';

      _camera = CameraController(
        cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front, 
          orElse: () => cameras.first
        ),
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      // 1. 카메라 초기화
      await _camera!.initialize();
      status = "AI 로딩 중...";
      notifyListeners();
      
      // 2. 카메라 스트림이 안정될 때까지 대기
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 3. 브라우저의 MediaPipe JS 초기화 호출
      await js.context.callMethod('initTracking');
      
      // 4. 주기적으로 JavaScript로부터 데이터를 가져오는 타이머 (약 30fps)
      _processingTimer = Timer.periodic(const Duration(milliseconds: 33), (_) => _updateTracking());
      
      error = null;
      notifyListeners();
    } catch (e) {
      print('Tracking Start Error: $e');
      error = '카메라 또는 AI 초기화에 실패했습니다.';
      status = "오류 발생";
      notifyListeners();
    }
  }

  /// 매 프레임마다 호출되어 얼굴 데이터를 업데이트함
  void _updateTracking() {
    if (_disposed || !isReady) return;

    // JavaScript의 window.getFaceData() 호출
    final data = js.context.callMethod('getFaceData');
    
    // 1. 상태 처리 (문자열인 경우)
    if (data is String) {
      if (data == "LOADING") {
        status = "AI 모델 로딩 중...";
      } else if (data == "NO_VIDEO") {
        status = "비디오 대기 중...";
      } else if (data == "NO_FACE") {
        status = "얼굴을 찾는 중...";
        // 얼굴을 놓쳤을 때 기존 위치는 유지하되 상태만 업데이트
        if (expression.faceFound) {
          expression = FaceExpression(
            faceFound: false, 
            faceRect: expression.faceRect,
            eyeOpenLeft: 1.0, eyeOpenRight: 1.0, mouthOpen: 0.0
          );
        }
      }
      notifyListeners();
      return;
    }

    // 2. 데이터 처리 (Map 형태의 얼굴 데이터가 들어온 경우)
    if (data != null) {
      try {
        status = "얼굴 감지됨";
        final landmarks = data['landmarks'] as List;
        final blendshapes = data['blendshapes'] as List;

        // 얼굴 영역(Bounding Box) 계산 (정규화된 좌표 0.0 ~ 1.0)
        double minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
        for (var pt in landmarks) {
          double x = pt['x'].toDouble(); 
          double y = pt['y'].toDouble();
          if (x < minX) minX = x; if (x > maxX) maxX = x;
          if (y < minY) minY = y; if (y > maxY) maxY = y;
        }

        // 표정 데이터(Blendshapes) 맵으로 변환
        Map<String, double> scores = {};
        for (var b in blendshapes) {
          scores[b['categoryName']] = b['score'].toDouble();
        }

        // 최종 표정 값 매핑 및 업데이트
        expression = FaceExpression(
          faceFound: true,
          faceRect: Rect.fromLTRB(minX, minY, maxX, maxY),
          // 눈 깜빡임: 1.0(뜸) - blinkScore(감음)
          eyeOpenLeft: 1.0 - (scores['eyeBlinkLeft'] ?? 0),
          eyeOpenRight: 1.0 - (scores['eyeBlinkRight'] ?? 0),
          // 입 벌림: jawOpen 점수를 기반으로 증폭
          mouthOpen: (scores['jawOpen'] ?? 0) * 1.5,
          // 미소: 좌우 입꼬리 미소 점수의 평균
          smile: ((scores['mouthSmileLeft'] ?? 0) + (scores['mouthSmileRight'] ?? 0)) / 2,
          // 눈썹: 내측 눈썹 올림 점수 사용
          browRaiseLeft: scores['browInnerUp'] ?? 0,
          browRaiseRight: scores['browInnerUp'] ?? 0,
        );

        notifyListeners();
      } catch (e) {
        print('Data Parsing Error: $e');
      }
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