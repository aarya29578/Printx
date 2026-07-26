import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Notifications ────────────────────────────────────────────────────────────

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });
}

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationItem> notifications;
  const NotificationsLoaded(this.notifications);

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notifications];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsLoading()) {
    // Architecture ready — push notification integration here later
    emit(const NotificationsLoaded([]));
  }

  void addNotification(NotificationItem item) {
    final current = state;
    if (current is NotificationsLoaded) {
      emit(NotificationsLoaded([item, ...current.notifications]));
    }
  }

  void markAllRead() {
    final current = state;
    if (current is! NotificationsLoaded) return;
    emit(NotificationsLoaded(
      current.notifications
          .map((n) => NotificationItem(
                id: n.id,
                title: n.title,
                body: n.body,
                createdAt: n.createdAt,
                isRead: true,
              ))
          .toList(),
    ));
  }
}
