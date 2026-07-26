class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.printx.in/v1';
  static const String imageBaseUrl = 'https://picsum.photos';
  static const String mockImageUrl = 'https://picsum.photos/seed';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

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
