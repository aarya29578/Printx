import '../models/app_models.dart';
import '../../core/constants/api_constants.dart';

class MockReviews {
  static final List<ReviewModel> all = [
    ReviewModel(
      id: 'r001',
      userId: 'u001',
      userName: 'Priya Sharma',
      userAvatar: ApiConstants.avatarImage(1),
      productId: 'p001',
      rating: 5.0,
      comment:
          'Absolutely love the quality! The matte finish is gorgeous and the printing is super sharp. Got compliments from everyone at the conference. Will definitely order again!',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isVerifiedPurchase: true,
    ),
    ReviewModel(
      id: 'r002',
      userId: 'u002',
      userName: 'Rahul Gupta',
      userAvatar: ApiConstants.avatarImage(2),
      productId: 'p001',
      rating: 4.5,
      comment:
          'Really impressed with the quality for the price. Fast delivery too — got my cards in 2 days. The colors are vibrant and exactly match my Canva design. Highly recommend!',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      isVerifiedPurchase: true,
    ),
    ReviewModel(
      id: 'r003',
      userId: 'u003',
      userName: 'Anjali Mehta',
      userAvatar: ApiConstants.avatarImage(3),
      productId: 'p005',
      rating: 5.0,
      comment:
          'The mug came out perfect! Gifted it to my boss for his birthday and he loved it. The print quality is excellent, colors are spot on, and it feels premium.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      isVerifiedPurchase: true,
    ),
    ReviewModel(
      id: 'r004',
      userId: 'u004',
      userName: 'Vikram Singh',
      userAvatar: ApiConstants.avatarImage(4),
      productId: 'p003',
      rating: 4.0,
      comment:
          'Good quality T-shirts. Ordered 25 for our startup team and everyone loved them. The digital print is crisp. Slightly disappointed with one shirt\'s sizing but overall great.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      isVerifiedPurchase: true,
    ),
    ReviewModel(
      id: 'r005',
      userId: 'u005',
      userName: 'Sneha Patel',
      userAvatar: ApiConstants.avatarImage(5),
      productId: 'p010',
      rating: 5.0,
      comment:
          'The Spot UV cards are absolutely stunning! The contrast between matte and glossy is incredible. My clients always ask about them. 100% worth the premium price!',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isVerifiedPurchase: true,
    ),
    ReviewModel(
      id: 'r006',
      userId: 'u006',
      userName: 'Arjun Kumar',
      userAvatar: ApiConstants.avatarImage(6),
      productId: 'p008',
      rating: 4.5,
      comment:
          'Beautiful notebooks with our company logo. The hard cover looks very professional. Perfect for our client gifting program. Ordered 100 pieces and all came perfectly packed.',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      isVerifiedPurchase: true,
    ),
    ReviewModel(
      id: 'r007',
      userId: 'u007',
      userName: 'Divya Krishnan',
      userAvatar: ApiConstants.avatarImage(7),
      productId: 'p011',
      rating: 5.0,
      comment:
          'Our wedding invitations were beyond beautiful! The gold foil effect was exactly what I wanted. Got so many compliments from guests. Thank you PrintX for making our special day even more special!',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      isVerifiedPurchase: true,
    ),
    ReviewModel(
      id: 'r008',
      userId: 'u008',
      userName: 'Manish Agarwal',
      userAvatar: ApiConstants.avatarImage(8),
      productId: 'p004',
      rating: 4.0,
      comment:
          'Good quality standee, sturdy base. The print is sharp and vibrant. Arrived well packed. Only minor issue was a small dent on the base stand but the team replaced it quickly.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isVerifiedPurchase: true,
    ),
  ];

  static List<ReviewModel> getByProduct(String productId) {
    return all.where((r) => r.productId == productId).toList();
  }
}

class MockNotifications {
  static final List<NotificationModel> all = [
    NotificationModel(
      id: 'n001',
      title: 'Order Confirmed!',
      description: 'Your order #VPX-20492 for Visiting Cards has been confirmed.',
      type: NotificationType.order,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      route: '/order/ord001/track',
    ),
    NotificationModel(
      id: 'n002',
      title: '🎉 Printing Started',
      description: '#VPX-20492 is now in production at our Pune facility.',
      type: NotificationType.order,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      route: '/order/ord001/track',
    ),
    NotificationModel(
      id: 'n003',
      title: 'Limited Time: 20% OFF',
      description: 'Get 20% off on all T-shirts today only! Use code SAVE20.',
      type: NotificationType.offer,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
      route: '/products/t-shirts',
    ),
    NotificationModel(
      id: 'n004',
      title: 'Order Dispatched 🚚',
      description: '#VPX-19874 is on its way! Expected by tomorrow.',
      type: NotificationType.delivery,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      route: '/order/ord002/track',
    ),
    NotificationModel(
      id: 'n005',
      title: 'Order Delivered ✅',
      description: 'Your mugs from #VPX-18901 have been delivered. Rate your experience!',
      type: NotificationType.delivery,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n006',
      title: 'New Designs Available',
      description: '500+ new wedding card templates just added. Check them out!',
      type: NotificationType.offer,
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      isRead: true,
      route: '/categories',
    ),
    NotificationModel(
      id: 'n007',
      title: '₹100 Cashback Credited',
      description: 'Your referral bonus of ₹100 has been credited to your wallet.',
      type: NotificationType.system,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n008',
      title: 'Design Approval Required',
      description: 'Your design for order #VPX-19343 needs final approval before printing.',
      type: NotificationType.order,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n009',
      title: 'Flash Sale! 40% OFF',
      description: 'Mega sale on banners and standees for the next 24 hours only!',
      type: NotificationType.offer,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isRead: true,
      route: '/products/banners',
    ),
    NotificationModel(
      id: 'n010',
      title: 'Account Created 🎊',
      description: 'Welcome to PrintX! Use code NEWUSER for 15% off your first order.',
      type: NotificationType.system,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      isRead: true,
    ),
  ];
}
