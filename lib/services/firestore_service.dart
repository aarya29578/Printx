import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../data/mock_data/mock_banners.dart';
import '../data/mock_data/mock_categories.dart';
import '../data/models/app_models.dart';
import '../data/models/category_model.dart';
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Products / Categories / Banners
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<List<Product>> fetchProducts() async {
    try {
      final snapshot = await products.get();
      print('📦 [PRODUCT FETCH] count=${snapshot.docs.length}');
      print(
          '🗄️ [FIRESTORE PRODUCTS raw docs] ${snapshot.docs.map((d) => d.id).toList()}');

      if (snapshot.docs.isEmpty) return <Product>[];
      return snapshot.docs
          .map((doc) => _productFromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('❌ [PRODUCT FETCH] error=$e');
      return <Product>[];
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

  static Stream<List<Product>> watchProducts() {
    return products.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => _productFromMap(doc.id, doc.data()))
              .toList(),
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

  // ─────────────────────────────────────────────────────────────────────────────
  // Orders (NO mock/fallback)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Reads ONLY orders belonging to [userId].
  static Future<List<Order>> fetchOrdersForUser({
    required String userId,
  }) async {
    final queryPath = "orders.where(userId==${userId}) orderBy(createdAt desc)";
    print('📦 [ORDER FETCH] start userId=$userId query=$queryPath');

    final query = await orders.where('userId', isEqualTo: userId).get();

    final docIds = query.docs.map((d) => d.id).toList();
    final result =
        query.docs.map((doc) => _orderFromMap(doc.id, doc.data())).toList();

    print(
        '📦 [ORDER FETCH] returned docs=${docIds.length} orderModels=${result.length} docIds=$docIds');
    return result;
  }

  /// Fetch a single order document by its Firestore doc id.
  static Future<Order> fetchOrderById({
    required String orderId,
  }) async {
    print('FETCH ORDER orderId=$orderId');
    final ref = orders.doc(orderId);
    print('FETCH ORDER path=${ref.path}');
    final snap = await ref.get();
    final exists = snap.exists;
    print('FETCH ORDER exists=$exists');
    if (!exists) {
      throw StateError('Order not found: $orderId');
    }
    final data = snap.data() as Map<String, dynamic>;
    final order = _orderFromMap(snap.id, data);
    print(
        'FETCH ORDER returned.id=${order.id} status=${order.status} items=${order.items.length}');
    return order;
  }

  /// Writes a real Firestore order document following the required schema.
  static Future<String> createOrder({
    required String orderId,
    required String userId,
    required String userName,
    required String userEmail,
    required String deliveryAddress,
    required List<Map<String, dynamic>> items,
    required int totalAmount,
  }) async {
    final orderRef = orders.doc();
    final createdOrderId = orderRef.id;

    final collectionPath = orderRef.parent.path;

    final payload = <String, dynamic>{
      'orderId': createdOrderId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'createdAt': firestore.FieldValue.serverTimestamp(),
      'status': 'pending',
      'deliveryAddress': deliveryAddress,
      'items': items,
      'totalAmount': totalAmount,
    };

    print('🧾 [ORDER CREATE] collectionPath=$collectionPath');
    print('🧾 [ORDER CREATE] documentId=$createdOrderId');
    print('🧾 [ORDER CREATE] userId=$userId');
    print('🧾 [ORDER CREATE] payload=$payload');

    await orderRef.set(payload);

    // FIRESTORE VERIFY (immediately after write)
    final createdSnap = await orderRef.get();
    final exists = createdSnap.exists;
    final returnedData = exists ? createdSnap.data() : null;

    print('🧾 [FIRESTORE VERIFY] path=${orderRef.path} exists=$exists');
    print('🧾 [FIRESTORE VERIFY] returnedData=$returnedData');

    return createdOrderId;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Legacy adapter (pre-existing UI may still call fetchOrders()).
  // We intentionally fail to prevent cross-user / mock visibility.
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<List<Order>> fetchOrders() {
    throw UnimplementedError(
        'fetchOrders() is not supported. Use fetchOrdersForUser(userId) to avoid cross-user order visibility.');
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Order parsing (supports ONLY schema created by createOrder)
  // ─────────────────────────────────────────────────────────────────────────────

  static Order _orderFromMap(String id, Map<String, dynamic> data) {
    final statusText = (data['status'] as String?) ?? 'pending';

    final status = _orderStatusFromText(statusText);

    final items = (data['items'] as List?)?.whereType<Map>().toList() ?? [];

    final orderItems = items.map((e) {
      final map = e.cast<String, dynamic>();
      return OrderItem(
        productId: (map['productId'] as String?) ?? '',
        productName: (map['productName'] as String?) ?? '',
        productImage:
            (map['productImage'] as String?) ?? ApiConstants.productImage(1),
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (map['price'] as num?)?.toInt() ?? 0,
        totalPrice: ((map['price'] as num?)?.toInt() ?? 0) *
            ((map['quantity'] as num?)?.toInt() ?? 1),
        specs: _specsFromSizeFinish(size: map['size'], finish: map['finish']),
        customDesignUrl: map['customDesignUrl'] as String?,
        customDesignFileName: map['customDesignFileName'] as String?,
        customerInstructions: (map['customerInstructions'] as String?) ?? '',
      );
    }).toList();

    final totalAmount = (data['totalAmount'] as num?)?.toInt() ?? 0;

    final createdAt =
        (data['createdAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now();

    return Order(
      id: id,
      orderNumber: (data['orderId'] as String?) ?? id,
      items: orderItems.isEmpty
          ? [
              OrderItem(
                productId: '',
                productName: '',
                productImage: ApiConstants.productImage(1),
                quantity: 1,
                unitPrice: 0,
                totalPrice: 0,
              ),
            ]
          : orderItems,
      subtotal: totalAmount,
      discount: 0,
      deliveryCharge: 0,
      gst: 0,
      total: totalAmount,
      status: status,
      createdAt: createdAt,
      estimatedDelivery: null,
      trackingSteps: const [],
      deliveryAddress: (data['deliveryAddress'] as String?) ?? '',
      trackingId: null,
    );
  }

  static String? _specsFromSizeFinish({dynamic size, dynamic finish}) {
    final s = size?.toString();
    final f = finish?.toString();
    if (s == null && f == null) return null;
    if (s != null && f != null) return '$s · $f';
    return (s ?? f);
  }

  static OrderStatus _orderStatusFromText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'design_approved':
      case 'designapproved':
      case 'design_review':
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
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Product _productFromMap(String id, Map<String, dynamic> data) {
    final imageUrl =
        (data['imageUrl'] as String?) ?? ApiConstants.productImage(1);

    final sizes = data.containsKey('sizes')
        ? _stringList(data['sizes'])
        : _stringList(_csvToList(data['sizesText']));

    final finishes = data.containsKey('finishes')
        ? _stringList(data['finishes'])
        : _stringList(_csvToList(data['finishesText']));

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
      finishes: finishes,
      sizes: sizes,
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

  static List<dynamic> _csvToList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value;
    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) return const [];
      return raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<String> _stringList(dynamic value) {
    // Supports Firestore values saved as either:
    // - array of strings
    // - comma-separated string (older docs / exports / migrations)
    if (value is List) {
      return value
          .map((item) => item.toString())
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String) {
      final raw = value.trim();
      if (raw.isEmpty) return const [];
      return raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<int> _intList(dynamic value) {
    if (value is List) {
      return value.map((item) => _toInt(item) ?? 0).toList();
    }
    return const [];
  }
}
