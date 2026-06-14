import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  confirmed,
  designApproved,
  printing,
  qualityCheck,
  dispatched,
  outForDelivery,
  delivered,
  cancelled
}

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String? specs;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.specs,
  });

  @override
  List<Object?> get props => [productId];
}

class TrackingStep extends Equatable {
  final String title;
  final String? description;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;

  const TrackingStep({
    required this.title,
    this.description,
    this.timestamp,
    required this.isCompleted,
    this.isCurrent = false,
  });

  @override
  List<Object?> get props => [title];
}

class Order extends Equatable {
  final String id;
  final String orderNumber;
  final List<OrderItem> items;
  final int subtotal;
  final int discount;
  final int deliveryCharge;
  final int gst;
  final int total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final List<TrackingStep> trackingSteps;
  final String deliveryAddress;
  final String? trackingId;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    this.deliveryCharge = 0,
    required this.gst,
    required this.total,
    required this.status,
    required this.createdAt,
    this.estimatedDelivery,
    this.trackingSteps = const [],
    required this.deliveryAddress,
    this.trackingId,
  });

  @override
  List<Object?> get props => [id];
}
