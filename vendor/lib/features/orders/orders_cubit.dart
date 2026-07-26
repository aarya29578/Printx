import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../features/auth/auth_repository.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;

  const OrdersLoaded(this.orders);

  List<Order> get active => orders
      .where((o) =>
          o.status != OrderStatus.delivered &&
          o.status != OrderStatus.cancelled)
      .toList();

  List<Order> get completed =>
      orders.where((o) => o.status == OrderStatus.delivered).toList();

  List<Order> get cancelled =>
      orders.where((o) => o.status == OrderStatus.cancelled).toList();

  @override
  List<Object?> get props => [orders];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object?> get props => [message];
}

class OrdersCubit extends Cubit<OrdersState> {
  StreamSubscription<List<Order>>? _sub;

  OrdersCubit() : super(OrdersLoading());

  void load() {
    emit(OrdersLoading());
    final currentUser = AuthRepository.currentUser;
    if (currentUser == null) {
      emit(const OrdersError('Not authenticated'));
      return;
    }
    _sub?.cancel();
    _sub = FirestoreService.watchOrdersForUser(userId: currentUser.uid).listen(
      (orders) => emit(OrdersLoaded(orders)),
      onError: (e) => emit(OrdersError(e.toString())),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
