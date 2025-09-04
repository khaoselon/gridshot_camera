import 'dart:io';
import 'dart:ui' show Offset, Size;
import 'package:gridshot_camera/models/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:gridshot_camera/main.dart';
import 'package:gridshot_camera/models/grid_style.dart';
import 'package:gridshot_camera/models/shooting_mode.dart';
import 'package:gridshot_camera/services/settings_service.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _lastError;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get hasError => _lastError != null;
  String? get lastError => _lastError;
  bool get isDisposed => _isDisposed;

  /// カメラを初期化
  Future<bool> initialize({CameraDescription? preferredCamera}) async {
    if (_isDisposed) return false;

    try {
      _lastError = null;

      // カメラが利用可能かチェック
      if (cameras.isEmpty) {
        _lastError = 'カメラデバイスが見つかりません';
        notifyListeners();
        return false;
      }

      // 使用するカメラを選択（背面カメラを優先）
      CameraDescription camera;
      if (preferredCamera != null) {
        camera = preferredCamera;
      } else {
        camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }

      // カメラコントローラーを作成
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false, // 音声は不要
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      // フラッシュを自動に設定
      await _controller!.setFlashMode(FlashMode.auto);

      // フォーカスモードを自動に設定
      await _controller!.setFocusMode(FocusMode.auto);

      _isInitialized = true;
      debugPrint('カメラの初期化完了');
    } catch (e) {
      _lastError = 'カメラの初期化に失敗しました: $e';
      debugPrint(_lastError);
      _isInitialized = false;
    }

    if (!_isDisposed) {
      notifyListeners();
    }
    return _isInitialized;
  }

  /// 写真を撮影
  Future<String?> takePicture({
    required GridPosition position,
    String? customFileName,
  }) async {
    if (!_isInitialized || _controller == null || _isDisposed) {
      _lastError = 'カメラが初期化されていません';
      notifyListeners();
      return null;
    }

    try {
      _lastError = null;

      // 保存ディレクトリを取得
      final directory = await getTemporaryDirectory();
      final fileName =
          customFileName ??
          'gridshot_${position.displayString}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(directory.path, fileName);

      // 撮影実行
      final image = await _controller!.takePicture();

      // ファイルを目的のパスにコピー
      final file = File(image.path);
      final savedFile = await file.copy(filePath);

      // 一時ファイルを削除
      try {
        await file.delete();
      } catch (e) {
        debugPrint('一時ファイルの削除に失敗: $e');
      }

      debugPrint('写真を保存しました: $filePath');
      return savedFile.path;
    } catch (e) {
      _lastError = '写真の撮影に失敗しました: $e';
      debugPrint(_lastError);
      notifyListeners();
      return null;
    }
  }

  /// フラッシュモードを切り替え
  Future<void> toggleFlashMode() async {
    if (!_isInitialized || _controller == null) return;

    try {
      final currentMode = _controller!.value.flashMode;
      FlashMode newMode;

      switch (currentMode) {
        case FlashMode.off:
          newMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          newMode = FlashMode.always;
          break;
        case FlashMode.always:
          newMode = FlashMode.off;
          break;
        case FlashMode.torch:
          newMode = FlashMode.off;
          break;
      }

      await _controller!.setFlashMode(newMode);
      debugPrint('フラッシュモードを変更: $newMode');
      notifyListeners();
    } catch (e) {
      debugPrint('フラッシュモードの変更に失敗: $e');
    }
  }

  /// フォーカスを指定位置に設定
  Future<void> setFocusPoint(Offset point, Size screenSize) async {
    if (!_isInitialized || _controller == null) return;

    try {
      // 画面座標をカメラ座標に変換
      final x = point.dx / screenSize.width;
      final y = point.dy / screenSize.height;

      await _controller!.setFocusPoint(Offset(x, y));
      await _controller!.setExposurePoint(Offset(x, y));

      debugPrint('フォーカスポイントを設定: ($x, $y)');
    } catch (e) {
      debugPrint('フォーカスポイントの設定に失敗: $e');
    }
  }

  /// ズーム倍率を設定
  Future<void> setZoomLevel(double zoom) async {
    if (!_isInitialized || _controller == null) return;

    try {
      final maxZoom = await _controller!.getMaxZoomLevel();
      final minZoom = await _controller!.getMinZoomLevel();

      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(clampedZoom);

      notifyListeners();
    } catch (e) {
      debugPrint('ズームレベルの設定に失敗: $e');
    }
  }

  /// 現在のズーム倍率を取得
  Future<double> getCurrentZoomLevel() async {
    if (!_isInitialized || _controller == null) return 1.0;

    try {
      // 新しいFlutter版では、ズーム値は直接取得できないため、内部で管理
      return 1.0; // デフォルト値を返す
    } catch (e) {
      debugPrint('ズームレベルの取得に失敗: $e');
      return 1.0;
    }
  }

  /// 最大ズーム倍率を取得
  Future<double> getMaxZoomLevel() async {
    if (!_isInitialized || _controller == null) return 1.0;

    try {
      return await _controller!.getMaxZoomLevel();
    } catch (e) {
      debugPrint('最大ズームレベルの取得に失敗: $e');
      return 1.0;
    }
  }

  /// カメラの向きを切り替え
  Future<void> switchCamera() async {
    if (cameras.length < 2) return;

    try {
      _lastError = null;

      // 現在のカメラとは異なるカメラを選択
      final currentLensDirection = _controller?.description.lensDirection;
      final newCamera = cameras.firstWhere(
        (camera) => camera.lensDirection != currentLensDirection,
        orElse: () => cameras.first,
      );

      await dispose();
      await initialize(preferredCamera: newCamera);
    } catch (e) {
      _lastError = 'カメラの切り替えに失敗しました: $e';
      debugPrint(_lastError);
      notifyListeners();
    }
  }

  /// プレビューサイズを取得
  Size? getPreviewSize() {
    if (!_isInitialized || _controller == null) return null;
    return _controller!.value.previewSize;
  }

  /// カメラの状態情報を取得
  Map<String, dynamic> getCameraInfo() {
    if (!_isInitialized || _controller == null) {
      return {'isInitialized': false, 'error': _lastError};
    }

    return {
      'isInitialized': _isInitialized,
      'lensDirection': _controller!.description.lensDirection.name,
      'flashMode': _controller!.value.flashMode.name,
      'previewSize': _controller!.value.previewSize,
      'hasError': _controller!.value.hasError,
      'errorDescription': _controller!.value.errorDescription,
    };
  }

  /// 撮影設定を適用
  Future<void> applyShootingSettings(ShootingSession session) async {
    if (!_isInitialized || _controller == null) return;

    try {
      final settings = SettingsService.instance.currentSettings;

      // 画質設定を適用（ここでは解像度で代用）
      ResolutionPreset resolution;
      switch (settings.imageQuality) {
        case ImageQuality.high:
          resolution = ResolutionPreset.high;
          break;
        case ImageQuality.medium:
          resolution = ResolutionPreset.medium;
          break;
        case ImageQuality.low:
          resolution = ResolutionPreset.low;
          break;
      }

      // 必要に応じてカメラを再初期化
      if (_controller!.resolutionPreset != resolution) {
        final currentCamera = _controller!.description;
        await dispose();

        _controller = CameraController(
          currentCamera,
          resolution,
          enableAudio: false,
        );

        await _controller!.initialize();
        _isInitialized = true;
      }

      debugPrint('撮影設定を適用しました');
      notifyListeners();
    } catch (e) {
      debugPrint('撮影設定の適用に失敗: $e');
    }
  }

  /// リソースを解放
  @override
  Future<void> dispose() async {
    _isDisposed = true;

    if (_controller != null) {
      try {
        await _controller!.dispose();
        debugPrint('カメラリソースを解放しました');
      } catch (e) {
        debugPrint('カメラリソース解放時にエラー: $e');
      }
      _controller = null;
    }

    _isInitialized = false;
    super.dispose();
  }

  /// エラー状態をクリア
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// カメラの利用可能性をチェック
  static Future<bool> checkCameraAvailability() async {
    try {
      if (cameras.isEmpty) {
        return false;
      }

      // 簡単なテスト初期化
      final testController = CameraController(
        cameras.first,
        ResolutionPreset.low,
        enableAudio: false,
      );

      await testController.initialize();
      await testController.dispose();

      return true;
    } catch (e) {
      debugPrint('カメラ利用可能性チェック失敗: $e');
      return false;
    }
  }
}
