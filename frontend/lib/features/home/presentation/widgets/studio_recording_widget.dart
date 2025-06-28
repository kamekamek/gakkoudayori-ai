import 'package:flutter/material.dart';
import 'dart:math' as math;

/// プロ仕様のレコーディングスタジオ風UIウィジェット
class StudioRecordingWidget extends StatefulWidget {
  final double audioLevel;
  final bool isRecording;
  final VoidCallback? onToggleRecording;
  final Color? primaryColor;
  final Color? accentColor;

  const StudioRecordingWidget({
    super.key,
    required this.audioLevel,
    required this.isRecording,
    this.onToggleRecording,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<StudioRecordingWidget> createState() => _StudioRecordingWidgetState();
}

class _StudioRecordingWidgetState extends State<StudioRecordingWidget>
    with TickerProviderStateMixin {
  late AnimationController _levelMeterController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    _levelMeterController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    if (widget.isRecording) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(StudioRecordingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }

    if (widget.audioLevel != oldWidget.audioLevel) {
      _levelMeterController.animateTo(widget.audioLevel);
    }
  }

  void _startAnimations() {
    _pulseController.repeat();
    _rotationController.repeat();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _pulseController.reset();
    _rotationController.stop();
    _rotationController.reset();
  }

  @override
  void dispose() {
    _levelMeterController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.primaryColor ?? Theme.of(context).colorScheme.error;
    final accentColor =
        widget.accentColor ?? Theme.of(context).colorScheme.errorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // レコーディングボタン（vinyl record風）
          GestureDetector(
            onTap: widget.onToggleRecording,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: widget.isRecording
                      ? _rotationController.value * 2 * math.pi
                      : 0,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.black,
                          primaryColor.withOpacity(0.8),
                          Colors.black,
                        ],
                        stops: const [0.3, 0.6, 1.0],
                      ),
                      border: Border.all(
                        color: primaryColor,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // レコード盤の溝
                        ...List.generate(3, (index) {
                          final radius = 8.0 + (index * 4);
                          return Container(
                            width: radius,
                            height: radius,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                          );
                        }),
                        // 中央のドット
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor,
                          ),
                        ),
                        // 録音アイコン
                        Icon(
                          widget.isRecording
                              ? Icons.stop
                              : Icons.fiber_manual_record,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 16),

          // スタジオ級レベルメーター
          Expanded(
            child: Column(
              children: [
                // 上部の波形
                SizedBox(
                  height: 24,
                  child: AnimatedBuilder(
                    animation: _levelMeterController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: StudioWaveformPainter(
                          audioLevel: widget.audioLevel,
                          isRecording: widget.isRecording,
                          color: primaryColor,
                          animation: _pulseController,
                        ),
                        size: const Size(double.infinity, 24),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // レベルメーターバー
                Row(
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _levelMeterController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: widget.audioLevel,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getLevelColor(widget.audioLevel, primaryColor),
                            ),
                            minHeight: 4,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // dBレベル表示
                    Text(
                      '${(_audioLevelToDb(widget.audioLevel)).toStringAsFixed(1)}dB',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // ステータス表示
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRecording
                          ? primaryColor
                              .withOpacity(0.5 + _pulseController.value * 0.5)
                          : Colors.grey[600],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                widget.isRecording ? 'REC' : 'READY',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(double level, Color baseColor) {
    if (level < 0.3) return Colors.green;
    if (level < 0.7) return Colors.yellow;
    if (level < 0.9) return Colors.orange;
    return Colors.red;
  }

  double _audioLevelToDb(double level) {
    if (level <= 0) return -60.0;
    return 20 * math.log(level) / math.ln10;
  }
}

/// スタジオ品質の波形描画
class StudioWaveformPainter extends CustomPainter {
  final double audioLevel;
  final bool isRecording;
  final Color color;
  final Animation<double> animation;

  StudioWaveformPainter({
    required this.audioLevel,
    required this.isRecording,
    required this.color,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRecording) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    final random = math.Random(42); // 固定シードで一貫した波形

    // 複数の周波数成分を重ね合わせて自然な波形を作成
    for (double x = 0; x < size.width; x += 2) {
      double y = size.height / 2;

      // 基本波
      y += math.sin(
              (x / size.width * 4 * math.pi) + animation.value * 2 * math.pi) *
          audioLevel *
          size.height *
          0.3;

      // 高周波成分
      y += math.sin(
              (x / size.width * 8 * math.pi) + animation.value * 4 * math.pi) *
          audioLevel *
          size.height *
          0.1;

      // ランダムノイズ
      y += (random.nextDouble() - 0.5) * audioLevel * size.height * 0.05;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // グラデーション効果
    final gradient = LinearGradient(
      colors: [
        color.withOpacity(0.1),
        color,
        color.withOpacity(0.1),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    paint.shader =
        gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(StudioWaveformPainter oldDelegate) {
    return oldDelegate.audioLevel != audioLevel ||
        oldDelegate.isRecording != isRecording;
  }
}
