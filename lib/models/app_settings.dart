import 'dart:ui';
import 'package:flutter/material.dart';

class AppSettings {
  final String languageCode;
  final bool showGridBorder;
  final Color borderColor;
  final double borderWidth;
  final ImageQuality imageQuality;
  final bool showAds;
  final bool hasRequestedTracking;

  const AppSettings({
    this.languageCode = 'ja',
    this.showGridBorder = true,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.imageQuality = ImageQuality.high,
    this.showAds = true,
    this.hasRequestedTracking = false,
  });

  AppSettings copyWith({
    String? languageCode,
    bool? showGridBorder,
    Color? borderColor,
    double? borderWidth,
    ImageQuality? imageQuality,
    bool? showAds,
    bool? hasRequestedTracking,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      showGridBorder: showGridBorder ?? this.showGridBorder,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      imageQuality: imageQuality ?? this.imageQuality,
      showAds: showAds ?? this.showAds,
      hasRequestedTracking: hasRequestedTracking ?? this.hasRequestedTracking,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'languageCode': languageCode,
      'showGridBorder': showGridBorder,
      'borderColor': borderColor.value,
      'borderWidth': borderWidth,
      'imageQuality': imageQuality.name,
      'showAds': showAds,
      'hasRequestedTracking': hasRequestedTracking,
    };
  }

  static AppSettings fromMap(Map<String, dynamic> map) {
    return AppSettings(
      languageCode: map['languageCode'] ?? 'ja',
      showGridBorder: map['showGridBorder'] ?? true,
      borderColor: Color(map['borderColor'] ?? Colors.white.value),
      borderWidth: (map['borderWidth'] ?? 2.0).toDouble(),
      imageQuality: ImageQuality.values.firstWhere(
        (e) => e.name == map['imageQuality'],
        orElse: () => ImageQuality.high,
      ),
      showAds: map['showAds'] ?? true,
      hasRequestedTracking: map['hasRequestedTracking'] ?? false,
    );
  }
}

enum ImageQuality {
  low(50),
  medium(75),
  high(95);

  const ImageQuality(this.quality);

  final int quality;

  String get displayName {
    switch (this) {
      case ImageQuality.low:
        return 'low';
      case ImageQuality.medium:
        return 'medium';
      case ImageQuality.high:
        return 'high';
    }
  }
}

// 事前定義された境界線色
class BorderColors {
  static const List<Color> predefinedColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.cyan,
    Colors.pink,
  ];

  static Color getColorByIndex(int index) {
    if (index >= 0 && index < predefinedColors.length) {
      return predefinedColors[index];
    }
    return Colors.white;
  }

  static int getIndexByColor(Color color) {
    final index = predefinedColors.indexOf(color);
    return index == -1 ? 0 : index;
  }
}
