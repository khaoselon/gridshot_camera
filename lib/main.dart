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

      // 明るいテーマ設定
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // メインカラー設定（明るい紫系）
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF), // 明るい紫
          brightness: Brightness.light,
          primary: const Color(0xFF7C4DFF),
          secondary: const Color(0xFF9C88FF),
          surface: Colors.grey[50]!,
          background: const Color(0xFFFAF9FF), // 非常に薄い紫がかった白
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.grey[800]!,
          onBackground: Colors.grey[900]!,
        ),

        // AppBarテーマ
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF7C4DFF),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        // ボタンテーマ
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF),
            foregroundColor: Colors.white,
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // アウトラインボタンテーマ
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF7C4DFF),
            side: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // カードテーマ
        cardTheme: CardThemeData(
          elevation: 6,
          shadowColor: const Color(0xFF7C4DFF).withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),

        // フォントファミリー
        fontFamily: 'NotoSansJP',

        // テキストテーマ
        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          headlineLarge: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          headlineMedium: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          titleLarge: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          titleMedium: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          bodyLarge: TextStyle(color: Colors.grey[800], letterSpacing: 0.3),
          bodyMedium: TextStyle(color: Colors.grey[700], letterSpacing: 0.3),
        ),

        // その他のコンポーネントテーマ
        scaffoldBackgroundColor: const Color(0xFFFAF9FF),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF7C4DFF),
          foregroundColor: Colors.white,
          elevation: 8,
        ),

        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF7C4DFF);
            }
            return Colors.grey[400];
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF7C4DFF).withOpacity(0.3);
            }
            return Colors.grey[300];
          }),
        ),

        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF7C4DFF),
          inactiveTrackColor: const Color(0xFF7C4DFF).withOpacity(0.3),
          thumbColor: const Color(0xFF7C4DFF),
          overlayColor: const Color(0xFF7C4DFF).withOpacity(0.2),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF7C4DFF),
          linearTrackColor: Color(0xFFE1BEE7),
          circularTrackColor: Color(0xFFE1BEE7),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[700]),
        ),
      ),

      // ダークテーマ設定（明るめに調整）
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C88FF),
          brightness: Brightness.dark,
          primary: const Color(0xFF9C88FF),
          secondary: const Color(0xFFBBAAFF),
          surface: Colors.grey[850]!,
          background: const Color(0xFF121212),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),

        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: const Color(0xFF9C88FF).withOpacity(0.3),
          color: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        fontFamily: 'NotoSansJP',
        scaffoldBackgroundColor: const Color(0xFF121212),
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
