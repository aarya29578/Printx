/// Category utilities for mapping between IDs, names, and display information
///
/// Maps Firestore category IDs (doc IDs) to human-readable names and product units
/// Supports both mock data (category names) and Firestore data (category IDs)

class CategoryUtils {
  /// Map of category IDs to display names
  static const Map<String, String> categoryIdToName = {
    'CAT001': 'Visiting Cards',
    'CAT002': 'T-Shirts & Apparel',
    'CAT003': 'Banners & Signage',
    'CAT004': 'Drinkware',
    'CAT005': 'Flyers & Brochures',
    'CAT006': 'Stationery',
    'CAT007': 'Office Essentials',
    'CAT008': 'Stickers & Labels',
    'CAT009': 'Invitations',
    'CAT010': 'Bags & Accessories',
    'CAT011': 'Gifts',
    'CAT012': 'Photo Prints',
    // Add custom categories dynamically
    'fr': 'French Category', // Example: user-created category
  };

  /// Map of category IDs to product unit type
  /// 'cards': displays quantity as "N cards" (e.g., for visiting cards)
  /// 'pcs': displays quantity as "N pcs" (default for most products)
  static const Map<String, String> categoryIdToUnit = {
    'CAT001': 'cards', // Visiting Cards
    'CAT008': 'labels', // Stickers & Labels
    // All others default to 'pcs'
  };

  /// Get display name for a category by ID
  /// Falls back to the ID itself if not found (supports custom categories)
  static String getDisplayName(String categoryId) {
    return categoryIdToName[categoryId] ?? categoryId;
  }

  /// Get unit type for displaying quantity in cart
  /// Returns 'cards', 'labels', or 'pcs' (default)
  static String getUnitType(String categoryId) {
    return categoryIdToUnit[categoryId] ?? 'pcs';
  }

  /// Check if category uses "cards" unit
  static bool isCardCategory(String categoryId) {
    return getUnitType(categoryId) == 'cards';
  }

  /// Get specs string for cart item
  /// Example: "Matte · 100 cards" or "Glossy · 250 pcs"
  static String getCartSpecs(String categoryId, String? finish, int quantity) {
    final unitType = getUnitType(categoryId);
    final finishStr = finish ?? 'Standard';
    return '$finishStr · $quantity $unitType';
  }

  /// Convert category slug/name from mock data to potential category ID
  /// Used for migrating mock data references to Firestore IDs
  static String? migrateSlugToId(String slug) {
    // Reverse mapping: common mock slugs to category IDs
    const mockToId = {
      'visiting-cards': 'CAT001',
      'visiting_cards': 'CAT001',
      't-shirts': 'CAT002',
      'tshirts': 'CAT002',
      't-shirts-apparel': 'CAT002',
      'banners': 'CAT003',
      'signage': 'CAT003',
      'drinkware': 'CAT004',
      'flyers': 'CAT005',
      'brochures': 'CAT005',
      'stationery': 'CAT006',
      'office': 'CAT007',
      'stickers': 'CAT008',
      'labels': 'CAT008',
      'invitations': 'CAT009',
      'bags': 'CAT010',
      'accessories': 'CAT010',
      'gifts': 'CAT011',
      'photos': 'CAT012',
    };

    return mockToId[slug.toLowerCase()];
  }

  /// Normalize category reference (handle both mock data slugs and Firestore IDs)
  static String normalizeCategoryReference(String input) {
    // If it looks like a Firestore ID (starts with CAT or is lowercase custom ID), return as-is
    if (input.startsWith('CAT') || input == input.toLowerCase()) {
      return input;
    }
    // Otherwise, might be from mock data - try to migrate
    return migrateSlugToId(input) ?? input;
  }
}
