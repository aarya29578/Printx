class AnalyticsService {
  static void logEvent(String name, {Map<String, dynamic>? parameters}) {
    // In production, integrate with Firebase Analytics or similar
    // For now, just no-op for mock
  }

  static void logScreen(String screenName) {
    logEvent('screen_view', parameters: {'screen_name': screenName});
  }

  static void logProductView(String productId, String productName) {
    logEvent('view_item', parameters: {
      'item_id': productId,
      'item_name': productName,
    });
  }

  static void logAddToCart(String productId, int price) {
    logEvent('add_to_cart', parameters: {
      'item_id': productId,
      'price': price,
    });
  }

  static void logPurchase(String orderId, int total) {
    logEvent('purchase', parameters: {
      'order_id': orderId,
      'value': total,
      'currency': 'INR',
    });
  }

  static void logSearch(String query) {
    logEvent('search', parameters: {'search_term': query});
  }

  static void logLogin(String method) {
    logEvent('login', parameters: {'method': method});
  }

  static void logSignUp(String method) {
    logEvent('sign_up', parameters: {'method': method});
  }
}
