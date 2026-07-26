import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mock_data/mock_reviews.dart';
import '../../data/models/app_models.dart';
import '../../features/misc_cubits.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<NotificationsCubit>().loadWithData(MockNotifications.all);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoaded && state.unreadCount > 0) {
                return TextButton(
                  onPressed: () =>
                      context.read<NotificationsCubit>().markAllRead(),
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        size: 80, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.md),
                    Text('No notifications',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 16)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = state.notifications[index];
                return FadeInLeft(
                  delay: Duration(milliseconds: index * 60),
                  child: Slidable(
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) => context
                              .read<NotificationsCubit>()
                              .deleteNotification(n.id),
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: _NotificationTile(notification: n),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  IconData _icon() {
    return switch (notification.type) {
      NotificationType.order => Icons.receipt_long_rounded,
      NotificationType.delivery => Icons.local_shipping_rounded,
      NotificationType.offer => Icons.local_offer_rounded,
      NotificationType.system => Icons.info_outline_rounded,
    };
  }

  Color _iconColor() {
    return switch (notification.type) {
      NotificationType.order => AppColors.primary,
      NotificationType.delivery => AppColors.success,
      NotificationType.offer => AppColors.accent,
      NotificationType.system => AppColors.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead
          ? null
          : AppColors.primary.withOpacity(0.04),
      child: ListTile(
        onTap: () {
          context
              .read<NotificationsCubit>()
              .markRead(notification.id);
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _iconColor().withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_icon(), color: _iconColor(), size: 22),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
              fontWeight: notification.isRead
                  ? FontWeight.w400
                  : FontWeight.w700,
              fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.description,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text(
              timeago.format(notification.createdAt),
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }
}
