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

    // グリッドの縦横比を計算（正方形に近づける）
    final cellAspectRatio = widget.gridStyle.columns / widget.gridStyle.rows;
    final containerHeight = widget.size / cellAspectRatio;

    return Container(
      width: widget.size,
      height: containerHeight,
      constraints: BoxConstraints(
        maxHeight: widget.size * 1.5, // 最大高さを制限
        minHeight: widget.size * 0.5, // 最小高さを設定
      ),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true, // 重要: 内容に合わせてサイズを調整
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.gridStyle.columns, // 列数
            childAspectRatio: 1.0, // セルを正方形に
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
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCellIcon(index),
                      size: _getIconSize(),
                      color: isHighlighted
                          ? theme.primaryColor
                          : theme.iconTheme.color?.withOpacity(0.6),
                    ),
                    if (widget.size > 80) ...[
                      const SizedBox(height: 2),
                      Text(
                        position.displayString,
                        style: TextStyle(
                          fontSize: _getTextSize(),
                          fontWeight: FontWeight.bold,
                          color: isHighlighted
                              ? theme.primaryColor
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.3),
                            blurRadius: 8 * _pulseAnimation.value,
                            spreadRadius: 2 * _pulseAnimation.value,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: cell,
              );
            }

            return cell;
          },
        ),
      ),
    );
  }

  double _getIconSize() {
    // グリッドサイズに応じてアイコンサイズを調整
    final cellSize =
        widget.size /
        (widget.gridStyle.columns > widget.gridStyle.rows
            ? widget.gridStyle.columns
            : widget.gridStyle.rows);
    final baseSize = cellSize / 3;
    return baseSize.clamp(12.0, 24.0);
  }

  double _getTextSize() {
    // グリッドサイズに応じてテキストサイズを調整
    final cellSize =
        widget.size /
        (widget.gridStyle.columns > widget.gridStyle.rows
            ? widget.gridStyle.columns
            : widget.gridStyle.rows);
    return (cellSize / 8).clamp(8.0, 12.0);
  }

  IconData _getCellIcon(int index) {
    // セルの位置に基づいてアイコンを決定
    switch (index % 6) {
      case 0:
        return Icons.photo_camera;
      case 1:
        return Icons.image;
      case 2:
        return Icons.crop_square;
      case 3:
        return Icons.grid_view;
      case 4:
        return Icons.photo;
      case 5:
        return Icons.camera_alt;
      default:
        return Icons.crop_square;
    }
  }
}

// グリッドオーバーレイ（カメラ画面で使用）- 改善版
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
    if (borderWidth <= 0) return;

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = borderColor.withOpacity(0.2)
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
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(outerRect, paint);

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

      // 現在のセルの境界線を太くする
      final thickPaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth * 2
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect, thickPaint);
    }

    // セル番号を描画
    if (showCellNumbers) {
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      final fontSize = (cellWidth + cellHeight) / 10;

      for (int i = 0; i < gridStyle.totalCells; i++) {
        final position = gridStyle.getPosition(i);
        final centerX = (position.col + 0.5) * cellWidth;
        final centerY = (position.row + 0.5) * cellHeight;
        final isCurrentCell = currentIndex == i;

        textPainter.text = TextSpan(
          text: position.displayString,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize.clamp(14.0, 24.0),
            fontWeight: isCurrentCell ? FontWeight.bold : FontWeight.w600,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.8),
              ),
              Shadow(
                offset: const Offset(-1, -1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.8),
              ),
            ],
          ),
        );

        textPainter.layout();

        // 現在のセルの場合は背景を追加
        if (isCurrentCell) {
          final textRect = Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: textPainter.width + 8,
            height: textPainter.height + 4,
          );
          final bgPaint = Paint()
            ..color = borderColor.withOpacity(0.3)
            ..style = PaintingStyle.fill;
          canvas.drawRRect(
            RRect.fromRectAndRadius(textRect, const Radius.circular(4)),
            bgPaint,
          );
        }

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

// グリッドスタイル表示用のコンパクトウィジェット
class GridStyleIndicator extends StatelessWidget {
  final GridStyle gridStyle;
  final double size;
  final Color? color;
  final bool isSelected;

  const GridStyleIndicator({
    super.key,
    required this.gridStyle,
    this.size = 32,
    this.color,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor =
        color ??
        (isSelected ? theme.colorScheme.primary : theme.iconTheme.color);

    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: GridStylePainter(
          gridStyle: gridStyle,
          color: indicatorColor ?? Colors.grey,
        ),
      ),
    );
  }
}

class GridStylePainter extends CustomPainter {
  final GridStyle gridStyle;
  final Color color;

  GridStylePainter({required this.gridStyle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final cellWidth = size.width / gridStyle.columns;
    final cellHeight = size.height / gridStyle.rows;

    // 垂直線を描画
    for (int i = 0; i <= gridStyle.columns; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 水平線を描画
    for (int i = 0; i <= gridStyle.rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! GridStylePainter ||
        oldDelegate.gridStyle != gridStyle ||
        oldDelegate.color != color;
  }
}
