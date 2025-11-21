import 'package:flutter/material.dart';
import 'package:junk_wunk/utils/colors.dart';

class CustomToast {
  static OverlayEntry? _currentOverlay;

  /// Shows a custom animated toast message that grows from the bottom of the screen
  ///
  /// [context] - The BuildContext for showing the toast
  /// [message] - The text message to display
  /// [color] - The background color of the toast
  /// [icon] - Optional icon to show before the message
  /// [duration] - How long to show the toast (default calculated based on message length)
  static void show({
    required BuildContext context,
    required String message,
    required Color color,
    IconData? icon,
    Duration? duration,
  }) {
    try {
      // Check if the context is valid
      if (!context.mounted) return;

      // Calculate appropriate duration based on message length if not provided
      final effectiveDuration =
          duration ?? _calculateDurationForMessage(message);

      // Safely remove any existing toast
      try {
        if (_currentOverlay != null) {
          _currentOverlay?.remove();
        }
      } catch (e) {
        // Silently handle any errors from removing previous overlay
        debugPrint('Error removing previous toast: $e');
      }

      _currentOverlay = null;

      // Create a new overlay entry
      final newOverlay = OverlayEntry(
        builder: (context) => _ToastAnimation(
          message: message,
          color: color,
          icon: icon,
          duration: effectiveDuration,
        ),
      );

      // Save reference to current overlay
      _currentOverlay = newOverlay;

      // Show the overlay
      Overlay.of(context).insert(newOverlay);

      // Schedule removal after duration
      Future.delayed(effectiveDuration + const Duration(milliseconds: 500), () {
        try {
          if (_currentOverlay == newOverlay) {
            _currentOverlay?.remove();
            _currentOverlay = null;
          }
        } catch (e) {
          // Silently handle any errors when removing the overlay
          debugPrint('Error removing toast: $e');
          _currentOverlay = null;
        }
      });
    } catch (e) {
      // If anything goes wrong, make sure we clean up
      debugPrint('Error showing toast: $e');
      _currentOverlay = null;
    }
  }

  /// Shows a success toast with medium green color and check icon
  static void showSuccess(BuildContext context, String message,
      {Duration? duration}) {
    show(
      context: context,
      message: message,
      color: AppColors.success, // Medium green from theme
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  /// Shows an error toast with soft red color and error icon
  static void showError(BuildContext context, String message,
      {Duration? duration}) {
    show(
      context: context,
      message: message,
      color: AppColors.error, // Soft red from theme
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  /// Shows an info toast with blue-green color and info icon
  static void showInfo(BuildContext context, String message,
      {Duration? duration}) {
    show(
      context: context,
      message: message,
      color: AppColors.info, // Blue-green from theme
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  /// Shows a warning toast with soft amber color and warning icon
  static void showWarning(BuildContext context, String message,
      {Duration? duration}) {
    show(
      context: context,
      message: message,
      color: AppColors.warning, // Soft amber from theme
      icon: Icons.warning_amber_outlined,
      duration: duration,
    );
  }

  /// Calculates an appropriate duration for the toast based on message length
  static Duration _calculateDurationForMessage(String message) {
    // Base duration for short messages
    const baseDuration = Duration(milliseconds: 1500);

    if (message.length < 30) {
      return baseDuration;
    } else if (message.length < 60) {
      return const Duration(milliseconds: 2500);
    } else if (message.length < 100) {
      return const Duration(milliseconds: 3500);
    } else {
      // For very long messages, calculate reading time at ~15 chars/second
      // Min 4 seconds, max 8 seconds
      final readingTimeMs = (message.length / 15 * 1000).round();
      return Duration(milliseconds: readingTimeMs.clamp(4000, 8000));
    }
  }
}

class _ToastAnimation extends StatefulWidget {
  final String message;
  final Color color;
  final IconData? icon;
  final Duration duration;

  const _ToastAnimation({
    required this.message,
    required this.color,
    this.icon,
    required this.duration,
  });

  @override
  State<_ToastAnimation> createState() => _ToastAnimationState();
}

class _ToastAnimationState extends State<_ToastAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Animation for growing effect
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Animation for sliding up from bottom
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuint),
      ),
    );

    // Animation for fading in
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Start the animation
    _controller.forward();

    // Reverse the animation after duration to exit
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size
    final size = MediaQuery.of(context).size;

    return Positioned(
      bottom: 70, // Fixed distance from bottom
      width: size.width,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    // For very short messages, keep minimum width; for longer ones allow wider toast
                    width: widget.message.length < 30
                        ? size.width * 0.6
                        : size.width * 0.85,
                    constraints: BoxConstraints(
                      // For very long messages, allow wider toast up to 90% of screen width
                      maxWidth:
                          widget.message.length > 100 ? size.width * 0.9 : 350,
                      // No fixed height - allow it to expand based on content
                      minHeight: 36,
                    ),
                    padding: widget.message.length > 50
                        ? const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12) // More padding for longer messages
                        : const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: widget.message.length > 80
                        ? Column(
                            // For very long messages, use column layout
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.icon != null)
                                Container(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        widget.icon,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          // Show first part of message as header
                                          '${widget.message.split('.').first}.',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            decoration: TextDecoration.none,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.visible,
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  // If we showed a header, don't repeat it
                                  widget.icon != null
                                      ? widget.message
                                          .substring(widget.message
                                                  .split('.')
                                                  .first
                                                  .length +
                                              1)
                                          .trim()
                                      : widget.message,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                  maxLines: 8,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    decoration: TextDecoration.none,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            // For shorter messages, use row layout
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Text(
                                  widget.message,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                  maxLines: widget.message.length > 50 ? 4 : 2,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    decoration: TextDecoration.none,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
