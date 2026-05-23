// lib/common/app_notification.dart
// Thay thế SnackBar bằng modal bottom sheet có style đẹp hơn.

import 'package:flutter/material.dart';
import 'color_extension.dart';

enum NotifType { success, error, info, warning }

class AppNotification {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    NotifType type = NotifType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _NotifModal(
        message: message,
        title: title,
        type: type,
        duration: duration,
      ),
    );
  }

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Huỷ',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(message,
            style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText,
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TColor.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(confirmText,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _NotifModal extends StatefulWidget {
  final String message;
  final String? title;
  final NotifType type;
  final Duration duration;

  const _NotifModal({
    required this.message,
    this.title,
    required this.type,
    required this.duration,
  });

  @override
  State<_NotifModal> createState() => _NotifModalState();
}

class _NotifModalState extends State<_NotifModal> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Color get _bgColor {
    switch (widget.type) {
      case NotifType.success: return const Color(0xFF2ECC71);
      case NotifType.error:   return Colors.red.shade600;
      case NotifType.warning: return const Color(0xFFF39C12);
      case NotifType.info:    return const Color(0xFF3498DB);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case NotifType.success: return Icons.check_circle_rounded;
      case NotifType.error:   return Icons.cancel_rounded;
      case NotifType.warning: return Icons.warning_rounded;
      case NotifType.info:    return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _bgColor.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(_icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.title != null)
                      Text(
                        widget.title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: widget.title != null ? 12 : 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
