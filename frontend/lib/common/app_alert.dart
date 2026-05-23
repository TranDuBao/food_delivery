import 'package:flutter/material.dart';

/// Hiển thị thông báo dạng modal đẹp với icon ở giữa màn hình
class AppAlert {
  /// [type]: 'success' | 'error' | 'warning' | 'info'
  static void show(
    BuildContext context, {
    required String message,
    String type = 'success',
    Duration duration = const Duration(seconds: 2),
  }) {
    final config = _configs[type] ?? _configs['success']!;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AlertOverlay(
        message: message,
        icon: config['icon'] as IconData,
        iconColor: config['iconColor'] as Color,
        bgColor: config['bgColor'] as Color,
        borderColor: config['borderColor'] as Color,
        onDismiss: () => entry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(entry);
  }

  static final Map<String, Map<String, dynamic>> _configs = {
    'success': {
      'icon': Icons.check_circle_outline_rounded,
      'iconColor': const Color(0xFF22C55E),
      'bgColor': Colors.white,
      'borderColor': const Color(0xFF22C55E),
    },
    'error': {
      'icon': Icons.error_outline_rounded,
      'iconColor': const Color(0xFFEF4444),
      'bgColor': Colors.white,
      'borderColor': const Color(0xFFEF4444),
    },
    'warning': {
      'icon': Icons.warning_amber_rounded,
      'iconColor': const Color(0xFFF59E0B),
      'bgColor': Colors.white,
      'borderColor': const Color(0xFFF59E0B),
    },
    'info': {
      'icon': Icons.info_outline_rounded,
      'iconColor': const Color(0xFF3B82F6),
      'bgColor': Colors.white,
      'borderColor': const Color(0xFF3B82F6),
    },
  };
}

class _AlertOverlay extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onDismiss;
  final Duration duration;

  const _AlertOverlay({
    required this.message,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<_AlertOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _ctrl.reverse();
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () async {
          await _ctrl.reverse();
          widget.onDismiss();
        },
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 260, minWidth: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                  decoration: BoxDecoration(
                    color: widget.bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: widget.borderColor.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circle icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.iconColor.withValues(alpha: 0.1),
                          border: Border.all(color: widget.iconColor.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Icon(widget.icon, color: widget.iconColor, size: 38),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
