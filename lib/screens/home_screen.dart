import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../l10n/app_localizations.dart';
import 'package:gridshot_camera/models/grid_style.dart';
import 'package:gridshot_camera/models/shooting_mode.dart';
import 'package:gridshot_camera/screens/camera_screen.dart';
import 'package:gridshot_camera/screens/settings_screen.dart';
import 'package:gridshot_camera/services/ad_service.dart';
import 'package:gridshot_camera/services/settings_service.dart' as svc;
import 'package:gridshot_camera/widgets/grid_preview_widget.dart';
import 'package:gridshot_camera/widgets/mode_selection_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  ShootingMode _selectedMode = ShootingMode.catalog;
  GridStyle _selectedGridStyle = GridStyle.grid2x2;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBannerAd();

    // インタースティシャル広告を事前読み込み
    AdService.instance.loadInterstitialAd();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  void _loadBannerAd() {
    // 広告表示設定がオンの場合のみ読み込み
    if (!svc.SettingsService.instance.shouldShowAds) return;

    AdService.instance.createBannerAd(
      onAdLoaded: (ad) {
        setState(() {
          _bannerAd = ad as BannerAd;
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        setState(() {
          _isBannerAdReady = false;
        });
      },
    );
  }

  void _onModeChanged(ShootingMode mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  void _onGridStyleChanged(GridStyle style) {
    setState(() {
      _selectedGridStyle = style;
    });
  }

  Future<void> _startShooting() async {
    // 撮影開始前にインタースティシャル広告を表示する場合
    // await AdService.instance.showInterstitialAd();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CameraScreen(mode: _selectedMode, gridStyle: _selectedGridStyle),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // タイトルセクション
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.grid_view,
                              size: 48,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.homeTitle,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // モード選択セクション
                    Text(
                      l10n.homeTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ModeSelectionCard(
                      mode: ShootingMode.catalog,
                      title: l10n.catalogMode,
                      description: l10n.catalogModeDescription,
                      icon: Icons.collections,
                      isSelected: _selectedMode == ShootingMode.catalog,
                      onTap: () => _onModeChanged(ShootingMode.catalog),
                    ),

                    const SizedBox(height: 12),

                    ModeSelectionCard(
                      mode: ShootingMode.impossible,
                      title: l10n.impossibleMode,
                      description: l10n.impossibleModeDescription,
                      icon: Icons.auto_fix_high,
                      isSelected: _selectedMode == ShootingMode.impossible,
                      onTap: () => _onModeChanged(ShootingMode.impossible),
                    ),

                    const SizedBox(height: 32),

                    // グリッドスタイル選択セクション
                    Text(
                      l10n.gridStyle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // グリッドプレビュー
                            GridPreviewWidget(
                              gridStyle: _selectedGridStyle,
                              size: 120,
                              highlightIndex: 0, // 最初のセルをハイライト
                            ),
                            const SizedBox(height: 16),

                            // グリッドスタイル選択ボタン（改善版）
                            _buildGridStyleSelector(l10n, theme),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 撮影開始ボタン
                    ElevatedButton.icon(
                      onPressed: _startShooting,
                      icon: const Icon(Icons.camera_alt, size: 24),
                      label: Text(
                        l10n.startShooting,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // バナー広告
            if (_isBannerAdReady &&
                _bannerAd != null &&
                svc.SettingsService.instance.shouldShowAds)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  // 改善されたグリッドスタイルセレクター
  Widget _buildGridStyleSelector(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '選択中: ${_getGridStyleLabel(l10n, _selectedGridStyle)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: GridStyle.values.length,
          itemBuilder: (context, index) {
            final style = GridStyle.values[index];
            final isSelected = _selectedGridStyle == style;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onGridStyleChanged(style),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? theme.primaryColor
                          : theme.dividerColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? theme.primaryColor.withOpacity(0.1)
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grid_view,
                          color: isSelected
                              ? theme.primaryColor
                              : theme.iconTheme.color?.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getGridStyleLabel(l10n, style),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.primaryColor
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getGridStyleLabel(AppLocalizations l10n, GridStyle style) {
    switch (style) {
      case GridStyle.grid2x2:
        return l10n.grid2x2;
      case GridStyle.grid2x3:
        return l10n.grid2x3;
      case GridStyle.grid3x2:
        return l10n.grid3x2;
      case GridStyle.grid3x3:
        return l10n.grid3x3;
    }
  }
}
