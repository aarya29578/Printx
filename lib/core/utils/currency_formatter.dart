import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static String format(num amount) => _inrFormat.format(amount);

  static String formatDecimal(num amount) => _inrFormatDecimal.format(amount);

  static String formatCompact(num amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }

  static String perUnit(num price, int qty, String unit) {
    final perUnit = price / qty;
    return '${_inrFormatDecimal.format(perUnit)} per $unit';
  }

  static String savings(num original, num discounted) {
    final saved = original - discounted;
    final percent = ((saved / original) * 100).round();
    return 'Save ${format(saved)} ($percent% off)';
  }

  static int discountPercent(num? originalPrice, num? salePrice) {
    print('DISCOUNT DEBUG: originalPrice=$originalPrice salePrice=$salePrice');

    final original = (originalPrice is num) ? originalPrice : null;
    final discounted = (salePrice is num) ? salePrice : null;

    if (original == null || discounted == null) {
      print('DISCOUNT RESULT: 0');
      return 0;
    }

    final originalVal = original.toDouble();
    final discountedVal = discounted.toDouble();

    // Defensive checks: null/0/negative/NaN/Infinity should return 0.
    if (originalVal <= 0 ||
        !originalVal.isFinite ||
        !discountedVal.isFinite ||
        originalVal.isNaN ||
        discountedVal.isNaN) {
      print('DISCOUNT RESULT: 0');
      return 0;
    }

    final diff = originalVal - discountedVal;
    final rawPercent = (diff / originalVal) * 100;

    if (!rawPercent.isFinite || rawPercent.isNaN) {
      print('DISCOUNT RESULT: 0');
      return 0;
    }

    // Defensive checks before converting to int.
    final rounded = rawPercent.round();
    if (rounded.isNaN || rounded.isInfinite) {
      print('DISCOUNT RESULT: 0');
      return 0;
    }

    final discount = rounded < 0 ? 0 : rounded;
    print('DISCOUNT RESULT: $discount');
    return discount;
  }
}
