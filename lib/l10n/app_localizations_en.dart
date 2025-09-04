// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GridShot Camera';

  @override
  String get homeTitle => 'Select Shooting Mode';

  @override
  String get catalogMode => 'Catalog Mode';

  @override
  String get catalogModeDescription => 'Capture different subjects in each grid cell for cataloging';

  @override
  String get impossibleMode => 'Impossible Composite Mode';

  @override
  String get impossibleModeDescription => 'Shoot the same scene in grid order to create impossible compositions';

  @override
  String get gridStyle => 'Grid Style';

  @override
  String get grid2x2 => '2×2';

  @override
  String get grid2x3 => '2×3';

  @override
  String get grid3x2 => '3×2';

  @override
  String get grid3x3 => '3×3';

  @override
  String get startShooting => 'Start Shooting';

  @override
  String get settings => 'Settings';

  @override
  String get cameraTitle => 'Shooting';

  @override
  String currentPosition(String position) {
    return 'Current: $position';
  }

  @override
  String get tapToShoot => 'Tap to Shoot';

  @override
  String get retake => 'Retake';

  @override
  String get next => 'Next';

  @override
  String get complete => 'Complete';

  @override
  String get previewTitle => 'Preview';

  @override
  String get save => 'Save';

  @override
  String get share => 'Share';

  @override
  String get cancel => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get japanese => '日本語';

  @override
  String get english => 'English';

  @override
  String get gridBorder => 'Grid Border';

  @override
  String get borderColor => 'Border Color';

  @override
  String get borderWidth => 'Border Width';

  @override
  String get imageQuality => 'Image Quality';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get adSettings => 'Ad Settings';

  @override
  String get showAds => 'Show Ads';

  @override
  String get cameraPermission => 'Camera Permission';

  @override
  String get cameraPermissionMessage => 'Camera access is required to take photos. Please allow camera access in settings.';

  @override
  String get storagePermission => 'Storage Permission';

  @override
  String get storagePermissionMessage => 'Storage access is required to save photos.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get error => 'Error';

  @override
  String get saveSuccess => 'Image saved successfully';

  @override
  String get saveFailed => 'Failed to save image';

  @override
  String get shareSuccess => 'Image shared successfully';

  @override
  String get loading => 'Loading...';

  @override
  String get processing => 'Processing...';

  @override
  String get compositing => 'Compositing...';

  @override
  String get trackingPermissionTitle => 'App Tracking Permission';

  @override
  String get trackingPermissionMessage => 'Allow app tracking across other apps to personalize ads.';

  @override
  String get allow => 'Allow';

  @override
  String get dontAllow => 'Don\'t Allow';
}
