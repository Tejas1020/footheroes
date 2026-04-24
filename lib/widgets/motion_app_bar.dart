import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:footheroes/theme/app_theme.dart';
import 'football_background.dart';

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
  bool _isPressed = false;

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
                          color: AppTheme.cardinal
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPressed
                        ? AppTheme.cardinal.withValues(alpha: 0.4)
                        : AppTheme.cardBorderColor,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  size: 22,
                  color: AppTheme.parchment,
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
        gradient: AppTheme.heroCtaGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardinal.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        displayCount,
        style: AppTheme.dmSans.copyWith(
          fontSize: isLarge ? 9 : 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.parchment,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _NotificationDropdown extends StatelessWidget {
  final NotificationProvider provider;
  final VoidCallback onMarkAllRead;

  const _NotificationDropdown({
    required this.provider,
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
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: AppTheme.cardBorder,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.cardBorderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: AppTheme.bebasDisplay.copyWith(
                      fontSize: 18,
                      color: AppTheme.parchment,
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
                        style: AppTheme.dmSans.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.cardinal,
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
          const Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: AppTheme.mutedParchment,
          ),
          const SizedBox(height: 12),
          Text(
            'All caught up!',
            style: AppTheme.dmSans.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.parchment,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No new notifications',
            style: AppTheme.dmSans.copyWith(
              fontSize: 13,
              color: AppTheme.gold,
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
        return AppTheme.cardinal;
      case NotificationType.matchGoal:
        return AppTheme.cardinal;
      case NotificationType.matchEnd:
        return AppTheme.navy;
      case NotificationType.teamInvite:
        return AppTheme.rose;
      case NotificationType.chat:
        return AppTheme.gold;
      case NotificationType.general:
        return AppTheme.gold;
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
                : AppTheme.cardinal.withValues(alpha: 0.05),
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
                            style: AppTheme.dmSans.copyWith(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppTheme.parchment,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.cardinal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 13,
                        color: AppTheme.mutedParchment,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(notification.timestamp),
                      style: AppTheme.dmSans.copyWith(
                        fontSize: 11,
                        color: AppTheme.gold,
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
// ABSTRACT WAVE DIVIDER
// ============================================================

/// Flowing abstract line animation for app bar bottom divider.
class _AnimatedWaveLine extends StatefulWidget {
  const _AnimatedWaveLine();

  @override
  State<_AnimatedWaveLine> createState() => _AnimatedWaveLineState();
}

class _AnimatedWaveLineState extends State<_AnimatedWaveLine>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _slide = Tween<double>(begin: -0.2, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: double.infinity,
          height: 2,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.cardinal.withValues(alpha: 0.0),
                        AppTheme.cardinal.withValues(alpha: 0.7),
                        AppTheme.parchment.withValues(alpha: 0.5),
                        AppTheme.cardinal.withValues(alpha: 0.0),
                      ],
                      stops: [
                        (_slide.value - 0.15).clamp(0.0, 1.0),
                        _slide.value.clamp(0.0, 1.0),
                        (_slide.value + 0.15).clamp(0.0, 1.0),
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// REDESIGNED MOTION APPBAR
// ============================================================

/// Motion-driven AppBar with parallax and brand-consistent design.
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: FootballBackground(
          backgroundColor: AppTheme.abyss.withValues(alpha: 0.9 + (entryValue * 0.1)),
          colors: const [
            AppTheme.redDeep,
            AppTheme.cardinal,
            AppTheme.navy,
          ],
          child: Container(
            padding: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16, bottom: 45),
            decoration: BoxDecoration(
              boxShadow: showGlow
                  ? [
                      BoxShadow(
                        color: AppTheme.cardinal.withValues(alpha: 0.08 + (0.06 * glowValue)),
                        blurRadius: 20 + (10 * glowValue),
                        offset: Offset(0, 4 + (2 * glowValue)),
                      ),
                    ]
                  : null,
            ),
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
                        style: AppTheme.dmSans.copyWith(
                          fontSize: 12,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Opacity(opacity: entryValue, child: const _AnimatedWaveLine()),
              ],
            ),
          ),
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
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 22,
            color: AppTheme.parchment,
            letterSpacing: 0.5,
          ),
        ),
        // Shimmer underline using brand tokens
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 2.5,
          width: 40 + (30 * entryValue),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.cardinal,
                AppTheme.parchment.withValues(alpha: 0.9),
                AppTheme.navy,
              ],
              stops: [
                shimmerValue.clamp(0.0, 0.5),
                (shimmerValue + 0.5).clamp(0.0, 1.0),
                (shimmerValue + 0.75).clamp(0.5, 1.0),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _AppBarIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String heroLabel;

  const _AppBarIconButton({
    required this.icon,
    this.onTap,
    required this.heroLabel,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isPressed
                    ? AppTheme.cardinal.withValues(alpha: 0.15)
                    : AppTheme.cardSurface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isPressed
                      ? AppTheme.cardinal.withValues(alpha: 0.4)
                      : AppTheme.cardBorderColor,
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: _isPressed
                      ? AppTheme.cardinal
                      : AppTheme.parchment,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hero AppBar for player home using brand specification.
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
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _entryAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, _) {
        return FootballBackground(
          backgroundColor: AppTheme.abyss,
          colors: const [
            AppTheme.redDeep,
            AppTheme.cardinal,
            AppTheme.navy,
          ],
          child: Padding(
            padding: const EdgeInsets.only(bottom: 45),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: topPadding + 12,
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    child: Row(
                      children: [
                        // Clean avatar with brand red
                        _CleanAvatar(
                          playerName: widget.playerName,
                          entryValue: _entryAnim.value,
                        ),
                        const SizedBox(width: 16),

                        // Name + greeting
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Hey, Welcome',
                                style: AppTheme.dmSans.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.gold,
                                  letterSpacing: 0.15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.playerName,
                                      style: AppTheme.dmSans.copyWith(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.parchment,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _ConnectionDot(isConnected: widget.isConnected),
                                ],
                              ),
                            ],
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
                const SizedBox(height: 12),
                const _AnimatedWaveLine(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CleanAvatar extends StatelessWidget {
  final String playerName;
  final double entryValue;

  const _CleanAvatar({
    required this.playerName,
    required this.entryValue,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.5 + (0.5 * entryValue),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          gradient: AppTheme.heroCtaGradient,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          playerName.isNotEmpty ? playerName[0].toUpperCase() : 'P',
          style: AppTheme.bebasDisplay.copyWith(
            fontSize: 18,
            color: AppTheme.parchment,
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final NotificationProvider? notificationProvider;

  const _ActionButtons({this.notificationProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PremiumIconButton(
          icon: Icons.search_rounded,
          onTap: () {},
        ),
        const SizedBox(width: 8),
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

class _PremiumIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PremiumIconButton({
    required this.icon,
    this.onTap,
  });

  @override
  State<_PremiumIconButton> createState() => _PremiumIconButtonState();
}

class _PremiumIconButtonState extends State<_PremiumIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

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
      onTapDown: (_) { _ctrl.forward(); },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () { _ctrl.reverse(); },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.cardSurface,
                shape: BoxShape.circle,
                border: AppTheme.cardBorder,
                boxShadow: AppTheme.cardShadow,
              ),
              child: Icon(
                widget.icon,
                size: 22,
                color: AppTheme.parchment,
              ),
            ),
          );
        },
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _blinkAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
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
        ? AppTheme.gold
        : AppTheme.cardinal;

    return AnimatedBuilder(
      animation: _blinkAnim,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor.withValues(alpha: _blinkAnim.value),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}
