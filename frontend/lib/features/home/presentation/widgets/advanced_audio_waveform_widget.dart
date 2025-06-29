import 'package:flutter/material.dart';
import 'dart:math' as math;

/// より魅力的な音声波形表示ウィジェット（現代的なデザイン）
class AdvancedAudioWaveformWidget extends StatefulWidget {
  final double audioLevel;
  final bool isRecording;
  final Color? color;
  final int barCount;
  final double height;
  final WaveformStyle style;

  const AdvancedAudioWaveformWidget({
    super.key,
    required this.audioLevel,
    required this.isRecording,
    this.color,
    this.barCount = 12,
    this.height = 40,
    this.style = WaveformStyle.bars,
  });

  @override
  State<AdvancedAudioWaveformWidget> createState() =>
      _AdvancedAudioWaveformWidgetState();
}

enum WaveformStyle {
  bars, // 従来のバー形式
  pulse, // パルス波形
  ripple, // 波紋エフェクト
  spectrum, // スペクトラム表示
}

class _AdvancedAudioWaveformWidgetState
    extends State<AdvancedAudioWaveformWidget> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late List<AnimationController> _barControllers;
  final List<double> _barHeights = [];
  final List<double> _barOpacities = [];

  @override
  void initState() {
    super.initState();

    // メインアニメーションコントローラー
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // パルスアニメーション用
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 各バーのアニメーションコントローラー
    _barControllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 30)),
        vsync: this,
      ),
    );

    // 初期バー高さとオパシティを設定
    _initializeBars();

    // 録音中の場合、アニメーション開始
    if (widget.isRecording) {
      _startAnimation();
    }
  }

  void _initializeBars() {
    _barHeights.clear();
    _barOpacities.clear();
    for (int i = 0; i < widget.barCount; i++) {
      _barHeights.add(0.1);
      _barOpacities.add(0.3);
    }
  }

  @override
  void didUpdateWidget(AdvancedAudioWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }

    if (widget.audioLevel != oldWidget.audioLevel && widget.isRecording) {
      _updateWaveform();
    }
  }

  void _startAnimation() {
    switch (widget.style) {
      case WaveformStyle.pulse:
        _pulseController.repeat();
        break;
      case WaveformStyle.ripple:
        _pulseController.repeat(reverse: true);
        break;
      default:
        for (var controller in _barControllers) {
          controller.repeat(reverse: true);
        }
    }
  }

  void _stopAnimation() {
    _pulseController.stop();
    _pulseController.reset();
    for (var controller in _barControllers) {
      controller.stop();
      controller.reset();
    }
  }

  void _updateWaveform() {
    final random = math.Random();
    final baseLevel = widget.audioLevel.clamp(0.0, 1.0);

    for (int i = 0; i < widget.barCount; i++) {
      // 中央が高く、両端が低くなるような分布
      final centerDistance =
          (i - widget.barCount / 2).abs() / (widget.barCount / 2);
      final centerWeight = 1.0 - (centerDistance * 0.3);

      // 音声レベルとランダム要素を組み合わせて自然な波形を作成
      final randomFactor = 0.4 + (random.nextDouble() * 0.6);
      final levelWithCenter = baseLevel * centerWeight * randomFactor;

      _barHeights[i] = levelWithCenter.clamp(0.1, 1.0);
      _barOpacities[i] = (0.3 + levelWithCenter * 0.7).clamp(0.3, 1.0);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    for (var controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    switch (widget.style) {
      case WaveformStyle.pulse:
        return _buildPulseWaveform(color);
      case WaveformStyle.ripple:
        return _buildRippleWaveform(color);
      case WaveformStyle.spectrum:
        return _buildSpectrumWaveform(color);
      default:
        return _buildBarsWaveform(color);
    }
  }

  Widget _buildBarsWaveform(Color color) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _barControllers[index],
            builder: (context, child) {
              final animationValue =
                  widget.isRecording ? _barControllers[index].value : 0.0;

              final barHeight = widget.isRecording
                  ? (_barHeights[index] + (animationValue * 0.2)) *
                      widget.height
                  : widget.height * 0.1;

              final opacity = widget.isRecording ? _barOpacities[index] : 0.3;

              return Container(
                width: math.max(2, (widget.height / widget.barCount) * 0.6),
                height: barHeight.clamp(widget.height * 0.1, widget.height),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(opacity * 0.7),
                      color.withOpacity(opacity),
                      color.withOpacity(opacity * 0.7),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: widget.isRecording
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 2,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulseWaveform(Color color) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final delay = index / widget.barCount;
              final animationValue = ((_pulseController.value + delay) % 1.0);
              final baseLevel = widget.audioLevel.clamp(0.0, 1.0);

              final height = widget.isRecording
                  ? (baseLevel * (0.5 + animationValue * 0.5)) * widget.height
                  : widget.height * 0.1;

              return Container(
                width: 2,
                height: height.clamp(widget.height * 0.1, widget.height),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.4 + animationValue * 0.6),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildRippleWaveform(Color color) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(3, (ring) {
              final scale = 0.3 + (ring * 0.3) + (_pulseController.value * 0.4);
              final opacity =
                  (1.0 - _pulseController.value) * (1.0 - ring * 0.3);

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.height,
                  height: widget.height,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(opacity * 0.5),
                      width: 1,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildSpectrumWaveform(Color color) {
    return SizedBox(
      height: widget.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _barControllers[index],
            builder: (context, child) {
              final frequency = (index + 1) / widget.barCount;
              final animationValue = _barControllers[index].value;
              final baseLevel = widget.audioLevel * frequency;

              final barHeight = widget.isRecording
                  ? (baseLevel + (animationValue * 0.3)) * widget.height
                  : widget.height * 0.05;

              return Expanded(
                child: Container(
                  height: barHeight.clamp(widget.height * 0.05, widget.height),
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color.withOpacity(0.4),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(1),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// 録音状態インジケーター（ドットアニメーション）
class RecordingDotsIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const RecordingDotsIndicator({
    super.key,
    required this.color,
    this.size = 8,
  });

  @override
  State<RecordingDotsIndicator> createState() => _RecordingDotsIndicatorState();
}

class _RecordingDotsIndicatorState extends State<RecordingDotsIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );

    // 各ドットを遅延させてアニメーション開始
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color
                    .withOpacity(0.3 + _controllers[index].value * 0.7),
              ),
            );
          },
        );
      }),
    );
  }
}
