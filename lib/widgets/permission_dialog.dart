import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool shouldOpenSettings;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.shouldOpenSettings,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (shouldOpenSettings)
          TextButton(
            onPressed: () async {
              await openAppSettings(); // ダイアログは閉じない（呼び出し側でpop）
            },
            child: const Text('設定を開く'),
          ),
        TextButton(
          onPressed: onCancel, // 呼び出し側でpop
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: onRetry, // 呼び出し側でpop→再試行
          child: const Text('再試行'),
        ),
      ],
    );
  }
}
