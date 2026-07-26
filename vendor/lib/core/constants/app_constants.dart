class AppConstants {
  AppConstants._();

  static const String appName = 'PrintX';
  static const String appTagline = 'Your Brand. Beautifully Printed.';
  static const String appVersion = '1.0.0';

  // SharedPreferences keys
  static const String keyOnboardingDone = 'onboarding_done';
  static const String keyThemeMode = 'theme_mode';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserPhone = 'user_phone';
  static const String keyRecentSearches = 'recent_searches';
  static const String keyCartItems = 'cart_items';
  static const String keySavedDesigns = 'saved_designs';
  static const String keyWishlist = 'wishlist';

  // GST rate
  static const double gstRate = 0.18;

  // Delivery charges
  static const double standardDeliveryCharge = 0;
  static const double expressDeliveryCharge = 99;
  static const double sameDayDeliveryCharge = 199;

  // Free delivery threshold
  static const double freeDeliveryThreshold = 499;

  // OTP config
  static const int otpLength = 6;
  static const int otpResendSeconds = 30;

  // Pagination
  static const int pageSize = 20;

  // Image quality
  static const int imageQuality = 85;
  static const int maxImageSizeMb = 10;

  // Canvas sizes (in points)
  static const double businessCardWidth = 3.5;
  static const double businessCardHeight = 2.0;

  // Mock phone number prefix
  static const String phonePrefix = '+91';

  // Support
  static const String supportEmail = 'support@printx.in';
  static const String supportPhone = '+91 80 4000 5000';
}
