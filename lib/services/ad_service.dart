import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  static AdService get instance => _instance;

  AdService._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInitialized = false;
  bool _isTrackingAuthorized = false;
  int _interstitialShowCount = 0;
  DateTime? _lastInterstitialShow;

  // インタースティシャル広告の表示間隔（分）
  static const int _interstitialCooldownMinutes = 3;
  static const int _interstitialShowThreshold = 2; // 2回の操作ごとに表示

  // テスト広告ID
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // 本番広告ID（後で実際のIDに置き換える）
  static const String _prodBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _prodInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _prodRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// 広告サービスを初期化
  void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;
    debugPrint('AdService初期化完了');
  }

  /// トラッキング許可状況を更新
  void updateTrackingStatus(TrackingStatus status) {
    _isTrackingAuthorized = status == TrackingStatus.authorized;
    debugPrint('トラッキング許可状況: $_isTrackingAuthorized');
  }

  /// 広告IDを取得
  String get _bannerAdUnitId {
    if (kDebugMode) return _testBannerAdUnitId;

    if (Platform.isAndroid) {
      return _prodBannerAdUnitId;
    } else if (Platform.isIOS) {
      return _prodBannerAdUnitId;
    }
    return _testBannerAdUnitId;
  }

  String get _interstitialAdUnitId {
    if (kDebugMode) return _testInterstitialAdUnitId;

    if (Platform.isAndroid) {
      return _prodInterstitialAdUnitId;
    } else if (Platform.isIOS) {
      return _prodInterstitialAdUnitId;
    }
    return _testInterstitialAdUnitId;
  }

  String get _rewardedAdUnitId {
    if (kDebugMode) return _testRewardedAdUnitId;

    if (Platform.isAndroid) {
      return _prodRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return _prodRewardedAdUnitId;
    }
    return _testRewardedAdUnitId;
  }

  /// バナー広告を作成
  Future<BannerAd?> createBannerAd({
    AdSize adSize = AdSize.banner,
    required Function(Ad ad) onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
  }) async {
    if (!_isInitialized) {
      debugPrint('AdServiceが初期化されていません');
      return null;
    }

    _bannerAd?.dispose();

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: adSize,
      request: _createAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('バナー広告の読み込み完了');
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('バナー広告の読み込み失敗: $error');
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
        onAdOpened: (ad) {
          debugPrint('バナー広告がタップされました');
        },
        onAdClosed: (ad) {
          debugPrint('バナー広告が閉じられました');
        },
      ),
    );

    await _bannerAd!.load();
    return _bannerAd;
  }

  /// インタースティシャル広告を読み込み
  Future<void> loadInterstitialAd({
    Function? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!_isInitialized) return;

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: _createAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('インタースティシャル広告の読み込み完了');
          onAdLoaded?.call();

          _setInterstitialCallbacks();
        },
        onAdFailedToLoad: (error) {
          debugPrint('インタースティシャル広告の読み込み失敗: $error');
          _interstitialAd = null;
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }

  /// インタースティシャル広告を表示
  Future<void> showInterstitialAd({bool forceShow = false}) async {
    if (_interstitialAd == null) {
      debugPrint('インタースティシャル広告が準備されていません');
      // 次回に備えて読み込み開始
      await loadInterstitialAd();
      return;
    }

    // 表示頻度制御
    if (!forceShow && !_shouldShowInterstitial()) {
      debugPrint('インタースティシャル広告の表示をスキップ（頻度制御）');
      return;
    }

    try {
      await _interstitialAd!.show();
      _lastInterstitialShow = DateTime.now();
      _interstitialShowCount = 0;
    } catch (e) {
      debugPrint('インタースティシャル広告の表示エラー: $e');
    }
  }

  /// リワード広告を読み込み
  Future<void> loadRewardedAd({
    Function? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!_isInitialized) return;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: _createAdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('リワード広告の読み込み完了');
          onAdLoaded?.call();

          _setRewardedCallbacks();
        },
        onAdFailedToLoad: (error) {
          debugPrint('リワード広告の読み込み失敗: $error');
          _rewardedAd = null;
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }

  /// リワード広告を表示
  Future<void> showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('リワード広告が準備されていません');
      return;
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('リワード獲得: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward);
        },
      );
    } catch (e) {
      debugPrint('リワード広告の表示エラー: $e');
    }
  }

  /// インタースティシャル広告を表示すべきかチェック
  bool _shouldShowInterstitial() {
    // 表示回数をチェック
    _interstitialShowCount++;
    if (_interstitialShowCount < _interstitialShowThreshold) {
      return false;
    }

    // 最後に表示してからの時間をチェック
    if (_lastInterstitialShow != null) {
      final timeSinceLastShow = DateTime.now().difference(
        _lastInterstitialShow!,
      );
      if (timeSinceLastShow.inMinutes < _interstitialCooldownMinutes) {
        return false;
      }
    }

    return true;
  }

  /// インタースティシャル広告のコールバックを設定
  void _setInterstitialCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('インタースティシャル広告が表示されました');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('インタースティシャル広告が閉じられました');
        ad.dispose();
        _interstitialAd = null;
        // 次の広告を事前読み込み
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('インタースティシャル広告の表示に失敗: $error');
        ad.dispose();
        _interstitialAd = null;
      },
    );
  }

  /// リワード広告のコールバックを設定
  void _setRewardedCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('リワード広告が表示されました');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('リワード広告が閉じられました');
        ad.dispose();
        _rewardedAd = null;
        // 次の広告を事前読み込み
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('リワード広告の表示に失敗: $error');
        ad.dispose();
        _rewardedAd = null;
      },
    );
  }

  /// 広告リクエストを作成
  AdRequest _createAdRequest() {
    return AdRequest(
      keywords: ['camera', 'photo', 'photography', 'grid'],
      nonPersonalizedAds: !_isTrackingAuthorized,
    );
  }

  /// アプリ再開時の処理
  void resumeAds() {
    debugPrint('広告の再開処理');
    // 必要に応じて広告の再読み込みなど
  }

  /// アプリ一時停止時の処理
  void pauseAds() {
    debugPrint('広告の一時停止処理');
  }

  /// リソースの解放
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();

    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;

    debugPrint('AdServiceのリソースを解放しました');
  }

  /// デバッグ情報を出力
  void debugPrintStatus() {
    debugPrint('=== AdService Status ===');
    debugPrint('初期化状態: $_isInitialized');
    debugPrint('トラッキング許可: $_isTrackingAuthorized');
    debugPrint('バナー広告: ${_bannerAd != null ? '読み込み済み' : '未読み込み'}');
    debugPrint('インタースティシャル: ${_interstitialAd != null ? '読み込み済み' : '未読み込み'}');
    debugPrint('リワード広告: ${_rewardedAd != null ? '読み込み済み' : '未読み込み'}');
    debugPrint('======================');
  }
}
