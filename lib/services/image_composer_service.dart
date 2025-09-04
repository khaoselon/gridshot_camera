import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:gallery_saver/gallery_saver.dart';
import 'package:gridshot_camera/models/grid_style.dart';
import 'package:gridshot_camera/models/shooting_mode.dart';
import 'package:gridshot_camera/models/app_settings.dart';
import 'package:gridshot_camera/services/settings_service.dart';

class ImageComposerService {
  static final ImageComposerService _instance =
      ImageComposerService._internal();
  static ImageComposerService get instance => _instance;

  ImageComposerService._internal();

  /// 複数の画像を1つのグリッド画像に合成
  Future<CompositeResult> composeGridImage({
    required ShootingSession session,
    AppSettings? settings,
  }) async {
    try {
      final appSettings = settings ?? SettingsService.instance.currentSettings;
      final images = session.getCompletedImages();

      if (images.length != session.gridStyle.totalCells) {
        throw Exception('撮影が完了していない画像があります');
      }

      debugPrint('画像合成を開始: ${images.length}枚の画像');

      // 各画像を読み込み
      List<img.Image> loadedImages = [];
      for (final capturedImage in images) {
        final file = File(capturedImage.filePath);
        if (!await file.exists()) {
          throw Exception('画像ファイルが見つかりません: ${capturedImage.filePath}');
        }

        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) {
          throw Exception('画像のデコードに失敗しました: ${capturedImage.filePath}');
        }
        loadedImages.add(image);
      }

      // 画像サイズを統一（最小サイズに合わせる）
      final targetSize = _calculateTargetSize(loadedImages);
      debugPrint('目標画像サイズ: ${targetSize.width}x${targetSize.height}');

      // 各画像をリサイズ
      List<img.Image> resizedImages = [];
      for (final image in loadedImages) {
        final resized = img.copyResize(
          image,
          width: targetSize.width,
          height: targetSize.height,
          interpolation: img.Interpolation.linear,
        );
        resizedImages.add(resized);
      }

      // グリッド画像を合成
      final compositeImage = _createGridComposite(
        images: resizedImages,
        gridStyle: session.gridStyle,
        settings: appSettings,
      );

      // 合成画像を保存
      final savedPath = await _saveCompositeImage(
        compositeImage,
        session,
        appSettings,
      );

      debugPrint('画像合成完了: $savedPath');

      return CompositeResult(
        success: true,
        filePath: savedPath,
        message: '画像の合成が完了しました',
      );
    } catch (e) {
      debugPrint('画像合成エラー: $e');
      return CompositeResult(success: false, message: '画像の合成に失敗しました: $e');
    }
  }

  /// 目標画像サイズを計算
  ImageSize _calculateTargetSize(List<img.Image> images) {
    if (images.isEmpty) {
      return const ImageSize(width: 1080, height: 1080);
    }

    // 最小の幅と高さを取得
    int minWidth = images.first.width;
    int minHeight = images.first.height;

    for (final image in images) {
      minWidth = minWidth < image.width ? minWidth : image.width;
      minHeight = minHeight < image.height ? minHeight : image.height;
    }

    // アスペクト比を1:1に調整
    final targetSize = minWidth < minHeight ? minWidth : minHeight;

    return ImageSize(width: targetSize, height: targetSize);
  }

  /// グリッド合成画像を作成
  img.Image _createGridComposite({
    required List<img.Image> images,
    required GridStyle gridStyle,
    required AppSettings settings,
  }) {
    if (images.isEmpty) {
      throw Exception('合成する画像がありません');
    }

    final cellWidth = images.first.width;
    final cellHeight = images.first.height;
    final borderWidth = settings.showGridBorder
        ? settings.borderWidth.toInt()
        : 0;

    // 合成画像のサイズを計算
    final compositeWidth =
        (cellWidth * gridStyle.columns) +
        (borderWidth * (gridStyle.columns - 1));
    final compositeHeight =
        (cellHeight * gridStyle.rows) + (borderWidth * (gridStyle.rows - 1));

    debugPrint('合成画像サイズ: ${compositeWidth}x${compositeHeight}');

    // 合成画像を作成
    final composite = img.Image(
      width: compositeWidth,
      height: compositeHeight,
      format: img.Format.uint8,
      numChannels: 3,
    );

    // 背景色（境界線の色）で埋める
    if (settings.showGridBorder && borderWidth > 0) {
      final borderColor = _convertFlutterColorToImageColor(
        settings.borderColor,
      );
      img.fill(composite, color: borderColor);
    }

    // 各画像を適切な位置に配置
    for (int i = 0; i < images.length && i < gridStyle.totalCells; i++) {
      final position = gridStyle.getPosition(i);
      final x = (position.col * cellWidth) + (position.col * borderWidth);
      final y = (position.row * cellHeight) + (position.row * borderWidth);

      img.compositeImage(composite, images[i], dstX: x, dstY: y);
    }

    return composite;
  }

  /// Flutter ColorをImageライブラリのColorに変換
  img.Color _convertFlutterColorToImageColor(ui.Color flutterColor) {
    return img.ColorRgb8(
      flutterColor.red,
      flutterColor.green,
      flutterColor.blue,
    );
  }

  /// 合成画像を保存
  Future<String> _saveCompositeImage(
    img.Image image,
    ShootingSession session,
    AppSettings settings,
  ) async {
    // 保存ディレクトリを取得
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now();
    final fileName =
        'gridshot_${session.mode.name}_${session.gridStyle.displayName}_${timestamp.millisecondsSinceEpoch}.jpg';
    final filePath = path.join(directory.path, fileName);

    // JPEG品質を設定
    final jpegBytes = img.encodeJpg(
      image,
      quality: settings.imageQuality.quality,
    );

    // ファイルに保存
    final file = File(filePath);
    await file.writeAsBytes(jpegBytes);

    // ギャラリーに保存（ユーザーが確認できるように）
    try {
      await GallerySaver.saveImage(filePath);
      debugPrint('ギャラリーへの保存完了');
    } catch (e) {
      debugPrint('ギャラリー保存エラー（続行）: $e');
    }

    return filePath;
  }

  /// 画像のメタデータを取得
  Future<ImageMetadata?> getImageMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return null;
      }

      final stat = await file.stat();

      return ImageMetadata(
        width: image.width,
        height: image.height,
        fileSize: stat.size,
        format: path.extension(filePath).toLowerCase(),
        modificationTime: stat.modified,
      );
    } catch (e) {
      debugPrint('画像メタデータの取得に失敗: $e');
      return null;
    }
  }

  /// 一時ファイルを削除
  Future<void> cleanupTemporaryFiles(ShootingSession session) async {
    try {
      for (final capturedImage in session.getCompletedImages()) {
        final file = File(capturedImage.filePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('一時ファイルを削除: ${capturedImage.filePath}');
        }
      }
    } catch (e) {
      debugPrint('一時ファイル削除エラー: $e');
    }
  }

  /// プレビュー用の縮小画像を作成
  Future<String?> createPreviewImage(
    String originalPath, {
    int maxSize = 500,
  }) async {
    try {
      final file = File(originalPath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return null;
      }

      // プレビューサイズに縮小
      final preview = img.copyResize(
        image,
        width: image.width > image.height ? maxSize : null,
        height: image.height > image.width ? maxSize : null,
        interpolation: img.Interpolation.linear,
      );

      // プレビューファイルを保存
      final directory = await getTemporaryDirectory();
      final fileName = 'preview_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final previewPath = path.join(directory.path, fileName);

      final previewBytes = img.encodeJpg(preview, quality: 80);
      final previewFile = File(previewPath);
      await previewFile.writeAsBytes(previewBytes);

      return previewPath;
    } catch (e) {
      debugPrint('プレビュー画像作成エラー: $e');
      return null;
    }
  }

  /// サポートされている画像形式かチェック
  bool isSupportedImageFormat(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.bmp', '.tiff'].contains(extension);
  }
}

// 結果クラス
class CompositeResult {
  final bool success;
  final String? filePath;
  final String message;

  CompositeResult({
    required this.success,
    this.filePath,
    required this.message,
  });
}

// 画像メタデータクラス
class ImageMetadata {
  final int width;
  final int height;
  final int fileSize;
  final String format;
  final DateTime modificationTime;

  ImageMetadata({
    required this.width,
    required this.height,
    required this.fileSize,
    required this.format,
    required this.modificationTime,
  });

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get dimensionsFormatted => '${width}x${height}';
}

// 画像サイズクラス
class ImageSize {
  final int width;
  final int height;

  const ImageSize({required this.width, required this.height});

  double get aspectRatio => width / height;
  bool get isSquare => width == height;
  bool get isLandscape => width > height;
  bool get isPortrait => height > width;
}
