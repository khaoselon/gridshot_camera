import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;
  final double? progress;
  final bool showProgress;
  final Color? color;
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.progress,
    this.showProgress = false,
    this.color,
    this.size = 50.0,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loadingColor = widget.color ?? theme.primaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ローディングインジケーター
          if (widget.showProgress && widget.progress != null)
            _buildProgressIndicator(loadingColor)
          else
            _buildAnimatedIndicator(loadingColor),

          if (widget.message != null) ...[
            const SizedBox(height: 24),
            // メッセージ
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Text(
                    widget.message!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(Color color) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景の円
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.2)),
            ),
          ),
          // プログレスの円
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: widget.progress,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          // パーセンテージ表示
          if (widget.progress != null)
            Text(
              '${(widget.progress! * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIndicator(Color color) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2.0 * 3.14159,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: LoadingPainter(
                      color: color,
                      progress: _rotationAnimation.value,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class LoadingPainter extends CustomPainter {
  final Color color;
  final double progress;

  LoadingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // 複数の円弧を描画してアニメーション効果を作成
    for (int i = 0; i < 3; i++) {
      final startAngle = (progress * 2 * 3.14159) + (i * 2 * 3.14159 / 3);
      final sweepAngle = 3.14159 / 3; // 60度

      paint.color = color.withOpacity(1.0 - (i * 0.3));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (i * 4)),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! LoadingPainter ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}

// 特定の用途向けのローディングウィジェット
class CameraLoadingWidget extends StatelessWidget {
  final String message;

  const CameraLoadingWidget({super.key, this.message = 'カメラを準備中...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: LoadingWidget(message: message, color: Colors.white, size: 60),
    );
  }
}

class CompositeLoadingWidget extends StatelessWidget {
  final double? progress;
  final String message;

  const CompositeLoadingWidget({
    super.key,
    this.progress,
    this.message = '画像を合成中...',
  });

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      message: message,
      progress: progress,
      showProgress: progress != null,
      size: 80,
    );
  }
}

// オーバーレイ表示用のローディング
class LoadingOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    String? message,
    double? progress,
    bool showProgress = false,
  }) {
    hide(); // 既存のオーバーレイを削除

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black.withOpacity(0.7),
        child: LoadingWidget(
          message: message,
          progress: progress,
          showProgress: showProgress,
          color: Colors.white,
          size: 60,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void updateProgress(double progress, {String? message}) {
    // プログレス更新は実装を簡略化
    // 実際のプロダクションではStateやChangeNotifierを使用
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// ボタン内のローディング表示
class ButtonLoadingWidget extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? loadingColor;
  final double size;

  const ButtonLoadingWidget({
    super.key,
    required this.isLoading,
    required this.child,
    this.loadingColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            loadingColor ?? Colors.white,
          ),
        ),
      );
    } else {
      return child;
    }
  }
}
