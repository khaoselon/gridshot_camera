import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';

import 'package:gridshot_camera/screens/home_screen.dart';
import 'package:gridshot_camera/services/settings_service.dart';
import 'package:gridshot_camera/services/ad_service.dart';
import 'package:gridshot_camera/models/app_settings.dart';
import 'package:gridshot_camera/l10n/app_localizations.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 画面の向きを固定（Portrait）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // AdMob初期化
  await MobileAds.instance.initialize();

  // カメラの初期化
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('カメラの初期化に失敗しました: $e');
  }

  // 設定サービスの初期化
  await SettingsService.instance.initialize();

  // AdMobサービスの初期化
  AdService.instance.initialize();

  runApp(const GridShotCameraApp());
}

class GridShotCameraApp extends StatefulWidget {
  const GridShotCameraApp({super.key});

  @override
  State<GridShotCameraApp> createState() => _GridShotCameraAppState();
}

class _GridShotCameraAppState extends State<GridShotCameraApp>
    with WidgetsBindingObserver {
  late AppSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentSettings = SettingsService.instance.currentSettings;

    // 設定変更を監視
    SettingsService.instance.addListener(_onSettingsChanged);

    // アプリ起動後にトラッキング許可を要求
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestTrackingPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {
      _currentSettings = SettingsService.instance.currentSettings;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // アプリがフォアグラウンドに戻った時の処理
        AdService.instance.resumeAds();
        break;
      case AppLifecycleState.paused:
        // アプリがバックグラウンドに移った時の処理
        AdService.instance.pauseAds();
        break;
      case AppLifecycleState.detached:
        // アプリが終了する時の処理
        AdService.instance.dispose();
        break;
      default:
        break;
    }
  }

  Future<void> _requestTrackingPermission() async {
    // iOSでのみApp Tracking Transparencyの許可を要求
    if (Platform.isIOS && !_currentSettings.hasRequestedTracking) {
      try {
        final status =
            await AppTrackingTransparency.requestTrackingAuthorization();

        // 許可要求したことを記録
        await SettingsService.instance.updateSettings(
          _currentSettings.copyWith(hasRequestedTracking: true),
        );

        // 許可状況に応じて広告設定を更新
        AdService.instance.updateTrackingStatus(status);

        debugPrint('App Tracking Transparency Status: $status');
      } catch (e) {
        debugPrint('App Tracking Transparency要求エラー: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridShot Camera',
      debugShowCheckedModeBanner: false,

      // 多言語化設定
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'), // 日本語
        Locale('en'), // 英語
      ],
      locale: Locale(_currentSettings.languageCode),

      // テーマ設定
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'NotoSansJP',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ダークテーマ設定
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'NotoSansJP',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          color: Colors.grey[850],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      // システムのテーマに従う
      themeMode: ThemeMode.system,

      home: const HomeScreen(),
    );
  }
}

// エラーハンドリングとクラッシュレポート
class AppErrorHandler {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // TODO: ここでFirebase Crashlyticsにレポートを送信
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack Trace: ${details.stack}');
    };
  }
}
