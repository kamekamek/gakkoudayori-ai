import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 音声録音中の波形表示ウィジェット
class AudioWaveformWidget extends StatefulWidget {
  final double audioLevel;
  final bool isRecording;
  final Color? color;
  final int barCount;
  final double height;

  const AudioWaveformWidget({
    super.key,
    required this.audioLevel,
    required this.isRecording,
    this.color,
    this.barCount = 5,
    this.height = 40,
  });

  @override
  State<AudioWaveformWidget> createState() => _AudioWaveformWidgetState();
}

class _AudioWaveformWidgetState extends State<AudioWaveformWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _barControllers;
  final List<double> _barHeights = [];

  @override
  void initState() {
    super.initState();

    // メインアニメーションコントローラー
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    // 各バーのアニメーションコントローラー
    _barControllers = List.generate(
      widget.barCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200 + (index * 50)),
        vsync: this,
      ),
    );

    // 初期バー高さを設定
    _barHeights.addAll(List.filled(widget.barCount, 0.1));

    // 録音中の場合、アニメーション開始
    if (widget.isRecording) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(AudioWaveformWidget oldWidget) {
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
    for (var controller in _barControllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimation() {
    for (var controller in _barControllers) {
      controller.stop();
      controller.reset();
    }
  }

  void _updateWaveform() {
    final random = math.Random();
    for (int i = 0; i < widget.barCount; i++) {
      // 音声レベルとランダム要素を組み合わせて自然な波形を作成
      final baseLevel = widget.audioLevel.clamp(0.0, 1.0);
      final randomFactor = 0.3 + (random.nextDouble() * 0.7);
      _barHeights[i] = (baseLevel * randomFactor).clamp(0.1, 1.0);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _barControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

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
                  ? (_barHeights[index] + (animationValue * 0.3)) *
                      widget.height
                  : widget.height * 0.1;

              return Container(
                width: 4,
                height: barHeight.clamp(widget.height * 0.1, widget.height),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// 録音ボタン用のアニメーション付きマイクアイコン
class AnimatedMicIcon extends StatefulWidget {
  final bool isRecording;
  final Color? color;
  final double size;

  const AnimatedMicIcon({
    super.key,
    required this.isRecording,
    this.color,
    this.size = 24,
  });

  @override
  State<AnimatedMicIcon> createState() => _AnimatedMicIconState();
}

class _AnimatedMicIconState extends State<AnimatedMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isRecording) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedMicIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRecording ? _scaleAnimation.value : 1.0,
          child: Opacity(
            opacity: widget.isRecording ? _opacityAnimation.value : 1.0,
            child: Icon(
              widget.isRecording ? Icons.stop : Icons.mic,
              color: widget.color,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}
