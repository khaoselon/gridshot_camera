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
    this.borderColor = Colors.white, // const OK
    this.borderWidth = 2.0, // const OK
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
        (e) => e.name == (map['imageQuality'] ?? ''),
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

// 拡張された境界線色パレット
class BorderColors {
  // ── 追加: Material に無いマゼンタを自前で定数定義 ──
  static const Color magenta = Color(0xFFFF00FF);

  // 基本色パレット（すべて定数）
  static const List<Color> basicColors = <Color>[
    Colors.white,
    Colors.black,
    Colors.grey,
  ];

  // 暖色系（定数）
  static const List<Color> warmColors = <Color>[
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.amber,
    Colors.deepOrange,
  ];

  // 寒色系（定数）
  static const List<Color> coolColors = <Color>[
    Colors.blue,
    Colors.cyan,
    Colors.lightBlue,
    Colors.indigo,
    Colors.blueGrey,
  ];

  // 自然色（定数）
  static const List<Color> natureColors = <Color>[
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.teal,
    Colors.brown,
  ];

  // 鮮やかな色（定数）※ Colors.magenta は存在しないので置き換え
  static const List<Color> vibrantColors = <Color>[
    Colors.purple,
    Colors.pink,
    magenta, // ← 自前定数
    Colors.deepPurple,
  ];

  // 明るいバリエーション（インデックス指定は定数にならないので final）
  static final List<Color> lightVariations = <Color>[
    Colors.red.shade300,
    Colors.orange.shade300,
    Colors.yellow.shade300,
    Colors.green.shade300,
    Colors.blue.shade300,
    Colors.purple.shade300,
    Colors.pink.shade300,
    Colors.cyan.shade300,
  ];

  // 暗いバリエーション（final のままでOK）
  static final List<Color> darkVariations = <Color>[
    Colors.red.shade700,
    Colors.orange.shade700,
    Colors.green.shade700,
    Colors.blue.shade700,
    Colors.purple.shade700,
    Colors.pink.shade700,
    Colors.cyan.shade700,
    Colors.indigo.shade700,
  ];

  // 全ての色をまとめたリスト
  static List<Color> get allColors => <Color>[
    ...basicColors,
    ...warmColors,
    ...coolColors,
    ...natureColors,
    ...vibrantColors,
    ...lightVariations,
    ...darkVariations,
  ];

  // カテゴリ別の色パレット
  static Map<String, List<Color>> get colorCategories => <String, List<Color>>{
    '基本色': basicColors,
    '暖色系': warmColors,
    '寒色系': coolColors,
    '自然色': natureColors,
    '鮮やかな色': vibrantColors,
    '明るい色': lightVariations,
    '暗い色': darkVariations,
  };

  // 推奨色（視認性の高い色）
  static const List<Color> recommendedColors = <Color>[
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
  ];

  static Color getColorByIndex(int index) {
    if (index >= 0 && index < allColors.length) {
      return allColors[index];
    }
    return Colors.white;
  }

  static int getIndexByColor(Color color) {
    final index = allColors.indexWhere((c) => c.value == color.value);
    return index == -1 ? 0 : index;
  }

  // 色の名前を取得
  static String getColorName(Color color) {
    // ここも同じ定数を使用
    const Color magentaColor = magenta;

    final Map<Color, String> colorNames = <Color, String>{
      Colors.white: '白',
      Colors.black: '黒',
      Colors.grey: 'グレー',
      Colors.red: '赤',
      Colors.orange: 'オレンジ',
      Colors.yellow: '黄',
      Colors.amber: 'アンバー',
      Colors.deepOrange: 'ディープオレンジ',
      Colors.blue: '青',
      Colors.cyan: 'シアン',
      Colors.lightBlue: 'ライトブルー',
      Colors.indigo: 'インディゴ',
      Colors.blueGrey: 'ブルーグレー',
      Colors.green: '緑',
      Colors.lightGreen: 'ライトグリーン',
      Colors.lime: 'ライム',
      Colors.teal: 'ティール',
      Colors.brown: '茶',
      Colors.purple: '紫',
      Colors.pink: 'ピンク',
      magentaColor: 'マゼンタ',
      Colors.deepPurple: 'ディープパープル',
    };

    // 完全一致
    final String exactMatch = colorNames.entries
        .firstWhere(
          (entry) => entry.key.value == color.value,
          orElse: () => const MapEntry(Colors.transparent, 'カスタム'),
        )
        .value;

    if (exactMatch != 'カスタム') return exactMatch;

    // 近似判定（簡易）
    final int r = color.red;
    final int g = color.green;
    final int b = color.blue;

    if (r > 200 && g > 200 && b > 200) return '明るい色';
    if (r < 100 && g < 100 && b < 100) return '暗い色';
    if (r > g && r > b) return '赤系';
    if (g > r && g > b) return '緑系';
    if (b > r && b > g) return '青系';

    return 'カスタム';
  }

  // コントラストの良い色を取得（境界線用）
  static Color getContrastColor(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  // 視認性チェック（簡易版）
  static bool hasGoodVisibility(Color borderColor, Color backgroundColor) {
    final borderLuminance = borderColor.computeLuminance();
    final backgroundLuminance = backgroundColor.computeLuminance();
    final contrast = (borderLuminance + 0.05) / (backgroundLuminance + 0.05);
    return contrast > 3.0 || contrast < 1 / 3.0;
  }

  // カメラ撮影時の推奨色
  static List<Color> getCameraRecommendedColors() => <Color>[
    Colors.white, // 暗い背景
    Colors.black, // 明るい背景
    Colors.red, // 汎用的
    Colors.yellow, // 高視認性
    Colors.cyan, // デジタル表示風
    Colors.lime, // 鮮やか
  ];
}
