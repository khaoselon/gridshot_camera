import 'package:flutter/material.dart';
import 'package:gridshot_camera/models/shooting_mode.dart';

class ModeSelectionCard extends StatefulWidget {
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
  State<ModeSelectionCard> createState() => _ModeSelectionCardState();
}

class _ModeSelectionCardState extends State<ModeSelectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: widget.isSelected ? 12 : 6,
          shadowColor: widget.isSelected
              ? colorScheme.primary.withOpacity(0.4)
              : theme.cardTheme.shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.isSelected
                ? BorderSide(color: colorScheme.primary, width: 2.5)
                : BorderSide.none,
          ),
          color: widget.isSelected
              ? colorScheme.primary.withOpacity(0.08)
              : theme.cardColor,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _animationController.forward().then((_) {
                  _animationController.reverse();
                });
                widget.onTap();
              },
              onTapDown: (_) => _animationController.forward(),
              onTapCancel: () => _animationController.reverse(),
              borderRadius: BorderRadius.circular(16),
              splashColor: colorScheme.primary.withOpacity(0.1),
              highlightColor: colorScheme.primary.withOpacity(0.05),
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // アイコンセクション
                    _buildIconSection(theme, colorScheme),

                    const SizedBox(width: 20),

                    // テキスト情報
                    Expanded(child: _buildTextSection(theme, colorScheme)),

                    // 選択インジケーター
                    if (widget.isSelected)
                      _buildSelectionIndicator(colorScheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: widget.isSelected
            ? LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.15),
                  colorScheme.primary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Icon(
        widget.icon,
        size: 36,
        color: widget.isSelected ? Colors.white : colorScheme.primary,
      ),
    );
  }

  Widget _buildTextSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: widget.isSelected
                ? colorScheme.primary
                : colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.4,
            color: widget.isSelected
                ? colorScheme.onSurface.withOpacity(0.8)
                : colorScheme.onSurface.withOpacity(0.7),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionIndicator(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: const Icon(Icons.check, color: Colors.white, size: 20),
    );
  }
}

// 追加：モード選択セクション用のヘルパーウィジェット
class ModeSelectionSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ModeSelectionSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: theme.colorScheme.onBackground,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}
