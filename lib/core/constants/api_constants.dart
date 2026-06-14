class ApiConstants {
  ApiConstants._();

  // Base URLs (mock-ready, no real API calls)
  static const String baseUrl = 'https://api.printx.in/v1';
  static const String imageBaseUrl = 'https://picsum.photos';
  static const String mockImageUrl = 'https://picsum.photos/seed';

  // Endpoints
  static const String products = '/products';
  static const String categories = '/categories';
  static const String orders = '/orders';
  static const String cart = '/cart';
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String otpVerify = '/auth/otp/verify';
  static const String otpResend = '/auth/otp/resend';
  static const String profile = '/user/profile';
  static const String addresses = '/user/addresses';
  static const String designs = '/user/designs';
  static const String notifications = '/user/notifications';
  static const String coupons = '/coupons';
  static const String reviews = '/reviews';
  static const String search = '/search';

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Image sizes for picsum
  static const String productImageSize = '400/400';
  static const String categoryImageSize = '300/200';
  static const String bannerImageSize = '800/300';
  static const String thumbnailSize = '200/200';

  static String productImage(int seed) =>
      '$imageBaseUrl/seed/product_$seed/400/400';
  static String categoryImage(int seed) =>
      '$imageBaseUrl/seed/cat_$seed/300/200';
  static String bannerImage(int seed) =>
      '$imageBaseUrl/seed/banner_$seed/800/300';
  static String avatarImage(int seed) =>
      '$imageBaseUrl/seed/avatar_$seed/100/100';
}
