import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class BannerModel extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String ctaText;
  final Color primaryColor;
  final Color secondaryColor;
  final String imageUrl;
  final int position;
  final String? offerLabel;
  final String? route;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.primaryColor,
    required this.secondaryColor,
    required this.imageUrl,
    this.position = 0,
    this.offerLabel,
    this.route,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        ctaText,
        primaryColor,
        secondaryColor,
        imageUrl,
        position,
        offerLabel,
        route,
      ];
}

class CouponModel extends Equatable {
  final String id;
  final String code;
  final String title;
  final String description;
  final int discountAmount;
  final bool isPercentage;
  final int minOrderAmount;
  final DateTime expiry;
  final bool isActive;

  const CouponModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountAmount,
    this.isPercentage = false,
    required this.minOrderAmount,
    required this.expiry,
    this.isActive = true,
  });

  int calculateDiscount(int orderTotal) {
    if (!isActive || orderTotal < minOrderAmount) return 0;
    if (isPercentage) {
      return ((orderTotal * discountAmount) / 100).round();
    }
    return discountAmount;
  }

  @override
  List<Object?> get props => [id];
}

class ReviewModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String productId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String> images;
  final bool isVerifiedPurchase;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.productId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images = const [],
    this.isVerifiedPurchase = false,
  });

  @override
  List<Object?> get props => [id];
}

enum NotificationType { order, delivery, offer, system }

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final String? route;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.route,
  });

  @override
  List<Object?> get props => [id];
}

class CartItem extends Equatable {
  final String id;
  final String? customDesignUrl;
  final String? customDesignFileName;
  final String customerInstructions;
  final String productId;
  final String productName;
  final String productImage;
  final int basePrice;
  final int quantity;
  final String? finish;
  final String? size;
  final String? specs;
  final String? designId;

  const CartItem({
    required this.id,
    this.customDesignUrl,
    this.customDesignFileName,
    this.customerInstructions = "",
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.basePrice,
    required this.quantity,
    this.finish,
    this.size,
    this.specs,
    this.designId,
  });

  int get totalPrice => basePrice * (quantity ~/ 100).clamp(1, 100);

  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImage,
    int? basePrice,
    int? quantity,
    String? finish,
    String? size,
    String? specs,
    String? designId,
    String? customDesignUrl,
    String? customDesignFileName,
    String? customerInstructions,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      basePrice: basePrice ?? this.basePrice,
      quantity: quantity ?? this.quantity,
      finish: finish ?? this.finish,
      size: size ?? this.size,
      specs: specs ?? this.specs,
      designId: designId ?? this.designId,
      customDesignUrl: customDesignUrl ?? this.customDesignUrl,
      customDesignFileName: customDesignFileName ?? this.customDesignFileName,
      customerInstructions: customerInstructions ?? this.customerInstructions,
    );
  }

  @override
  List<Object?> get props => [id];
}

class DesignModel extends Equatable {
  final String id;
  final String name;
  final String category;
  final String thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> canvasData;

  const DesignModel({
    required this.id,
    required this.name,
    required this.category,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
    this.canvasData = const {},
  });

  @override
  List<Object?> get props => [id];
}

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final List<String> addresses;
  final int totalOrders;
  final int totalDesigns;
  final int totalSavings;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.addresses = const [],
    this.totalOrders = 0,
    this.totalDesigns = 0,
    this.totalSavings = 0,
  });

  @override
  List<Object?> get props => [id];
}

class AddressModel extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  String get fullAddress => '$addressLine, $city, $state - $pincode';

  @override
  List<Object?> get props => [id];
}
