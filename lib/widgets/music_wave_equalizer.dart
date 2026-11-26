import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

/// Animated 4-bar Spotify-style audio wave equalizer visualizer.
/// Shows animated pulsing green bars when music is playing,
/// and resting static bars when paused.
class MusicWaveEqualizer extends StatefulWidget {
  final bool isPlaying;
  final double? size;
  final Color? color;
  final int barCount;

  const MusicWaveEqualizer({
    super.key,
    this.isPlaying = true,
    this.size,
    this.color,
    this.barCount = 4,
  });

  @override
  State<MusicWaveEqualizer> createState() => _MusicWaveEqualizerState();
}

class _MusicWaveEqualizerState extends State<MusicWaveEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MusicWaveEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.size ?? 14.h;
    final color = widget.color ?? AppColors.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animVal = widget.isPlaying ? _controller.value : 0.2;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (index) {
            // Sinusoidal wave phase offsets for organic music rhythm motion
            final phase = (index * 0.28);
            final wave = math.sin((animVal + phase) * 2 * math.pi);
            // Normalized height scale between 0.25 and 1.0
            final scale = (0.25 + 0.75 * (wave.abs())).clamp(0.25, 1.0);
            final barHeight = height * scale;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 1.2.w),
              width: 2.6.w,
              height: barHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5.r),
              ),
            );
          }),
        );
      },
    );
  }
}
