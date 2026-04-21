import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/midnight_pitch_theme.dart';

// ============================================================
// NOTIFICATION SYSTEM
// ============================================================

/// Notification data model
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.type = NotificationType.general,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    title: title,
    body: body,
    timestamp: timestamp,
    type: type,
    isRead: isRead ?? this.isRead,
  );
}

enum NotificationType {
  matchLive,
  matchGoal,
  matchEnd,
  teamInvite,
  chat,
  general,
}

/// Notification provider for state management
class NotificationProvider extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}

/// Premium notification bell widget with animated badge
class NotificationBell extends StatefulWidget {
  final NotificationProvider notificationProvider;
  final VoidCallback? onNotificationsChanged;

  const NotificationBell({
    super.key,
    required this.notificationProvider,
    this.onNotificationsChanged,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _badgeController;
  late AnimationController _dropController;
  late Animation<double> _ringAnim;
  late Animation<double> _badgeScale;
  late Animation<double> _badgeBounce;
  late Animation<double> _dropAnim;
  bool _showDropdown = false;
  int _previousUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _dropController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _ringAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeOut),
    );
    _badgeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut),
    );
    _badgeBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.bounceOut),
    );
    _dropAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeOutCubic),
    );

    widget.notificationProvider.addListener(_onNotificationsChanged);
  }

  void _onNotificationsChanged() {
    final newCount = widget.notificationProvider.unreadCount;
    if (newCount > _previousUnreadCount) {
      _badgeController.forward(from: 0.0);
      _ringController.forward(from: 0.0);
    }
    _previousUnreadCount = newCount;
    widget.onNotificationsChanged?.call();
  }

  @override
  void dispose() {
    widget.notificationProvider.removeListener(_onNotificationsChanged);
    _ringController.dispose();
    _badgeController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      _showDropdown = !_showDropdown;
      if (_showDropdown) {
        _dropController.forward();
      } else {
        _dropController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Bell button
            _NotificationBellButton(
              ringAnim: _ringAnim,
              onTap: _toggleDropdown,
            ),
            // Badge
            if (widget.notificationProvider.hasUnread)
              Positioned(
                right: -2,
                top: -2,
                child: AnimatedBuilder(
                  animation: _badgeController,
                  builder: (context, child) {
                    final scale = _badgeScale.value;
                    final bounce = _badgeBounce.value;
                    return Transform.scale(
                      scale: scale * (0.8 + 0.2 * bounce),
                      child: _NotificationBadge(
                        count: widget.notificationProvider.unreadCount,
                      ),
                    );
                  },
                ),
              ),
            // Dropdown
            if (_showDropdown)
              Positioned(
                right: 0,
                top: constraints.maxHeight + 8,
                child: AnimatedBuilder(
                  animation: _dropController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _dropAnim.value,
                      alignment: Alignment.topRight,
                      child: Opacity(
                        opacity: _dropAnim.value,
                        child: _NotificationDropdown(
                          provider: widget.notificationProvider,
                          onClose: _toggleDropdown,
                          onMarkAllRead: () {
                            widget.notificationProvider.markAllAsRead();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NotificationBellButton extends StatefulWidget {
  final Animation<double> ringAnim;
  final VoidCallback onTap;

  const _NotificationBellButton({
    required this.ringAnim,
    required this.onTap,
  });

  @override
  State<_NotificationBellButton> createState() =>
      _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<_NotificationBellButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: widget.ringAnim,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ring pulse
              if (widget.ringAnim.value > 0)
                Opacity(
                  opacity: (1.0 - widget.ringAnim.value) * 0.6,
                  child: Transform.scale(
                    scale: 1.0 + (widget.ringAnim.value * 0.5),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: MidnightPitchTheme.electricBlue
                              .withValues(alpha: 1.0 - widget.ringAnim.value),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              // Button
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isPressed
                      ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.15)
                      : MidnightPitchTheme.surfaceContainerLow
                          .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPressed
                        ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.4)
                        : MidnightPitchTheme.ghostBorder,
                  ),
                  boxShadow: _isPressed
                      ? [
                          BoxShadow(
                            color: MidnightPitchTheme.electricBlue
                                .withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  size: 22,
                  color: _isPressed
                      ? MidnightPitchTheme.electricBlue
                      : MidnightPitchTheme.primaryText,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final int count;

  const _NotificationBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 99 ? '99+' : count.toString();
    final isLarge = count > 9;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 4 : 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MidnightPitchTheme.rose600,
            MidnightPitchTheme.rose500,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.rose600.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Text(
        displayCount,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: isLarge ? 9 : 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _NotificationDropdown extends StatelessWidget {
  final NotificationProvider provider;
  final VoidCallback onClose;
  final VoidCallback onMarkAllRead;

  const _NotificationDropdown({
    required this.provider,
    required this.onClose,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: MidnightPitchTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MidnightPitchTheme.ghostBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: MidnightPitchTheme.slate900.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: MidnightPitchTheme.border,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.headingFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MidnightPitchTheme.primaryText,
                    ),
                  ),
                  const Spacer(),
                  if (provider.hasUnread)
                    TextButton(
                      onPressed: onMarkAllRead,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MidnightPitchTheme.electricBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Notification list
            Flexible(
              child: provider.notifications.isEmpty
                  ? _EmptyNotificationState()
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: provider.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = provider.notifications[index];
                        return _NotificationListItem(
                          notification: notification,
                          onTap: () {
                            if (!notification.isRead) {
                              provider.markAsRead(notification.id);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: MidnightPitchTheme.mutedText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'All caught up!',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.headingFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MidnightPitchTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No new notifications',
            style: TextStyle(
              fontFamily: MidnightPitchTheme.fontFamily,
              fontSize: 13,
              color: MidnightPitchTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationListItem extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationListItem({
    required this.notification,
    required this.onTap,
  });

  IconData get _typeIcon {
    switch (notification.type) {
      case NotificationType.matchLive:
        return Icons.play_circle_filled_rounded;
      case NotificationType.matchGoal:
        return Icons.sports_soccer_rounded;
      case NotificationType.matchEnd:
        return Icons.flag_rounded;
      case NotificationType.teamInvite:
        return Icons.group_add_rounded;
      case NotificationType.chat:
        return Icons.chat_rounded;
      case NotificationType.general:
        return Icons.info_outline_rounded;
    }
  }

  Color get _typeColor {
    switch (notification.type) {
      case NotificationType.matchLive:
        return MidnightPitchTheme.rose600;
      case NotificationType.matchGoal:
        return MidnightPitchTheme.success;
      case NotificationType.matchEnd:
        return MidnightPitchTheme.indigo500;
      case NotificationType.teamInvite:
        return MidnightPitchTheme.amber600;
      case NotificationType.chat:
        return MidnightPitchTheme.electricBlue;
      case NotificationType.general:
        return MidnightPitchTheme.mutedText;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : MidnightPitchTheme.electricBlue.withValues(alpha: 0.04),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _typeIcon,
                  size: 20,
                  color: _typeColor,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontFamily: MidnightPitchTheme.fontFamily,
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: MidnightPitchTheme.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: MidnightPitchTheme.electricBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 13,
                        color: MidnightPitchTheme.secondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.timestamp),
                      style: TextStyle(
                        fontFamily: MidnightPitchTheme.fontFamily,
                        fontSize: 11,
                        color: MidnightPitchTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REDESIGNED MOTION APPBAR
// ============================================================

/// Motion-driven AppBar with parallax, glow effects, and animated elements
class MotionAppBar extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showGlow;
  final double scrollOffset;
  final VoidCallback? onMenuTap;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final NotificationProvider? notificationProvider;

  const MotionAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showGlow = true,
    this.scrollOffset = 0,
    this.onMenuTap,
    this.showBackButton = false,
    this.onBackTap,
    this.notificationProvider,
  });

  @override
  State<MotionAppBar> createState() => _MotionAppBarState();
}

class _MotionAppBarState extends State<MotionAppBar>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final parallaxOffset = widget.scrollOffset * 0.3;

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _shimmerController]),
      builder: (context, child) {
        return _AnimatedAppBarContent(
          topPadding: topPadding,
          parallaxOffset: parallaxOffset,
          entryValue: _fadeAnim.value,
          slideValue: _slideAnim.value,
          glowValue: _glowAnim.value,
          shimmerValue: _shimmerAnim.value,
          showGlow: widget.showGlow,
          title: widget.title,
          subtitle: widget.subtitle,
          showBackButton: widget.showBackButton,
          onBackTap: widget.onBackTap,
          onMenuTap: widget.onMenuTap,
          actions: widget.actions,
          onBack: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            }
          },
          notificationProvider: widget.notificationProvider,
        );
      },
    );
  }
}

/// Separate widget so AnimatedBuilder doesn't have nested builder issues
class _AnimatedAppBarContent extends StatelessWidget {
  final double topPadding;
  final double parallaxOffset;
  final double entryValue;
  final double slideValue;
  final double glowValue;
  final double shimmerValue;
  final bool showGlow;
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final NotificationProvider? notificationProvider;

  const _AnimatedAppBarContent({
    required this.topPadding,
    required this.parallaxOffset,
    required this.entryValue,
    required this.slideValue,
    required this.glowValue,
    required this.shimmerValue,
    required this.showGlow,
    required this.title,
    this.subtitle,
    required this.showBackButton,
    this.onBackTap,
    this.onMenuTap,
    this.actions,
    this.onBack,
    this.notificationProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.9 + (entryValue * 0.1)),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.08 + (0.06 * glowValue)),
                  blurRadius: 20 + (10 * glowValue),
                  offset: Offset(0, 4 + (2 * glowValue)),
                ),
              ]
            : null,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Leading
                Opacity(opacity: entryValue, child: _buildLeading()),
                const SizedBox(width: 12),

                // Title block
                Expanded(
                  child: Opacity(
                    opacity: entryValue,
                    child: _buildTitleBlock(),
                  ),
                ),

                // Actions
                Opacity(
                  opacity: entryValue,
                  child: _buildActions(),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Opacity(
                opacity: entryValue * 0.7,
                child: Transform.translate(
                  offset: Offset(slideValue * 0.5, 0),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: MidnightPitchTheme.fontFamily,
                      fontSize: 12,
                      color: MidnightPitchTheme.mutedText,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (showBackButton) {
      return _AppBarIconButton(
        icon: Icons.arrow_back_ios_rounded,
        onTap: onBackTap ?? onBack,
        heroLabel: 'back',
      );
    }
    return _AppBarIconButton(
      icon: Icons.menu_rounded,
      onTap: onMenuTap,
      heroLabel: 'menu',
    );
  }

  Widget _buildActions() {
    final notificationProvider = this.notificationProvider;

    if (notificationProvider != null) {
      // Use the notification bell when provider is provided
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: NotificationBell(
              notificationProvider: notificationProvider,
            ),
          ),
          const SizedBox(width: 8),
          if (actions != null) ...actions!,
        ],
      );
    }

    final actionList = actions;
    if (actionList == null || actionList.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AppBarIconButton(
            icon: Icons.notifications_outlined,
            onTap: () {},
            heroLabel: 'notif',
          ),
          const SizedBox(width: 4),
          _AppBarIconButton(
            icon: Icons.search_rounded,
            onTap: () {},
            heroLabel: 'search',
          ),
        ],
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: actionList);
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: MidnightPitchTheme.headingFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: MidnightPitchTheme.primaryText,
            letterSpacing: 0.5,
          ),
        ),
        // Shimmer underline
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 3,
          width: 40 + (30 * entryValue),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MidnightPitchTheme.electricBlue,
                Colors.white.withValues(alpha: 0.9),
                MidnightPitchTheme.electricBlue,
              ],
              stops: [
                shimmerValue.clamp(0.0, 0.5),
                (shimmerValue + 0.5).clamp(0.0, 1.0),
                (shimmerValue + 0.75).clamp(0.5, 1.0),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.4 + (0.4 * glowValue)),
                blurRadius: 6 + (4 * glowValue),
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Animated icon button for AppBar with hover/press effects
class _AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String heroLabel;
  final double size;

  const _AppBarIconButton({
    super.key,
    required this.icon,
    this.onTap,
    required this.heroLabel,
    this.size = 48,
  });

  @override
  State<_AppBarIconButton> createState() => _AppBarIconButtonState();
}

class _AppBarIconButtonState extends State<_AppBarIconButton>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _ctrl.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _ctrl.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _isPressed
                    ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.15)
                    : MidnightPitchTheme.surfaceContainerLow.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isPressed
                      ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.4)
                      : MidnightPitchTheme.ghostBorder,
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: _isPressed
                      ? MidnightPitchTheme.electricBlue
                      : MidnightPitchTheme.primaryText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hero AppBar for player home - premium glassmorphic design with day-based greeting
class PlayerHomeAppBar extends StatefulWidget {
  final String playerName;
  final double scrollOffset;
  final bool isConnected;
  final NotificationProvider? notificationProvider;

  const PlayerHomeAppBar({
    super.key,
    required this.playerName,
    this.scrollOffset = 0,
    this.isConnected = false,
    this.notificationProvider,
  });

  @override
  State<PlayerHomeAppBar> createState() => _PlayerHomeAppBarState();
}

class _PlayerHomeAppBarState extends State<PlayerHomeAppBar>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _shimmerController;
  late Animation<double> _entryAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _entryAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String _getDayGreeting() {
    final dayOfWeek = DateTime.now().weekday;
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return 'Happy ${days[dayOfWeek - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: Listenable.merge([_entryController, _shimmerController]),
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MidnightPitchTheme.surfaceContainer,
                MidnightPitchTheme.surfaceContainer.withValues(alpha: 0.95),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.05 + (0.05 * _entryAnim.value)),
                blurRadius: 20,
                offset: Offset(0, 4 + (2 * _entryAnim.value)),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + 12,
                left: 20,
                right: 20,
                bottom: 16,
              ),
              child: Row(
                children: [
                  // Avatar with gradient ring + shimmer
                  _PremiumAvatar(
                    playerName: widget.playerName,
                    entryValue: _entryAnim.value,
                    shimmerValue: _shimmerAnim.value,
                  ),
                  const SizedBox(width: 16),

                  // Name + day greeting
                  Expanded(
                    child: Opacity(
                      opacity: _entryAnim.value,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - _entryAnim.value)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Day greeting with shimmer
                            _ShimmerText(
                              text: _getDayGreeting(),
                              shimmerValue: _shimmerAnim.value,
                            ),
                            const SizedBox(height: 4),
                            // Player name
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.playerName,
                                    style: TextStyle(
                                      fontFamily: MidnightPitchTheme.headingFontFamily,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: MidnightPitchTheme.primaryText,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _ConnectionDot(isConnected: widget.isConnected),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Action icons
                  _ActionButtons(
                    notificationProvider: widget.notificationProvider,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium avatar with gradient border ring and shimmer effect
class _PremiumAvatar extends StatelessWidget {
  final String playerName;
  final double entryValue;
  final double shimmerValue;

  const _PremiumAvatar({
    required this.playerName,
    required this.entryValue,
    required this.shimmerValue,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: entryValue,
      child: Transform.scale(
        scale: 0.5 + (0.5 * entryValue),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gradient ring
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MidnightPitchTheme.electricBlue,
                    MidnightPitchTheme.indigo500,
                    MidnightPitchTheme.electricBlue,
                  ],
                  stops: [
                    (shimmerValue - 0.3).clamp(0.0, 1.0),
                    (shimmerValue + 0.1).clamp(0.0, 1.0),
                    (shimmerValue + 0.5).clamp(0.0, 1.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.3 + (0.2 * entryValue)),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            // Inner avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MidnightPitchTheme.surfaceDim,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                playerName.isNotEmpty ? playerName[0].toUpperCase() : 'P',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.headingFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricBlue,
                  shadows: [
                    Shadow(
                      color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer text effect for day greeting
class _ShimmerText extends StatelessWidget {
  final String text;
  final double shimmerValue;

  const _ShimmerText({
    required this.text,
    required this.shimmerValue,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF94A3B8), // muted slate
            Color(0xFFE2E8F0), // light
            MidnightPitchTheme.electricBlue,
            Color(0xFFE2E8F0),
            Color(0xFF94A3B8),
          ],
          stops: [
            0.0,
            (shimmerValue - 0.2).clamp(0.0, 1.0),
            shimmerValue.clamp(0.0, 1.0),
            (shimmerValue + 0.2).clamp(0.0, 1.0),
            1.0,
          ],
        ).createShader(bounds);
      },
      child: Text(
        text,
        style: TextStyle(
          fontFamily: MidnightPitchTheme.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Action buttons row for PlayerHomeAppBar
class _ActionButtons extends StatelessWidget {
  final NotificationProvider? notificationProvider;

  const _ActionButtons({this.notificationProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search button
        _PremiumIconButton(
          icon: Icons.search_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        // Notification bell or placeholder
        if (notificationProvider != null)
          SizedBox(
            width: 48,
            height: 48,
            child: NotificationBell(
              notificationProvider: notificationProvider!,
            ),
          )
        else
          _PremiumIconButton(
            icon: Icons.notifications_outlined,
            onTap: () {},
          ),
      ],
    );
  }
}

/// Premium icon button with press animation
class _PremiumIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool showBadge;
  final int badgeCount;

  const _PremiumIconButton({
    required this.icon,
    this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  @override
  State<_PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<_PremiumIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { setState(() => _isPressed = true); _ctrl.forward(); },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () { setState(() => _isPressed = false); _ctrl.reverse(); },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isPressed
                          ? [
                              MidnightPitchTheme.electricBlue.withValues(alpha: 0.15),
                              MidnightPitchTheme.indigo500.withValues(alpha: 0.1),
                            ]
                          : [
                              MidnightPitchTheme.surfaceContainerHighest,
                              MidnightPitchTheme.surfaceContainerLow,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isPressed
                          ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.4)
                          : MidnightPitchTheme.ghostBorder,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isPressed
                            ? MidnightPitchTheme.electricBlue.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: _isPressed ? 12 : 6,
                        offset: Offset(0, _isPressed ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 22,
                    color: _isPressed
                        ? MidnightPitchTheme.electricBlue
                        : MidnightPitchTheme.primaryText,
                  ),
                ),
                // Badge
                if (widget.showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            MidnightPitchTheme.rose600,
                            MidnightPitchTheme.rose500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: MidnightPitchTheme.rose600.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        widget.badgeCount > 9 ? '9+' : widget.badgeCount.toString(),
                        style: const TextStyle(
                          fontFamily: MidnightPitchTheme.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Sophisticated animated divider with gradient glow sweep
class _AnimatedDivider extends StatelessWidget {
  final double animValue;
  const _AnimatedDivider({required this.animValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            MidnightPitchTheme.electricBlue.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.9),
            MidnightPitchTheme.electricBlue.withValues(alpha: 0.5),
            Colors.transparent,
          ],
          stops: [
            (animValue - 0.2).clamp(0.0, 1.0),
            (animValue - 0.05).clamp(0.0, 1.0),
            animValue.clamp(0.0, 1.0),
            (animValue + 0.15).clamp(0.0, 1.0),
            (animValue + 0.3).clamp(0.0, 1.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Premium avatar with gradient border and pulse effect
class _AnimatedAvatar extends StatefulWidget {
  final String playerName;
  final double entryValue;
  const _AnimatedAvatar({required this.playerName, required this.entryValue});

  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnim.value * widget.entryValue,
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              gradient: MidnightPitchTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: MidnightPitchTheme.surfaceDim,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.playerName.isNotEmpty
                    ? widget.playerName[0].toUpperCase()
                    : 'P',
                style: TextStyle(
                  fontFamily: MidnightPitchTheme.headingFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MidnightPitchTheme.electricBlue,
                  shadows: [
                    Shadow(
                      color: MidnightPitchTheme.electricBlue.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


/// Connection status dot - elegant blinking green/red
class _ConnectionDot extends StatefulWidget {
  final bool isConnected;
  const _ConnectionDot({required this.isConnected});

  @override
  State<_ConnectionDot> createState() => _ConnectionDotState();
}

class _ConnectionDotState extends State<_ConnectionDot>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _blinkAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.isConnected;
    final baseColor = isConnected
        ? const Color(0xFF00E676) // Vibrant green
        : const Color(0xFFFF5252); // Soft red
    final label = isConnected ? 'Connected to Appwrite' : 'Offline';

    return Tooltip(
      message: label,
      child: SizedBox(
        width: 24,
        height: 24,
        child: AnimatedBuilder(
          animation: _blinkAnim,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulse ring (connected only)
                if (isConnected)
                  Opacity(
                    opacity: _blinkAnim.value * 0.4,
                    child: Transform.scale(
                      scale: _pulseAnim.value,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: baseColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Inner dot
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: baseColor,
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.6 + (_blinkAnim.value * 0.4)),
                        blurRadius: 6 + (_blinkAnim.value * 8),
                        spreadRadius: 0 + (_blinkAnim.value * 2),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Pulse dot widget
class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat();
    _scaleAnim = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnim.value,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: MidnightPitchTheme.electricBlue.withValues(alpha: _opacityAnim.value),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: MidnightPitchTheme.electricBlue,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
