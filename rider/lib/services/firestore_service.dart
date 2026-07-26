import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import '../core/constants/api_constants.dart';
import '../data/models/order_model.dart';

class FirestoreService {
  FirestoreService._();

  static final fs.FirebaseFirestore _db = fs.FirebaseFirestore.instance;

  static fs.CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');

  static fs.CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  // ── Rider Orders — server-side filtered ────────────────────────────────────

  /// Real-time stream of ALL orders assigned to this rider (all statuses).
  static Stream<List<Order>> watchRiderOrders({required String riderId}) {
    return _orders
        .where('assignedRiderId', isEqualTo: riderId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => _orderFromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Real-time stream of a single order document (for live detail screen).
  static Stream<Order> watchOrderById({required String orderId}) {
    return _orders.doc(orderId).snapshots().map((snap) {
      if (!snap.exists) throw StateError('Order not found: $orderId');
      return _orderFromMap(snap.id, snap.data()!);
    });
  }

  // ── Status Updates ─────────────────────────────────────────────────────────

  /// Rider accepts assignment → status becomes 'picked_up'.
  /// Only valid if current status is 'assigned' or 'dispatched'.
  static Future<void> markPickedUp({required String orderId}) async {
    await _orders.doc(orderId).update({
      'status': 'picked_up',
      'pickedUpAt': fs.FieldValue.serverTimestamp(),
      'updatedAt': fs.FieldValue.serverTimestamp(),
    });
  }

  /// Rider starts delivery → status becomes 'out_for_delivery'.
  static Future<void> markOutForDelivery({required String orderId}) async {
    await _orders.doc(orderId).update({
      'status': 'out_for_delivery',
      'updatedAt': fs.FieldValue.serverTimestamp(),
    });
  }

  /// Rider confirms delivery → status becomes 'delivered'.
  static Future<void> markDelivered({required String orderId}) async {
    await _orders.doc(orderId).update({
      'status': 'delivered',
      'deliveredAt': fs.FieldValue.serverTimestamp(),
      'updatedAt': fs.FieldValue.serverTimestamp(),
    });
  }

  /// Generic status update (for any status string).
  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _orders.doc(orderId).update({
      'status': status,
      'updatedAt': fs.FieldValue.serverTimestamp(),
    });
  }

  // ── Online status ─────────────────────────────────────��────────────────────

  /// Toggle rider online/offline status. Visible to Admin in real-time.
  static Future<void> setOnlineStatus({
    required String riderId,
    required bool online,
  }) async {
    await _users.doc(riderId).update({
      'online': online,
      'lastSeen': fs.FieldValue.serverTimestamp(),
    });
  }

  // ── User lookup ────────────────────────────────────────────────────────────

  /// Fetch user document for phone/address lookup.
  static Future<Map<String, dynamic>?> fetchUser({
    required String userId,
  }) async {
    final snap = await _users.doc(userId).get();
    return snap.exists ? snap.data() : null;
  }

  // ── Dashboard stats ────────────────────────────────────────────────────────

  /// Count today's deliveries by status from an already-fetched list.
  static Map<String, int> computeDailyStats(List<Order> orders) {
    final now = DateTime.now();
    final todayOrders = orders.where((o) {
      return o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day;
    }).toList();

    int assigned = 0, pickedUp = 0, outForDelivery = 0, delivered = 0, cancelled = 0;
    for (final o in todayOrders) {
      switch (o.status) {
        case OrderStatus.assigned:
          assigned++;
          break;
        case OrderStatus.pickedUp:
          pickedUp++;
          break;
        case OrderStatus.outForDelivery:
          outForDelivery++;
          break;
        case OrderStatus.delivered:
          delivered++;
          break;
        case OrderStatus.cancelled:
          cancelled++;
          break;
        default:
          break;
      }
    }
    return {
      'assigned': assigned,
      'pickedUp': pickedUp,
      'outForDelivery': outForDelivery,
      'delivered': delivered,
      'cancelled': cancelled,
      'total': todayOrders.length,
    };
  }

  // ── Parsers ────────────────────────────────────────────────────────────────

  static Order _orderFromMap(String id, Map<String, dynamic> data) {
    final statusText = (data['status'] as String?) ?? 'pending';
    final status = _statusFromText(statusText);

    final items = (data['items'] as List?)?.whereType<Map>().toList() ?? [];
    final orderItems = items.map((e) {
      final map = e.cast<String, dynamic>();
      return OrderItem(
        productId: (map['productId'] as String?) ?? '',
        productName: (map['productName'] as String?) ?? '',
        productImage: (map['productImage'] as String?) ??
            ApiConstants.productImage(1),
        quantity: (map['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (map['price'] as num?)?.toInt() ?? 0,
        totalPrice: ((map['price'] as num?)?.toInt() ?? 0) *
            ((map['quantity'] as num?)?.toInt() ?? 1),
        specs: _specsFromMap(size: map['size'], finish: map['finish']),
        customDesignUrl: map['customDesignUrl'] as String?,
        customDesignFileName: map['customDesignFileName'] as String?,
        customerInstructions: (map['customerInstructions'] as String?) ?? '',
        vendorId: map['vendorId'] as String?,
      );
    }).toList();

    final total = (data['totalAmount'] as num?)?.toInt() ?? 0;
    final createdAt =
        (data['createdAt'] as fs.Timestamp?)?.toDate() ?? DateTime.now();
    final pickedUpAt =
        (data['pickedUpAt'] as fs.Timestamp?)?.toDate();
    final deliveredAt =
        (data['deliveredAt'] as fs.Timestamp?)?.toDate();

    return Order(
      id: id,
      orderNumber: (data['orderId'] as String?) ?? id,
      items: orderItems.isEmpty
          ? [
              OrderItem(
                productId: '',
                productName: 'Unknown Product',
                productImage: ApiConstants.productImage(1),
                quantity: 1,
                unitPrice: 0,
                totalPrice: 0,
              ),
            ]
          : orderItems,
      subtotal: total,
      discount: 0,
      deliveryCharge: 0,
      gst: 0,
      total: total,
      status: status,
      createdAt: createdAt,
      deliveryAddress: (data['deliveryAddress'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? '',
      userEmail: (data['userEmail'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      customerPhone: (data['customerPhone'] as String?) ?? '',
      assignedRiderId: data['assignedRiderId'] as String?,
      assignedRiderName: data['assignedRiderName'] as String?,
      pickedUpAt: pickedUpAt,
      deliveredAt: deliveredAt,
      vendorName: data['vendorName'] as String?,
      vendorAddress: data['vendorAddress'] as String?,
    );
  }

  static String? _specsFromMap({dynamic size, dynamic finish}) {
    final s = size?.toString();
    final f = finish?.toString();
    if (s == null && f == null) return null;
    if (s != null && f != null) return '$s · $f';
    return s ?? f;
  }

  static OrderStatus _statusFromText(String status) {
    return switch (status.toLowerCase()) {
      'confirmed' => OrderStatus.confirmed,
      'design_approved' || 'designapproved' || 'design_review' =>
        OrderStatus.designApproved,
      'printing' => OrderStatus.printing,
      'quality_check' => OrderStatus.qualityCheck,
      'shipped' || 'dispatched' => OrderStatus.dispatched,
      'assigned' => OrderStatus.assigned,
      'picked_up' || 'pickedup' => OrderStatus.pickedUp,
      'out_for_delivery' => OrderStatus.outForDelivery,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }
}
