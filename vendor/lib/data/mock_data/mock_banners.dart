import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../../core/constants/api_constants.dart';

class MockBanners {
  static final List<BannerModel> all = [
    BannerModel(
      id: 'b001',
      title: 'Visiting Cards\nfrom ₹149',
      subtitle: 'Premium quality, 2-day delivery',
      ctaText: 'Order Now',
      primaryColor: const Color(0xFF4F46E5),
      secondaryColor: const Color(0xFF7C3AED),
      imageUrl: ApiConstants.bannerImage(1),
      position: 1,
      offerLabel: '🔥 Trending',
      route: '/products/visiting-cards',
    ),
    BannerModel(
      id: 'b002',
      title: 'Custom T-Shirts\n42% OFF',
      subtitle: 'Free delivery on orders above ₹499',
      ctaText: 'Shop Now',
      primaryColor: const Color(0xFF06B6D4),
      secondaryColor: const Color(0xFF3B82F6),
      imageUrl: ApiConstants.bannerImage(2),
      position: 2,
      offerLabel: '✨ Limited Offer',
      route: '/products/t-shirts',
    ),
    BannerModel(
      id: 'b003',
      title: 'Wedding Stationery\nStarts ₹899',
      subtitle: 'Gold foil, embossing & more',
      ctaText: 'Explore',
      primaryColor: const Color(0xFFF59E0B),
      secondaryColor: const Color(0xFFEF4444),
      imageUrl: ApiConstants.bannerImage(3),
      position: 3,
      offerLabel: '💍 New Collection',
      route: '/products/wedding',
    ),
  ];
}

class MockCoupons {
  static final List<CouponModel> all = [
    CouponModel(
      id: 'c001',
      code: 'FIRST50',
      title: 'First Order Discount',
      description: '₹50 off on your first order',
      discountAmount: 50,
      isPercentage: false,
      minOrderAmount: 299,
      expiry: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
    ),
    CouponModel(
      id: 'c002',
      code: 'SAVE20',
      title: '20% Flat Discount',
      description: '20% off on orders above ₹999',
      discountAmount: 20,
      isPercentage: true,
      minOrderAmount: 999,
      expiry: DateTime.now().add(const Duration(days: 7)),
      isActive: true,
    ),
    CouponModel(
      id: 'c003',
      code: 'BULK500',
      title: 'Bulk Order Savings',
      description: '₹500 off on orders above ₹2499',
      discountAmount: 500,
      isPercentage: false,
      minOrderAmount: 2499,
      expiry: DateTime.now().add(const Duration(days: 15)),
      isActive: true,
    ),
    CouponModel(
      id: 'c004',
      code: 'NEWUSER',
      title: 'Welcome Coupon',
      description: 'Extra 15% for new users',
      discountAmount: 15,
      isPercentage: true,
      minOrderAmount: 499,
      expiry: DateTime.now().add(const Duration(days: 90)),
      isActive: true,
    ),
  ];
}
