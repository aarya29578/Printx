import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_model.dart';
import '../../services/firestore_service.dart';

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
  OrdersCubit() : super(OrdersLoading());

  Future<void> load() async {
    emit(OrdersLoading());
    await Future.delayed(const Duration(milliseconds: 200));
    emit(OrdersLoaded(await FirestoreService.fetchOrders()));
  }
}
