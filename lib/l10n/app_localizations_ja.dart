// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'GridShot Camera';

  @override
  String get homeTitle => '撮影モード選択';

  @override
  String get catalogMode => 'カタログモード';

  @override
  String get catalogModeDescription => '複数の被写体を各マスに収めて一覧化';

  @override
  String get impossibleMode => '不可能合成モード';

  @override
  String get impossibleModeDescription => '同じシーンを分割順に撮影して合成';

  @override
  String get gridStyle => 'グリッドスタイル';

  @override
  String get grid2x2 => '2×2';

  @override
  String get grid2x3 => '2×3';

  @override
  String get grid3x2 => '3×2';

  @override
  String get grid3x3 => '3×3';

  @override
  String get startShooting => '撮影開始';

  @override
  String get settings => '設定';

  @override
  String get cameraTitle => '撮影中';

  @override
  String currentPosition(String position) {
    return '現在位置: $position';
  }

  @override
  String get tapToShoot => 'タップで撮影';

  @override
  String get retake => '撮り直し';

  @override
  String get next => '次へ';

  @override
  String get complete => '完了';

  @override
  String get previewTitle => 'プレビュー';

  @override
  String get save => '保存';

  @override
  String get share => '共有';

  @override
  String get cancel => 'キャンセル';

  @override
  String get settingsTitle => '設定';

  @override
  String get language => '言語';

  @override
  String get japanese => '日本語';

  @override
  String get english => 'English';

  @override
  String get gridBorder => 'グリッド境界線';

  @override
  String get borderColor => '境界線の色';

  @override
  String get borderWidth => '境界線の太さ';

  @override
  String get imageQuality => '画像品質';

  @override
  String get high => '高';

  @override
  String get medium => '中';

  @override
  String get low => '低';

  @override
  String get adSettings => '広告設定';

  @override
  String get showAds => '広告を表示';

  @override
  String get cameraPermission => 'カメラ許可';

  @override
  String get cameraPermissionMessage => '写真を撮影するためにカメラへのアクセスが必要です。設定でカメラアクセスを許可してください。';

  @override
  String get storagePermission => 'ストレージ許可';

  @override
  String get storagePermissionMessage => '写真を保存するためにストレージへのアクセスが必要です。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get error => 'エラー';

  @override
  String get saveSuccess => '画像が保存されました';

  @override
  String get saveFailed => '画像の保存に失敗しました';

  @override
  String get shareSuccess => '画像が共有されました';

  @override
  String get loading => '読み込み中...';

  @override
  String get processing => '処理中...';

  @override
  String get compositing => '合成中...';

  @override
  String get trackingPermissionTitle => 'アプリトラッキング許可';

  @override
  String get trackingPermissionMessage => '広告をパーソナライズするために、他のアプリでのアクティビティ追跡を許可してください。';

  @override
  String get allow => '許可';

  @override
  String get dontAllow => '許可しない';
}
