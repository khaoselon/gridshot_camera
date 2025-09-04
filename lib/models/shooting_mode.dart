import 'grid_style.dart';

enum ShootingMode {
  catalog,
  impossible;

  String get name {
    switch (this) {
      case ShootingMode.catalog:
        return 'catalog';
      case ShootingMode.impossible:
        return 'impossible';
    }
  }

  bool get isCatalogMode => this == ShootingMode.catalog;
  bool get isImpossibleMode => this == ShootingMode.impossible;
}

class ShootingSession {
  final ShootingMode mode;
  final GridStyle gridStyle;
  final List<CapturedImage?> capturedImages;
  int currentIndex;

  ShootingSession({required this.mode, required this.gridStyle})
    : capturedImages = List.filled(gridStyle.totalCells, null),
      currentIndex = 0;

  bool get isCompleted => capturedImages.every((image) => image != null);
  bool get hasCurrentImage =>
      currentIndex < capturedImages.length &&
      capturedImages[currentIndex] != null;
  int get completedCount =>
      capturedImages.where((image) => image != null).length;
  double get progress => completedCount / gridStyle.totalCells;

  GridPosition get currentPosition => gridStyle.getPosition(currentIndex);

  void captureImage(CapturedImage image) {
    if (currentIndex < capturedImages.length) {
      capturedImages[currentIndex] = image;
    }
  }

  void retakeImage(int index, CapturedImage image) {
    if (index >= 0 && index < capturedImages.length) {
      capturedImages[index] = image;
    }
  }

  void moveToNext() {
    if (currentIndex < capturedImages.length - 1) {
      currentIndex++;
    }
  }

  void moveToPrevious() {
    if (currentIndex > 0) {
      currentIndex--;
    }
  }

  void jumpToIndex(int index) {
    if (index >= 0 && index < capturedImages.length) {
      currentIndex = index;
    }
  }

  List<CapturedImage> getCompletedImages() {
    return capturedImages.whereType<CapturedImage>().toList();
  }

  void reset() {
    capturedImages.fillRange(0, capturedImages.length, null);
    currentIndex = 0;
  }
}

class CapturedImage {
  final String filePath;
  final DateTime timestamp;
  final GridPosition position;

  CapturedImage({
    required this.filePath,
    required this.timestamp,
    required this.position,
  });

  @override
  String toString() {
    return 'CapturedImage(filePath: $filePath, position: $position, timestamp: $timestamp)';
  }
}
