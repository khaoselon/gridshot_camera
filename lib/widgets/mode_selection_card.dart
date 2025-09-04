import 'package:flutter/material.dart';
import 'package:gridshot_camera/models/shooting_mode.dart';

class ModeSelectionCard extends StatelessWidget {
  final ShootingMode mode;
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ModeSelectionCard({
    super.key,
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Card(
        elevation: isSelected ? 8 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: theme.primaryColor, width: 2)
              : BorderSide.none,
        ),
        color: isSelected ? theme.primaryColor.withOpacity(0.1) : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // アイコン
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.primaryColor
                        : theme.primaryColor.withOpacity(0.2),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: isSelected ? Colors.white : theme.primaryColor,
                  ),
                ),

                const SizedBox(width: 16),

                // テキスト情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? theme.primaryColor : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // 選択インジケーター
                if (isSelected)
                  Icon(Icons.check_circle, color: theme.primaryColor, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
