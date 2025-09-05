import 'package:flutter/material.dart';
import 'package:gridshot_camera/models/grid_style.dart';
import 'package:gridshot_camera/models/shooting_mode.dart';
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

// グリッドオーバーレイ（カメラ画面で使用）- モード対応版
class GridOverlay extends StatelessWidget {
  final GridStyle gridStyle;
  final Size size;
  final int? currentIndex;
  final Color borderColor;
  final double borderWidth;
  final bool showCellNumbers;
  final ShootingMode? shootingMode; // 追加：撮影モード

  const GridOverlay({
    super.key,
    required this.gridStyle,
    required this.size,
    this.currentIndex,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.showCellNumbers = true,
    this.shootingMode, // 撮影モード
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
          shootingMode: shootingMode,
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
  final ShootingMode? shootingMode;

  GridPainter({
    required this.gridStyle,
    this.currentIndex,
    required this.borderColor,
    required this.borderWidth,
    required this.showCellNumbers,
    required this.textColor,
    this.shootingMode,
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

    // モードに応じた描画処理
    if (shootingMode == ShootingMode.impossible) {
      _drawImpossibleModeGrid(
        canvas,
        size,
        paint,
        highlightPaint,
        cellWidth,
        cellHeight,
      );
    } else {
      _drawCatalogModeGrid(
        canvas,
        size,
        paint,
        highlightPaint,
        cellWidth,
        cellHeight,
      );
    }
  }

  void _drawCatalogModeGrid(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint highlightPaint,
    double cellWidth,
    double cellHeight,
  ) {
    // カタログモード：通常のグリッド表示

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
      _drawCellNumbers(canvas, cellWidth, cellHeight, 'カタログ');
    }
  }

  void _drawImpossibleModeGrid(
    Canvas canvas,
    Size size,
    Paint paint,
    Paint highlightPaint,
    double cellWidth,
    double cellHeight,
  ) {
    // 不可能合成モード：現在撮影中のセルのみを強調表示

    // 全体のグリッド線を薄く描画
    final dimPaint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..strokeWidth = borderWidth * 0.5
      ..style = PaintingStyle.stroke;

    // グリッド線を描画（薄く）
    for (int i = 1; i < gridStyle.columns; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), dimPaint);
    }

    for (int i = 1; i < gridStyle.rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), dimPaint);
    }

    // 外枠を描画（薄く）
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(outerRect, dimPaint);

    // 現在のセルのみを強調表示
    if (currentIndex != null) {
      final position = gridStyle.getPosition(currentIndex!);
      final rect = Rect.fromLTWH(
        position.col * cellWidth,
        position.row * cellHeight,
        cellWidth,
        cellHeight,
      );

      // ハイライト背景
      canvas.drawRect(rect, highlightPaint);

      // 現在のセルの境界線を太く明るく描画
      final currentCellPaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth * 3
        ..style = PaintingStyle.stroke;
      canvas.drawRect(rect, currentCellPaint);

      // 撮影エリアの説明テキスト
      _drawShootingInstructions(canvas, rect, position);
    }

    // 完了したセルを薄く表示
    _drawCompletedCells(canvas, cellWidth, cellHeight);

    // セル番号を描画（現在のセルのみ強調）
    if (showCellNumbers) {
      _drawCellNumbers(canvas, cellWidth, cellHeight, '不可能合成');
    }
  }

  void _drawShootingInstructions(
    Canvas canvas,
    Rect rect,
    GridPosition position,
  ) {
    // 撮影中のセルに指示テキストを表示
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: '${position.displayString}エリア\nを撮影',
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.8),
          ),
        ],
      ),
    );

    textPainter.layout();

    final centerX = rect.center.dx;
    final centerY = rect.center.dy;

    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2),
    );
  }

  void _drawCompletedCells(Canvas canvas, double cellWidth, double cellHeight) {
    // 完了したセルを薄く表示（実装簡略化）
    // 実際のプロダクションでは、ShootingSessionの状態を受け取って描画
  }

  void _drawCellNumbers(
    Canvas canvas,
    double cellWidth,
    double cellHeight,
    String mode,
  ) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final fontSize = (cellWidth + cellHeight) / 12;

    for (int i = 0; i < gridStyle.totalCells; i++) {
      final position = gridStyle.getPosition(i);
      final centerX = (position.col + 0.5) * cellWidth;
      final centerY = (position.row + 0.5) * cellHeight;
      final isCurrentCell = currentIndex == i;

      // 不可能合成モードでは現在のセル以外は薄く表示
      final opacity = (mode == '不可能合成' && !isCurrentCell) ? 0.4 : 1.0;

      textPainter.text = TextSpan(
        text: position.displayString,
        style: TextStyle(
          color: textColor.withOpacity(opacity),
          fontSize: fontSize.clamp(12.0, 20.0),
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
          width: textPainter.width + 12,
          height: textPainter.height + 8,
        );
        final bgPaint = Paint()
          ..color = borderColor.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(textRect, const Radius.circular(6)),
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! GridPainter ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.gridStyle != gridStyle ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.shootingMode != shootingMode;
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
