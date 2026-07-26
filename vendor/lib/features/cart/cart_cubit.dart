import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

import '../../features/auth/auth_repository.dart';
import '../../services/firestore_service.dart';
import '../../data/models/app_models.dart';
import '../../data/models/product_model.dart';
import '../../data/mock_data/mock_banners.dart';
import '../../core/utils/category_utils.dart';

// ─── Cart ─────────────────────────────────────────────────────────────────────

abstract class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final String? appliedCouponCode;
  final int discount;

  const CartLoaded({
    required this.items,
    this.appliedCouponCode,
    this.discount = 0,
  });

  int get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get gst => ((subtotal - discount) * 0.18).round();
  int get total => subtotal - discount + gst;
  int get itemCount => items.fold(0, (sum, item) => sum + 1);

  CartLoaded copyWith({
    List<CartItem>? items,
    String? appliedCouponCode,
    int? discount,
  }) {
    return CartLoaded(
      items: items ?? this.items,
      appliedCouponCode: appliedCouponCode ?? this.appliedCouponCode,
      discount: discount ?? this.discount,
    );
  }

  @override
  List<Object?> get props => [items, appliedCouponCode, discount];
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartLoaded(items: []));

  void addProduct(
    Product product, {
    int quantity = 100,
    String? finish,
    String? size,
    String? customDesignUrl,
    String? customDesignFileName,
    String customerInstructions = "",
  }) {
    final current = state as CartLoaded;
    const uuid = Uuid();

    // Use CategoryUtils to get proper unit type (cards, pcs, etc.)
    final specs =
        CategoryUtils.getCartSpecs(product.category, finish, quantity);

    final item = CartItem(
      id: uuid.v4(),
      productId: product.id,
      productName: product.name,
      productImage: product.imageUrl,
      basePrice: product.basePrice,
      quantity: quantity,
      finish:
          finish ?? (product.finishes.isNotEmpty ? product.finishes[0] : null),
      size: size ?? (product.sizes.isNotEmpty ? product.sizes[0] : null),
      specs: specs,
      customDesignUrl: customDesignUrl,
      customDesignFileName: customDesignFileName,
      customerInstructions: customerInstructions,
    );
    emit(CartLoaded(
      items: [...current.items, item],
      appliedCouponCode: current.appliedCouponCode,
      discount: current.discount,
    ));
  }

  void removeItem(String itemId) {
    final current = state as CartLoaded;
    emit(CartLoaded(
      items: current.items.where((i) => i.id != itemId).toList(),
      appliedCouponCode: current.appliedCouponCode,
      discount: current.discount,
    ));
  }

  void updateQty(String itemId, int qty) {
    final current = state as CartLoaded;
    emit(CartLoaded(
      items: current.items
          .map((i) => i.id == itemId ? i.copyWith(quantity: qty) : i)
          .toList(),
      appliedCouponCode: current.appliedCouponCode,
      discount: current.discount,
    ));
  }

  bool applyCoupon(String code) {
    final current = state as CartLoaded;
    final coupon = MockCoupons.all
        .where(
          (c) => c.code.toUpperCase() == code.toUpperCase() && c.isActive,
        )
        .firstOrNull;
    if (coupon == null) return false;
    final disc = coupon.calculateDiscount(current.subtotal);
    if (disc == 0) return false;
    emit(CartLoaded(
      items: current.items,
      appliedCouponCode: coupon.code,
      discount: disc,
    ));
    return true;
  }

  void removeCoupon() {
    final current = state as CartLoaded;
    emit(CartLoaded(items: current.items));
  }

  void clearCart() {
    emit(const CartLoaded(items: []));
  }
}

// ─── Checkout ─────────────────────────────────────────────────────────────────

enum DeliveryType { standard, express, sameDay }

abstract class CheckoutState extends Equatable {
  const CheckoutState();
  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutInProgress extends CheckoutState {
  final int step;
  final AddressModel? selectedAddress;
  final DeliveryType deliveryType;
  final String? paymentMethod;
  final String? orderNumber;

  const CheckoutInProgress({
    this.step = 0,
    this.selectedAddress,
    this.deliveryType = DeliveryType.standard,
    this.paymentMethod,
    this.orderNumber,
  });

  CheckoutInProgress copyWith({
    int? step,
    AddressModel? selectedAddress,
    DeliveryType? deliveryType,
    String? paymentMethod,
    String? orderNumber,
  }) {
    return CheckoutInProgress(
      step: step ?? this.step,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      deliveryType: deliveryType ?? this.deliveryType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      orderNumber: orderNumber ?? this.orderNumber,
    );
  }

  @override
  List<Object?> get props =>
      [step, selectedAddress, deliveryType, paymentMethod];
}

class CheckoutSuccess extends CheckoutState {
  final String orderNumber;
  const CheckoutSuccess(this.orderNumber);
  @override
  List<Object?> get props => [orderNumber];
}

class CheckoutError extends CheckoutState {
  final String message;
  const CheckoutError(this.message);
  @override
  List<Object?> get props => [message];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit() : super(CheckoutInitial());

  void start() {
    // Initialize checkout in-progress state.
    // (CheckoutScreen shows spinner only when state is CheckoutInitial.)
    emit(const CheckoutInProgress());
  }

  void nextStep() {
    final current = state;
    if (current is CheckoutInProgress) {
      // Require address selection before moving to Delivery step.
      if (current.step == 0 && current.selectedAddress == null) {
        return;
      }
      emit(current.copyWith(step: current.step + 1));
    }
  }

  void prevStep() {
    final current = state;
    if (current is CheckoutInProgress && current.step > 0) {
      emit(current.copyWith(step: current.step - 1));
    }
  }

  void selectAddress(AddressModel address) {
    final current = state;
    if (current is CheckoutInProgress) {
      emit(current.copyWith(selectedAddress: address));
    }
  }

  void selectDelivery(DeliveryType type) {
    final current = state;
    if (current is CheckoutInProgress) {
      emit(current.copyWith(deliveryType: type));
    }
  }

  void selectPayment(String method) {
    final current = state;
    if (current is CheckoutInProgress) {
      emit(current.copyWith(paymentMethod: method));
    }
  }

  Future<void> placeOrder(BuildContext context) async {
    final current = state;
    if (current is! CheckoutInProgress) return;

    // Require address selection before placing order.
    if (current.selectedAddress == null) {
      emit(const CheckoutError('Please select a delivery address.'));
      return;
    }

    // CheckoutCubit cannot access other cubits via `read()`.
    // Use widget-provided context to access CartCubit state.
    final cartState = BlocProvider.of<CartCubit>(context).state;
    if (cartState is! CartLoaded) return;

    final user = AuthRepository.currentUser;

    if (user == null) {
      emit(const CheckoutError('Not authenticated'));
      return;
    }

    final items = <Map<String, dynamic>>[];
    for (final ci in cartState.items) {
      items.add({
        'productId': ci.productId,
        'productName': ci.productName,
        'productImage': ci.productImage,
        'quantity': ci.quantity,
        'price': ci.basePrice,
        'size': ci.size ?? '',
        'finish': ci.finish ?? '',
        'customDesignUrl': ci.customDesignUrl,
        'customDesignFileName': ci.customDesignFileName,
        'customerInstructions': ci.customerInstructions ?? '',
      });
    }

    final totalAmount = cartState.total;

    final orderId = await FirestoreService.createOrder(
      orderId: const Uuid().v4(),
      userId: user.uid,
      userName: user.displayName ?? user.email ?? '',
      userEmail: user.email ?? '',
      deliveryAddress: current.selectedAddress!.fullAddress,
      items: items,
      totalAmount: totalAmount,
    );

    BlocProvider.of<CartCubit>(context).clearCart();
    emit(CheckoutSuccess(orderId));
  }
}

extension ListFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
