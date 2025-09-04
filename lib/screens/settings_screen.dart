// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:gridshot_camera/services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SettingsService.instance;

    return AnimatedBuilder(
      animation: service, // ChangeNotifier の更新を反映
      builder: (context, _) {
        final s = service.currentSettings;

        return Scaffold(
          appBar: AppBar(title: const Text('設定')),
          body: ListView(
            children: [
              const SizedBox(height: 12),

              // 言語
              ListTile(
                title: const Text('言語'),
                trailing: DropdownButton<String>(
                  value: s.languageCode,
                  items: const [
                    DropdownMenuItem(value: 'ja', child: Text('日本語')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) async {
                    if (v != null) {
                      await service.updateLanguage(v);
                    }
                  },
                ),
              ),

              const Divider(),

              // グリッド境界線の表示
              SwitchListTile(
                title: const Text('グリッド境界線を表示'),
                value: s.showGridBorder,
                onChanged: (val) => service.updateGridBorderDisplay(val),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
