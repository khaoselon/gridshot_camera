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

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _fadeController.dispose();
    _slideController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: _openSettings,
            tooltip: l10n.settings,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 8),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ヒーローセクション
                      _buildHeroSection(theme, colorScheme, l10n),

                      const SizedBox(height: 32),

                      // モード選択セクション
                      _buildModeSelectionSection(theme, l10n),

                      const SizedBox(height: 32),

                      // グリッドスタイル選択セクション
                      _buildGridSelectionSection(theme, colorScheme, l10n),

                      const SizedBox(height: 40),

                      // 撮影開始ボタン
                      _buildStartButton(theme, colorScheme, l10n),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // バナー広告
              if (_isBannerAdReady &&
                  _bannerAd != null &&
                  svc.SettingsService.instance.shouldShowAds)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.homeTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '撮影したい写真のスタイルを選択してください',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelectionSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '撮影モード',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: theme.colorScheme.onBackground,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),

        ModeSelectionCard(
          mode: ShootingMode.catalog,
          title: l10n.catalogMode,
          description: l10n.catalogModeDescription,
          icon: Icons.collections_rounded,
          isSelected: _selectedMode == ShootingMode.catalog,
          onTap: () => _onModeChanged(ShootingMode.catalog),
        ),

        const SizedBox(height: 16),

        ModeSelectionCard(
          mode: ShootingMode.impossible,
          title: l10n.impossibleMode,
          description: l10n.impossibleModeDescription,
          icon: Icons.auto_fix_high_rounded,
          isSelected: _selectedMode == ShootingMode.impossible,
          onTap: () => _onModeChanged(ShootingMode.impossible),
        ),
      ],
    );
  }

  Widget _buildGridSelectionSection(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.gridStyle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),

          // グリッドプレビュー
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    colorScheme.secondary.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: GridPreviewWidget(
                gridStyle: _selectedGridStyle,
                size: 140,
                highlightIndex: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // グリッドスタイル選択ボタン
          _buildGridStyleSelector(l10n, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildGridStyleSelector(
    AppLocalizations l10n,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '選択中: ${_getGridStyleLabel(l10n, _selectedGridStyle)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: GridStyle.values.length,
          itemBuilder: (context, index) {
            final style = GridStyle.values[index];
            final isSelected = _selectedGridStyle == style;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onGridStyleChanged(style),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : colorScheme.surface,
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : colorScheme.outline.withOpacity(0.3),
                      width: isSelected ? 0 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          color: isSelected
                              ? Colors.white
                              : colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getGridStyleLabel(l10n, style),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : colorScheme.onSurface,
                            letterSpacing: 0.3,
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

  Widget _buildStartButton(
    ThemeData theme,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _startShooting,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(
          Icons.camera_alt_rounded,
          size: 28,
          color: Colors.white,
        ),
        label: Text(
          l10n.startShooting,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
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
