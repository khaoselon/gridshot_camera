import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:gridshot_camera/services/settings_service.dart';
import 'package:gridshot_camera/models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: SettingsService.instance,
      builder: (context, _) {
        final settings = SettingsService.instance.currentSettings;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settingsTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _showResetDialog,
                tooltip: '設定をリセット',
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                // 言語設定セクション
                _buildSectionCard(
                  title: l10n.language,
                  icon: Icons.language,
                  children: [
                    ListTile(
                      title: Text(l10n.language),
                      subtitle: Text(
                        _getLanguageDisplayName(settings.languageCode),
                      ),
                      trailing: DropdownButton<String>(
                        value: settings.languageCode,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(
                            value: 'ja',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇯🇵'),
                                const SizedBox(width: 8),
                                Text(l10n.japanese),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🇺🇸'),
                                const SizedBox(width: 8),
                                Text(l10n.english),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value != null) {
                            await SettingsService.instance.updateLanguage(
                              value,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // グリッド表示設定セクション
                _buildSectionCard(
                  title: l10n.gridBorder,
                  icon: Icons.grid_on,
                  children: [
                    SwitchListTile(
                      title: Text(l10n.gridBorder),
                      subtitle: const Text('撮影時にグリッド線を表示します'),
                      value: settings.showGridBorder,
                      onChanged: (value) {
                        SettingsService.instance.updateGridBorderDisplay(value);
                      },
                    ),

                    if (settings.showGridBorder) ...[
                      const Divider(),

                      // 境界線の色設定
                      ListTile(
                        title: Text(l10n.borderColor),
                        subtitle: Text(
                          '現在の色: ${_getColorName(settings.borderColor)}',
                        ),
                        trailing: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: settings.borderColor,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onTap: () => _showColorPicker(context),
                      ),

                      // 境界線の太さ設定
                      ListTile(
                        title: Text(l10n.borderWidth),
                        subtitle: Text(
                          '${settings.borderWidth.toStringAsFixed(1)}px',
                        ),
                      ),
                      Slider(
                        value: settings.borderWidth,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        label: '${settings.borderWidth.toStringAsFixed(1)}px',
                        onChanged: (value) {
                          SettingsService.instance.updateBorderWidth(value);
                        },
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // 画像品質設定セクション
                _buildSectionCard(
                  title: l10n.imageQuality,
                  icon: Icons.photo_size_select_actual,
                  children: [
                    ListTile(
                      title: Text(l10n.imageQuality),
                      subtitle: Text(
                        _getQualityDisplayName(l10n, settings.imageQuality),
                      ),
                    ),
                    ...ImageQuality.values.map((quality) {
                      return RadioListTile<ImageQuality>(
                        title: Text(_getQualityDisplayName(l10n, quality)),
                        subtitle: Text(_getQualityDescription(quality)),
                        value: quality,
                        groupValue: settings.imageQuality,
                        onChanged: (value) {
                          if (value != null) {
                            SettingsService.instance.updateImageQuality(value);
                          }
                        },
                      );
                    }).toList(),
                  ],
                ),

                const SizedBox(height: 16),

                // 広告設定セクション
                _buildSectionCard(
                  title: l10n.adSettings,
                  icon: Icons.ads_click,
                  children: [
                    SwitchListTile(
                      title: Text(l10n.showAds),
                      subtitle: const Text('広告を表示してアプリの開発を支援する'),
                      value: settings.showAds,
                      onChanged: (value) {
                        SettingsService.instance.updateAdDisplay(value);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // アプリ情報セクション
                _buildSectionCard(
                  title: 'アプリ情報',
                  icon: Icons.info,
                  children: [
                    ListTile(
                      title: const Text('バージョン'),
                      subtitle: const Text('1.0.0'),
                      trailing: const Icon(Icons.info_outline),
                    ),
                    ListTile(
                      title: const Text('開発者'),
                      subtitle: const Text('GridShot Camera Team'),
                      trailing: const Icon(Icons.people),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('境界線の色を選択'),
        content: SizedBox(width: 300, height: 400, child: _buildColorPicker()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    // 拡張されたカラーパレット
    final colors = [
      // 基本色
      Colors.white,
      Colors.black,
      Colors.grey,

      // 暖色系
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.amber,

      // 寒色系
      Colors.blue,
      Colors.cyan,
      Colors.lightBlue,
      Colors.indigo,

      // 自然色
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.teal,

      // その他
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.deepOrange,

      // 明るいバリエーション
      Colors.red[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.purple[300]!,

      // 暗いバリエーション
      Colors.red[700]!,
      Colors.blue[700]!,
      Colors.green[700]!,
      Colors.purple[700]!,
    ];

    final currentColor = SettingsService.instance.currentSettings.borderColor;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = color.value == currentColor.value;

        return GestureDetector(
          onTap: () {
            SettingsService.instance.updateBorderColor(color);
            Navigator.of(context).pop();
          },
          child: Container(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
        );
      },
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定をリセット'),
        content: const Text('すべての設定を初期値に戻しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SettingsService.instance.resetSettings();
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('設定がリセットされました')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('リセット', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return '日本語';
      case 'en':
        return 'English';
      default:
        return languageCode;
    }
  }

  String _getColorName(Color color) {
    if (color == Colors.white) return '白';
    if (color == Colors.black) return '黒';
    if (color == Colors.red) return '赤';
    if (color == Colors.blue) return '青';
    if (color == Colors.green) return '緑';
    if (color == Colors.yellow) return '黄';
    if (color == Colors.orange) return 'オレンジ';
    if (color == Colors.purple) return '紫';
    if (color == Colors.pink) return 'ピンク';
    if (color == Colors.cyan) return 'シアン';
    if (color == Colors.grey) return 'グレー';
    if (color == const Color(0xFFFF00FF)) return 'マゼンタ';
    return 'カスタム';
  }

  String _getQualityDisplayName(AppLocalizations l10n, ImageQuality quality) {
    switch (quality) {
      case ImageQuality.high:
        return l10n.high;
      case ImageQuality.medium:
        return l10n.medium;
      case ImageQuality.low:
        return l10n.low;
    }
  }

  String _getQualityDescription(ImageQuality quality) {
    switch (quality) {
      case ImageQuality.high:
        return '最高品質 (95%) - ファイルサイズ大';
      case ImageQuality.medium:
        return '中品質 (75%) - バランス良好';
      case ImageQuality.low:
        return '低品質 (50%) - ファイルサイズ小';
    }
  }
}
