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

  static String formatDecimal(num amount) =>
      _inrFormatDecimal.format(amount);

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

  static int discountPercent(num original, num discounted) {
    return (((original - discounted) / original) * 100).round();
  }
}
