import 'package:flutter/material.dart';
import '../core/models/chat_message.dart';

/// 統一された通知コンポーネント
class NotificationWidget extends StatefulWidget {
  final String message;
  final SystemMessageType type;
  final VoidCallback? onDismiss;
  final bool autoHide;
  final Duration autoHideDuration;
  final bool isVisible;

  const NotificationWidget({
    super.key,
    required this.message,
    required this.type,
    this.onDismiss,
    this.autoHide = true,
    this.autoHideDuration = const Duration(seconds: 5),
    this.isVisible = true,
  });

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    if (widget.isVisible) {
      _animationController.forward();
    }

    if (widget.autoHide) {
      Future.delayed(widget.autoHideDuration, () {
        if (mounted) {
          _hide();
        }
      });
    }
  }

  @override
  void didUpdateWidget(NotificationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _hide();
    }
  }

  void _hide() {
    _animationController.reverse().then((_) {
      if (mounted && widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
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
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getIconColor().withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getIconColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(),
                  size: 20,
                  color: _getIconColor(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    color: _getTextColor(),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.onDismiss != null)
                GestureDetector(
                  onTap: _hide,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: _getIconColor().withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.type) {
      case SystemMessageType.pdfGenerated:
        return Icons.picture_as_pdf;
      case SystemMessageType.classroomPosted:
        return Icons.school;
      case SystemMessageType.error:
        return Icons.error_outline;
      case SystemMessageType.success:
        return Icons.check_circle_outline;
      case SystemMessageType.warning:
        return Icons.warning_outlined;
      case SystemMessageType.info:
        return Icons.info_outline;
    }
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case SystemMessageType.pdfGenerated:
        return Colors.purple.shade50;
      case SystemMessageType.classroomPosted:
        return Colors.green.shade50;
      case SystemMessageType.error:
        return Colors.red.shade50;
      case SystemMessageType.success:
        return Colors.green.shade50;
      case SystemMessageType.warning:
        return Colors.orange.shade50;
      case SystemMessageType.info:
        return Colors.blue.shade50;
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
      case SystemMessageType.pdfGenerated:
        return Colors.purple.shade800;
      case SystemMessageType.classroomPosted:
        return Colors.green.shade800;
      case SystemMessageType.error:
        return Colors.red.shade800;
      case SystemMessageType.success:
        return Colors.green.shade800;
      case SystemMessageType.warning:
        return Colors.orange.shade800;
      case SystemMessageType.info:
        return Colors.blue.shade800;
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case SystemMessageType.pdfGenerated:
        return Colors.purple.shade600;
      case SystemMessageType.classroomPosted:
        return Colors.green.shade600;
      case SystemMessageType.error:
        return Colors.red.shade600;
      case SystemMessageType.success:
        return Colors.green.shade600;
      case SystemMessageType.warning:
        return Colors.orange.shade600;
      case SystemMessageType.info:
        return Colors.blue.shade600;
    }
  }
}

/// 複数の通知を管理するコンテナ
class NotificationContainer extends StatefulWidget {
  final List<NotificationData> notifications;
  final Function(String)? onDismiss;

  const NotificationContainer({
    super.key,
    required this.notifications,
    this.onDismiss,
  });

  @override
  State<NotificationContainer> createState() => _NotificationContainerState();
}

class _NotificationContainerState extends State<NotificationContainer> {
  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          children: widget.notifications.map((notification) {
            return NotificationWidget(
              key: ValueKey(notification.id),
              message: notification.message,
              type: notification.type,
              onDismiss: () {
                if (widget.onDismiss != null) {
                  widget.onDismiss!(notification.id);
                }
              },
              autoHide: notification.autoHide,
              autoHideDuration: notification.autoHideDuration,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 通知データクラス
class NotificationData {
  final String id;
  final String message;
  final SystemMessageType type;
  final bool autoHide;
  final Duration autoHideDuration;

  NotificationData({
    required this.id,
    required this.message,
    required this.type,
    this.autoHide = true,
    this.autoHideDuration = const Duration(seconds: 5),
  });
}