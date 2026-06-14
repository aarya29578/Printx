import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/app_models.dart';
import '../../data/models/product_model.dart';
import '../../core/constants/api_constants.dart';
import '../../services/firestore_service.dart';

abstract class DesignsState extends Equatable {
  const DesignsState();
  @override
  List<Object?> get props => [];
}

class DesignsLoading extends DesignsState {}

class DesignsLoaded extends DesignsState {
  final List<DesignModel> designs;
  final Set<String> selectedIds;

  const DesignsLoaded({required this.designs, this.selectedIds = const {}});

  @override
  List<Object?> get props => [designs, selectedIds];
}

class DesignsError extends DesignsState {
  final String message;
  const DesignsError(this.message);
  @override
  List<Object?> get props => [message];
}

class DesignsCubit extends Cubit<DesignsState> {
  DesignsCubit() : super(DesignsLoading());

  static final List<DesignModel> _mockDesigns = [
    DesignModel(
      id: 'd001',
      name: 'My Business Card',
      category: 'visiting-cards',
      thumbnailUrl: ApiConstants.productImage(50),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    DesignModel(
      id: 'd002',
      name: 'Company T-Shirt Design',
      category: 't-shirts',
      thumbnailUrl: ApiConstants.productImage(51),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    DesignModel(
      id: 'd003',
      name: 'Event Banner 2024',
      category: 'banners',
      thumbnailUrl: ApiConstants.productImage(52),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    DesignModel(
      id: 'd004',
      name: 'Wedding Invite Draft',
      category: 'wedding',
      thumbnailUrl: ApiConstants.productImage(53),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    DesignModel(
      id: 'd005',
      name: 'Cafe Menu Card',
      category: 'stationery',
      thumbnailUrl: ApiConstants.productImage(54),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
  ];

  Future<void> load() async {
    emit(DesignsLoading());
    await Future.delayed(const Duration(milliseconds: 600));
    emit(DesignsLoaded(designs: _mockDesigns));
  }

  void saveDesign(String name, String category) {
    const uuid = Uuid();
    final design = DesignModel(
      id: uuid.v4(),
      name: name,
      category: category,
      thumbnailUrl: ApiConstants.productImage(55),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final current = state;
    if (current is DesignsLoaded) {
      emit(DesignsLoaded(designs: [design, ...current.designs]));
    }
  }

  void deleteDesign(String id) {
    final current = state;
    if (current is DesignsLoaded) {
      emit(DesignsLoaded(
          designs: current.designs.where((d) => d.id != id).toList()));
    }
  }

  void toggleSelection(String id) {
    final current = state;
    if (current is DesignsLoaded) {
      final selected = Set<String>.from(current.selectedIds);
      if (selected.contains(id)) {
        selected.remove(id);
      } else {
        selected.add(id);
      }
      emit(DesignsLoaded(designs: current.designs, selectedIds: selected));
    }
  }

  void clearSelection() {
    final current = state;
    if (current is DesignsLoaded) {
      emit(DesignsLoaded(designs: current.designs));
    }
  }
}

// ─── Search ───────────────────────────────────────────────────────────────────

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchResults extends SearchState {
  final String query;
  final List<dynamic> results;

  const SearchResults({required this.query, required this.results});

  @override
  List<Object?> get props => [query, results];
}

class SearchEmpty extends SearchState {
  final String query;
  const SearchEmpty(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(SearchInitial());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }
    emit(SearchLoading());
    await Future.delayed(const Duration(milliseconds: 400));

    final normalized = query.toLowerCase();
    final products = await FirestoreService.fetchProducts();
    final results = products
        .where((item) =>
            item.name.toLowerCase().contains(normalized) ||
            item.category.toLowerCase().contains(normalized) ||
            item.description.toLowerCase().contains(normalized))
        .toList();
    if (results.isEmpty) {
      emit(SearchEmpty(query));
    } else {
      emit(SearchResults(query: query, results: results));
    }
  }

  void clear() => emit(SearchInitial());
}

// ─── Notifications ────────────────────────────────────────────────────────────

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationModel> notifications;

  const NotificationsLoaded(this.notifications);

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notifications];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsLoading());

  Future<void> load() async {
    emit(NotificationsLoading());
    await Future.delayed(const Duration(milliseconds: 400));
    emit(const NotificationsLoaded([]));
  }

  void loadWithData(List<NotificationModel> data) {
    emit(NotificationsLoaded(data));
  }

  void markRead(String id) {
    final current = state;
    if (current is! NotificationsLoaded) return;
    emit(NotificationsLoaded(
      current.notifications
          .map((n) => n.id == id
              ? NotificationModel(
                  id: n.id,
                  title: n.title,
                  description: n.description,
                  type: n.type,
                  createdAt: n.createdAt,
                  isRead: true,
                  route: n.route,
                )
              : n)
          .toList(),
    ));
  }

  void markAllRead() {
    final current = state;
    if (current is! NotificationsLoaded) return;
    emit(NotificationsLoaded(
      current.notifications
          .map((n) => NotificationModel(
                id: n.id,
                title: n.title,
                description: n.description,
                type: n.type,
                createdAt: n.createdAt,
                isRead: true,
                route: n.route,
              ))
          .toList(),
    ));
  }

  void deleteNotification(String id) {
    final current = state;
    if (current is! NotificationsLoaded) return;
    emit(NotificationsLoaded(
        current.notifications.where((n) => n.id != id).toList()));
  }
}
