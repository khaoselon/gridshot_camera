import 'package:flutter/material.dart';
import 'package:gridshot_camera/models/grid_style.dart';
import 'package:gridshot_camera/services/settings_service.dart';

class GridPreviewWidget extends StatefulWidget {
  final GridStyle gridStyle;
  final double size;
  final int? highlightIndex;
  final bool showBorders;
  final Color? borderColor;
  final double? borderWidth;

  const GridPreviewWidget({
    super.key,
    required this.gridStyle,
    required this.size,
    this.highlightIndex,
    this.showBorders = true,
    this.borderColor,
    this.borderWidth,
  });

  @override
  State<GridPreviewWidget> createState() => _GridPreviewWidgetState();
}

class _GridPreviewWidgetState extends State<GridPreviewWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.highlightIndex != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GridPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.highlightIndex != widget.highlightIndex) {
      if (widget.highlightIndex != null) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = SettingsService.instance.currentSettings;

    final borderColor =
        widget.borderColor ??
        (widget.showBorders ? settings.borderColor : Colors.transparent);
    final borderWidth =
        widget.borderWidth ?? (widget.showBorders ? settings.borderWidth : 0.0);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.gridStyle.columns,
          childAspectRatio: 1.0,
          crossAxisSpacing: borderWidth,
          mainAxisSpacing: borderWidth,
        ),
        itemCount: widget.gridStyle.totalCells,
        itemBuilder: (context, index) {
          final isHighlighted = widget.highlightIndex == index;
          final position = widget.gridStyle.getPosition(index);

          Widget cell = Container(
            decoration: BoxDecoration(
              color: isHighlighted
                  ? theme.primaryColor.withOpacity(0.3)
                  : theme.cardColor,
              border: borderWidth > 0
                  ? Border.all(color: borderColor, width: borderWidth)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCellIcon(index),
                    size: widget.size / (widget.gridStyle.totalCells + 2),
                    color: isHighlighted
                        ? theme.primaryColor
                        : theme.iconTheme.color?.withOpacity(0.6),
                  ),
                  if (widget.size > 80) // サイズが十分大きい場合のみ表示
                    Text(
                      position.displayString,
                      style: TextStyle(
                        fontSize: widget.size / 15,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted
                            ? theme.primaryColor
                            : theme.textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ),
          );

          // ハイライト表示がある場合はアニメーション付きにする
          if (isHighlighted) {
            cell = AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: cell,
            );
          }

          return cell;
        },
      ),
    );
  }

  IconData _getCellIcon(int index) {
    // セルの位置に基づいてアイコンを決定
    switch (index % 4) {
      case 0:
        return Icons.photo_camera;
      case 1:
        return Icons.image;
      case 2:
        return Icons.crop_square;
      case 3:
        return Icons.grid_view;
      default:
        return Icons.crop_square;
    }
  }
}

// グリッドオーバーレイ（カメラ画面で使用）
class GridOverlay extends StatelessWidget {
  final GridStyle gridStyle;
  final Size size;
  final int? currentIndex;
  final Color borderColor;
  final double borderWidth;
  final bool showCellNumbers;

  const GridOverlay({
    super.key,
    required this.gridStyle,
    required this.size,
    this.currentIndex,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.showCellNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: GridPainter(
          gridStyle: gridStyle,
          currentIndex: currentIndex,
          borderColor: borderColor,
          borderWidth: borderWidth,
          showCellNumbers: showCellNumbers,
          textColor: Colors.white,
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final GridStyle gridStyle;
  final int? currentIndex;
  final Color borderColor;
  final double borderWidth;
  final bool showCellNumbers;
  final Color textColor;

  GridPainter({
    required this.gridStyle,
    this.currentIndex,
    required this.borderColor,
    required this.borderWidth,
    required this.showCellNumbers,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final cellWidth = size.width / gridStyle.columns;
    final cellHeight = size.height / gridStyle.rows;

    // グリッド線を描画
    for (int i = 1; i < gridStyle.columns; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 1; i < gridStyle.rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 外枠を描画
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 現在のセルをハイライト
    if (currentIndex != null) {
      final position = gridStyle.getPosition(currentIndex!);
      final rect = Rect.fromLTWH(
        position.col * cellWidth,
        position.row * cellHeight,
        cellWidth,
        cellHeight,
      );
      canvas.drawRect(rect, highlightPaint);
    }

    // セル番号を描画
    if (showCellNumbers) {
      final textPainter = TextPainter(textDirection: TextDirection.ltr);

      for (int i = 0; i < gridStyle.totalCells; i++) {
        final position = gridStyle.getPosition(i);
        final centerX = (position.col + 0.5) * cellWidth;
        final centerY = (position.row + 0.5) * cellHeight;

        textPainter.text = TextSpan(
          text: position.displayString,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            centerX - textPainter.width / 2,
            centerY - textPainter.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! GridPainter ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.gridStyle != gridStyle ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}
