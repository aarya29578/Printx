import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../data/mock_data/mock_categories.dart';
import '../data/mock_data/mock_banners.dart';
import '../data/mock_data/mock_orders.dart';
import '../data/mock_data/mock_products.dart';
import '../data/models/category_model.dart';
import '../data/models/app_models.dart';
import '../data/models/order_model.dart';
import '../data/models/product_model.dart';

class FirestoreService {
  FirestoreService._();

  static final firestore.FirebaseFirestore _db =
      firestore.FirebaseFirestore.instance;

  static firestore.CollectionReference<Map<String, dynamic>> get products =>
      _db.collection('products');

  static firestore.CollectionReference<Map<String, dynamic>> get categories =>
      _db.collection('categories');

  static firestore.CollectionReference<Map<String, dynamic>> get orders =>
      _db.collection('orders');

  static firestore.CollectionReference<Map<String, dynamic>> get users =>
      _db.collection('users');
  static firestore.CollectionReference<Map<String, dynamic>> get banners =>
      _db.collection('banners');

  static Future<List<Product>> fetchProducts() async {
    try {
      final snapshot = await products.get();
      if (snapshot.docs.isEmpty) return MockProducts.all;
      return snapshot.docs
          .map((doc) => _productFromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      return MockProducts.all;
    }
  }

  static Future<List<Category>> fetchCategories() async {
    try {
      final snapshot = await categories.get();
      if (snapshot.docs.isEmpty) return MockCategories.all;
      return _sortedCategories(
        snapshot.docs
            .map((doc) => _categoryFromMap(doc.id, doc.data()))
            .toList(),
      );
    } catch (_) {
      return MockCategories.all;
    }
  }

  static Future<List<BannerModel>> fetchBanners() async {
    try {
      final snapshot = await banners.get();
      if (snapshot.docs.isEmpty) return MockBanners.all;
      final items = snapshot.docs
          .map((doc) => _bannerFromMap(doc.id, doc.data()))
          .whereType<BannerModel>()
          .toList();
      if (items.isEmpty) return MockBanners.all;
      items.sort((a, b) => a.position.compareTo(b.position));
      return items;
    } catch (_) {
      return MockBanners.all;
    }
  }

  static Stream<List<Category>> watchCategories() {
    return categories.snapshots().map(
          (snapshot) => _sortedCategories(
            snapshot.docs
                .map((doc) => _categoryFromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  static BannerModel? _bannerFromMap(String id, Map<String, dynamic> data) {
    final status = (data['status'] as String?) ?? 'active';
    if (status == 'inactive') return null;
    final position = _toInt(data['position']) ?? 0;
    final primaryColor = _colorFromHex(
      (data['primaryColor'] as String?) ??
          (data['gradientFrom'] as String?) ??
          '#4F46E5',
    );
    final secondaryColor = _colorFromHex(
      (data['secondaryColor'] as String?) ??
          (data['gradientTo'] as String?) ??
          '#7C3AED',
    );
    final imageUrl = (data['imageUrl'] as String?) ??
        ApiConstants.bannerImage((position % 12) + 1);
    return BannerModel(
      id: id,
      title: (data['title'] as String?) ?? 'Banner',
      subtitle: (data['subtitle'] as String?) ?? '',
      ctaText: (data['ctaText'] as String?) ?? 'Shop Now',
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      imageUrl: imageUrl,
      position: position,
      offerLabel: data['offerLabel'] as String?,
      route: data['route'] as String?,
    );
  }

  static Color _colorFromHex(String value) {
    final normalized = value.replaceAll('#', '').trim();
    final hex = normalized.length == 6 ? 'FF$normalized' : normalized;
    return Color(int.parse(hex, radix: 16));
  }

  static List<Category> _sortedCategories(List<Category> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      final orderA = a.colorIndex;
      final orderB = b.colorIndex;
      return orderB.compareTo(orderA);
    });
    return sorted;
  }

  static Stream<List<Product>> watchProducts() {
    return products.snapshots().map(
      (snapshot) {
        // Use only live Firestore data - do not fall back to mock data
        final result = snapshot.docs
            .map((doc) => _productFromMap(doc.id, doc.data()))
            .toList();
        print(
            '📊 [FIRESTORE] watchProducts() returned ${result.length} products');
        final categories = result.map((p) => p.category).toSet();
        print('  Categories in products: ${categories.toList()}');
        return result;
      },
    );
  }

  static Future<List<Order>> fetchOrders() async {
    try {
      final snapshot = await orders.get();
      if (snapshot.docs.isEmpty) return MockOrders.all;
      return snapshot.docs
          .map((doc) => _orderFromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      return MockOrders.all;
    }
  }

  static Product _productFromMap(String id, Map<String, dynamic> data) {
    final imageUrl =
        (data['imageUrl'] as String?) ?? ApiConstants.productImage(1);
    return Product(
      id: id,
      name: (data['name'] as String?) ?? 'Unnamed Product',
      category: (data['category'] as String?) ?? 'general',
      imageUrl: imageUrl,
      imageUrls: [imageUrl],
      basePrice: _toInt(data['basePrice']) ?? 0,
      originalPrice:
          _toInt(data['originalPrice']) ?? _toInt(data['basePrice']) ?? 0,
      rating: (_toInt(data['rating']) ?? 0).toDouble(),
      reviewCount: _toInt(data['reviewCount']) ?? 0,
      isBestseller: data['isBestseller'] == true,
      finishes: _stringList(data['finishes']),
      sizes: _stringList(data['sizes']),
      description: (data['description'] as String?) ?? '',
      minQty: _toInt(data['minQty']) ?? 1,
      tags: _stringList(data['tags']),
      quantities: _intList(data['quantities']),
      badge: data['badge'] as String?,
    );
  }

  static Category _categoryFromMap(String id, Map<String, dynamic> data) {
    final order = _toInt(data['order']) ?? 0;
    final imageUrl = (data['imageUrl'] as String?) ??
        ApiConstants.categoryImage((order % 12) + 1);
    return Category(
      id: id,
      name: (data['name'] as String?) ?? 'Category',
      icon: (data['icon'] as String?) ?? 'category',
      productCount: _toInt(data['productCount']) ?? 0,
      colorIndex: order > 0 ? order - 1 : 0,
      imageUrl: imageUrl,
      description: data['description'] as String?,
    );
  }

  static Order _orderFromMap(String id, Map<String, dynamic> data) {
    final product =
        (data['product'] as Map?)?.cast<String, dynamic>() ?? const {};
    final statusText = (data['status'] as String?) ?? 'pending';
    final status = _orderStatusFromText(statusText);
    final qty = _toInt(data['qty']) ?? 1;
    final amount = _toInt(data['amount']) ?? 0;
    final date =
        DateTime.tryParse((data['date'] as String?) ?? '') ?? DateTime.now();
    final trackingId = data['trackingNumber'] as String?;
    final address = (data['address'] as String?) ?? '';
    return Order(
      id: id,
      orderNumber: (data['id'] as String?) ?? id,
      items: [
        OrderItem(
          productId: (product['id'] as String?) ?? 'product',
          productName: (product['name'] as String?) ?? 'Product',
          productImage:
              (product['thumbnail'] as String?) ?? ApiConstants.productImage(1),
          quantity: qty,
          unitPrice: qty > 0 ? (amount ~/ qty) : amount,
          totalPrice: amount,
          specs: product['specs'] as String?,
        ),
      ],
      subtotal: amount,
      discount: 0,
      deliveryCharge: 0,
      gst: 0,
      total: amount,
      status: status,
      createdAt: date,
      estimatedDelivery: null,
      trackingSteps:
          _trackingStepsFromStatus(status, data['timeline'] as List?),
      deliveryAddress: address,
      trackingId: trackingId,
    );
  }

  static List<TrackingStep> _trackingStepsFromStatus(
      OrderStatus status, List? timeline) {
    final hasTimeline = timeline is List && timeline.isNotEmpty;
    if (hasTimeline) {
      return timeline.whereType<Map>().map((step) {
        final map = step.cast<String, dynamic>();
        final done = map['done'] == true;
        final title =
            (map['step'] as String?) ?? (map['title'] as String?) ?? 'Step';
        return TrackingStep(
          title: title,
          description: map['note'] as String?,
          timestamp: DateTime.tryParse((map['time'] as String?) ?? ''),
          isCompleted: done,
          isCurrent: done,
        );
      }).toList();
    }

    final steps = <TrackingStep>[
      const TrackingStep(title: 'Order Confirmed', isCompleted: true),
      const TrackingStep(title: 'Design Approved', isCompleted: true),
      const TrackingStep(title: 'Printing in Progress', isCompleted: true),
      const TrackingStep(title: 'Quality Check', isCompleted: true),
      const TrackingStep(title: 'Dispatched', isCompleted: true),
      const TrackingStep(title: 'Out for Delivery', isCompleted: false),
      const TrackingStep(title: 'Delivered', isCompleted: false),
    ];

    switch (status) {
      case OrderStatus.delivered:
        return steps
            .map((step) => TrackingStep(
                title: step.title,
                description: step.description,
                timestamp: step.timestamp,
                isCompleted: true,
                isCurrent: false))
            .toList();
      case OrderStatus.dispatched:
      case OrderStatus.outForDelivery:
        return steps
            .map((step) => TrackingStep(
                title: step.title,
                description: step.description,
                timestamp: step.timestamp,
                isCompleted: step.title != 'Out for Delivery' &&
                    step.title != 'Delivered',
                isCurrent: step.title == 'Dispatched' ||
                    step.title == 'Out for Delivery'))
            .toList();
      case OrderStatus.printing:
        return steps
            .map((step) => TrackingStep(
                title: step.title,
                description: step.description,
                timestamp: step.timestamp,
                isCompleted: [
                  'Order Confirmed',
                  'Design Approved',
                  'Printing in Progress'
                ].contains(step.title),
                isCurrent: step.title == 'Printing in Progress'))
            .toList();
      case OrderStatus.cancelled:
        return [
          const TrackingStep(
              title: 'Cancelled', isCompleted: true, isCurrent: true)
        ];
      default:
        return steps
            .map((step) => TrackingStep(
                title: step.title,
                description: step.description,
                timestamp: step.timestamp,
                isCompleted: step.title == 'Order Confirmed' ||
                    step.title == 'Design Approved',
                isCurrent: step.title == 'Order Confirmed'))
            .toList();
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static List<int> _intList(dynamic value) {
    if (value is List) {
      return value.map((item) => _toInt(item) ?? 0).toList();
    }
    return const [];
  }

  static OrderStatus _orderStatusFromText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'design_review':
      case 'designapproved':
        return OrderStatus.designApproved;
      case 'printing':
        return OrderStatus.printing;
      case 'quality_check':
        return OrderStatus.qualityCheck;
      case 'shipped':
      case 'dispatched':
        return OrderStatus.dispatched;
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}
