import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../l10n/app_localizations.dart';
import 'package:gridshot_camera/models/shooting_mode.dart';
import 'package:gridshot_camera/services/image_composer_service.dart';
import 'package:gridshot_camera/services/ad_service.dart';
import 'package:gridshot_camera/services/settings_service.dart';
import 'package:gridshot_camera/widgets/loading_widget.dart';
import 'package:gridshot_camera/screens/camera_screen.dart';

class PreviewScreen extends StatefulWidget {
  final ShootingSession session;

  const PreviewScreen({super.key, required this.session});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with TickerProviderStateMixin {
  String? _compositeImagePath;
  String? _errorMessage;
  bool _isCompositing = false;
  bool _isSaving = false;
  bool _isSharing = false;

  // アニメーション関連
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // 広告関連
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startCompositing();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
  }

  Future<void> _startCompositing() async {
    setState(() {
      _isCompositing = true;
      _errorMessage = null;
    });

    try {
      final result = await ImageComposerService.instance.composeGridImage(
        session: widget.session,
      );

      if (result.success && result.filePath != null && mounted) {
        setState(() {
          _compositeImagePath = result.filePath;
          _isCompositing = false;
        });

        // 合成完了のアニメーション
        _scaleController.forward();

        // 一時ファイルのクリーンアップを少し遅らせる
        Future.delayed(const Duration(seconds: 2), () {
          ImageComposerService.instance.cleanupTemporaryFiles(widget.session);
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = result.message;
          _isCompositing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '画像の合成中にエラーが発生しました: $e';
          _isCompositing = false;
        });
      }
    }
  }

  void _loadBannerAd() {
    if (!SettingsService.instance.shouldShowAds) return;

    AdService.instance.createBannerAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerAdReady = true;
          });
        }
      },
      onAdFailedToLoad: (ad, error) {
        if (mounted) {
          setState(() {
            _isBannerAdReady = false;
          });
        }
      },
    );
  }

  Future<void> _saveImage() async {
    if (_compositeImagePath == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final l10n = AppLocalizations.of(context)!;

      // 保存処理は既にImageComposerServiceで実行済み（ギャラリー保存も含む）
      // ここでは成功メッセージの表示のみ
      _showSuccessMessage(l10n.saveSuccess);

      // ハプティックフィードバック
      HapticFeedback.lightImpact();
    } catch (e) {
      _showErrorMessage('画像の保存に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _shareImage() async {
    if (_compositeImagePath == null || _isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final l10n = AppLocalizations.of(context)!;

      await Share.shareXFiles(
        [XFile(_compositeImagePath!)],
        text: '${l10n.appTitle}で作成したグリッド写真',
        subject: l10n.appTitle,
      );

      _showSuccessMessage(l10n.shareSuccess);
    } catch (e) {
      _showErrorMessage('画像の共有に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _retakePhoto() async {
    // 確認ダイアログ
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('確認'),
        content: Text('撮影をやり直しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('撮り直し'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // カメラ画面に戻る
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            mode: widget.session.mode,
            gridStyle: widget.session.gridStyle,
          ),
        ),
      );
    }
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.previewTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goHome,
        ),
        actions: [
          if (!_isCompositing && _compositeImagePath != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retakePhoto,
              tooltip: l10n.retake,
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Expanded(child: _buildContent(context, l10n, theme)),
            if (_isBannerAdReady &&
                _bannerAd != null &&
                SettingsService.instance.shouldShowAds)
              _buildBannerAd(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isCompositing) {
      return _buildCompositingView(l10n);
    }

    if (_errorMessage != null) {
      return _buildErrorView(l10n);
    }

    if (_compositeImagePath != null) {
      return _buildPreviewView(l10n, theme);
    }

    return Container(); // 不明な状態
  }

  Widget _buildCompositingView(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // プレビューグリッド（撮影した画像の小さいプレビュー）
        _buildShootingPreview(),

        const SizedBox(height: 48),

        // ローディングインジケーター
        const CircularProgressIndicator(strokeWidth: 3),

        const SizedBox(height: 24),

        Text(
          l10n.compositing,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        Text(
          '${widget.session.gridStyle.totalCells}枚の画像を合成中...',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildShootingPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.session.gridStyle.columns,
              childAspectRatio: 1.0,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: widget.session.gridStyle.totalCells,
            itemBuilder: (context, index) {
              final capturedImage = widget.session.capturedImages[index];

              if (capturedImage != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(capturedImage.filePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      );
                    },
                  ),
                );
              } else {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.image, color: Colors.grey[400]),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.error,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _startCompositing, child: Text('再試行')),
            const SizedBox(height: 12),
            TextButton(onPressed: _retakePhoto, child: Text('撮り直し')),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewView(AppLocalizations l10n, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 合成画像の表示
          ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              elevation: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.file(
                    File(_compositeImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '画像の読み込みに失敗しました',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 撮影情報
          _buildImageInfo(l10n, theme),

          const SizedBox(height: 32),

          // アクションボタン
          _buildActionButtons(l10n),
        ],
      ),
    );
  }

  Widget _buildImageInfo(AppLocalizations l10n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '撮影情報',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('モード', _getModeDisplayName()),
            _buildInfoRow('グリッドスタイル', widget.session.gridStyle.displayName),
            _buildInfoRow('撮影枚数', '${widget.session.completedCount}枚'),
            _buildInfoRow('撮影日時', _formatDateTime(DateTime.now())),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 保存ボタン
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveImage,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save_alt),
          label: Text(
            _isSaving ? '保存中...' : l10n.save,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 12),

        // 共有ボタン
        OutlinedButton.icon(
          onPressed: _isSharing ? null : _shareImage,
          icon: _isSharing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.share),
          label: Text(
            _isSharing ? '共有中...' : l10n.share,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),

        const SizedBox(height: 12),

        // 撮り直しボタン
        TextButton.icon(
          onPressed: _retakePhoto,
          icon: const Icon(Icons.camera_alt),
          label: Text('新しく撮影する', style: const TextStyle(fontSize: 16)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerAd() {
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  String _getModeDisplayName() {
    switch (widget.session.mode) {
      case ShootingMode.catalog:
        return 'カタログモード';
      case ShootingMode.impossible:
        return '不可能合成モード';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
