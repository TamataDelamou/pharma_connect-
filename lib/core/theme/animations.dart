import 'package:flutter/material.dart';

class PharmaConnectAnimations {
  // ==================== DURATIONS ====================
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration hoverTransition = Duration(milliseconds: 150);
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration modalOpen = Duration(milliseconds: 250);
  static const Duration notificationSlide = Duration(milliseconds: 400);
  static const Duration kernelPulse = Duration(milliseconds: 2000);
  static const Duration scanLoading = Duration(milliseconds: 1200);
  static const Duration themeTransition = Duration(milliseconds: 400);

  // ==================== CURVES ====================
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.easeOutBack;

  // ==================== ANIMATION HELPERS ====================
  static Widget slideFadeTransition({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    double offsetY = 20,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offsetY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget scalePress({
    required Widget child,
    VoidCallback? onTap,
    double scale = 0.96,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1, end: 1),
        duration: buttonPress,
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: child,
      ),
    );
  }

  static AnimationController createKernelPulseController(TickerProvider vsync) {
    return AnimationController(duration: kernelPulse, vsync: vsync)..repeat();
  }

  static Widget shimmerScanLoading({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: const GradientRotation(0.3),
        ).createShader(
          Rect.fromLTWH(
            bounds.left + animation.value * bounds.width,
            0,
            bounds.width * 0.3,
            bounds.height,
          ),
        );
      },
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }
}
