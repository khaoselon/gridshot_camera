import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gridshot_camera/models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get instance => _instance;

  SettingsService._internal();

  SharedPreferences? _prefs;
  AppSettings _currentSettings = const AppSettings();

  static const String _settingsKey = 'app_settings';

  AppSettings get currentSettings => _currentSettings;

  /// 設定サービスを初期化
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
    } catch (e) {
      debugPrint('設定の初期化に失敗しました: $e');
      // デフォルト設定を使用
      _currentSettings = const AppSettings();
    }
  }

  /// 設定をロード
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    try {
      final settingsJson = _prefs!.getString(_settingsKey);
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson) as Map<String, dynamic>;
        _currentSettings = AppSettings.fromMap(settingsMap);
      } else {
        // 初回起動時はデフォルト設定を保存
        await _saveSettings();
      }
    } catch (e) {
      debugPrint('設定の読み込みに失敗しました: $e');
      // デフォルト設定を使用してリセット
      _currentSettings = const AppSettings();
      await _saveSettings();
    }

    notifyListeners();
  }

  /// 設定を保存
  Future<void> _saveSettings() async {
    if (_prefs == null) return;

    try {
      final settingsJson = json.encode(_currentSettings.toMap());
      await _prefs!.setString(_settingsKey, settingsJson);
    } catch (e) {
      debugPrint('設定の保存に失敗しました: $e');
    }
  }

  /// 設定を更新
  Future<void> updateSettings(AppSettings newSettings) async {
    _currentSettings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  /// 言語を変更
  Future<void> updateLanguage(String languageCode) async {
    final newSettings = _currentSettings.copyWith(languageCode: languageCode);
    await updateSettings(newSettings);
  }

  /// グリッド境界線の表示設定を変更
  Future<void> updateGridBorderDisplay(bool show) async {
    final newSettings = _currentSettings.copyWith(showGridBorder: show);
    await updateSettings(newSettings);
  }

  /// 境界線の色を変更
  Future<void> updateBorderColor(Color color) async {
    final newSettings = _currentSettings.copyWith(borderColor: color);
    await updateSettings(newSettings);
  }

  /// 境界線の太さを変更
  Future<void> updateBorderWidth(double width) async {
    final newSettings = _currentSettings.copyWith(borderWidth: width);
    await updateSettings(newSettings);
  }

  /// 画像品質を変更
  Future<void> updateImageQuality(ImageQuality quality) async {
    final newSettings = _currentSettings.copyWith(imageQuality: quality);
    await updateSettings(newSettings);
  }

  /// 広告表示設定を変更
  Future<void> updateAdDisplay(bool showAds) async {
    final newSettings = _currentSettings.copyWith(showAds: showAds);
    await updateSettings(newSettings);
  }

  /// トラッキング許可要求フラグを更新
  Future<void> updateTrackingRequested(bool requested) async {
    final newSettings = _currentSettings.copyWith(
      hasRequestedTracking: requested,
    );
    await updateSettings(newSettings);
  }

  /// 設定をリセット（デフォルトに戻す）
  Future<void> resetSettings() async {
    _currentSettings = const AppSettings();
    await _saveSettings();
    notifyListeners();
  }

  /// 特定の設定値を取得するためのヘルパーメソッド
  bool get isJapanese => _currentSettings.languageCode == 'ja';
  bool get isEnglish => _currentSettings.languageCode == 'en';
  bool get shouldShowAds => _currentSettings.showAds;
  bool get shouldShowGridBorder => _currentSettings.showGridBorder;

  /// 設定の妥当性をチェック
  bool validateSettings() {
    try {
      // 言語コードの妥当性チェック
      if (!['ja', 'en'].contains(_currentSettings.languageCode)) {
        return false;
      }

      // 境界線の太さの妥当性チェック
      if (_currentSettings.borderWidth < 0.5 ||
          _currentSettings.borderWidth > 10.0) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('設定の妥当性チェックでエラー: $e');
      return false;
    }
  }

  /// デバッグ用：現在の設定を出力
  void debugPrintSettings() {
    debugPrint('=== 現在の設定 ===');
    debugPrint('言語: ${_currentSettings.languageCode}');
    debugPrint('グリッド境界線表示: ${_currentSettings.showGridBorder}');
    debugPrint('境界線色: ${_currentSettings.borderColor}');
    debugPrint('境界線太さ: ${_currentSettings.borderWidth}');
    debugPrint('画像品質: ${_currentSettings.imageQuality.displayName}');
    debugPrint('広告表示: ${_currentSettings.showAds}');
    debugPrint('トラッキング許可要求済み: ${_currentSettings.hasRequestedTracking}');
    debugPrint('==================');
  }
}
