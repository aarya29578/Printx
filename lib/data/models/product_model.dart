import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final List<String> imageUrls;
  final int basePrice;
  final int originalPrice;
  final double rating;
  final int reviewCount;
  final bool isBestseller;
  final List<String> finishes;
  final List<String> sizes;
  final String description;
  final int minQty;
  final List<String> tags;
  final List<int> quantities;
  final String? badge;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.basePrice,
    required this.originalPrice,
    required this.rating,
    required this.reviewCount,
    this.isBestseller = false,
    this.finishes = const [],
    this.sizes = const [],
    required this.description,
    this.minQty = 1,
    this.tags = const [],
    this.quantities = const [50, 100, 250, 500, 1000],
    this.badge,
  });

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? imageUrl,
    List<String>? imageUrls,
    int? basePrice,
    int? originalPrice,
    double? rating,
    int? reviewCount,
    bool? isBestseller,
    List<String>? finishes,
    List<String>? sizes,
    String? description,
    int? minQty,
    List<String>? tags,
    List<int>? quantities,
    String? badge,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      basePrice: basePrice ?? this.basePrice,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isBestseller: isBestseller ?? this.isBestseller,
      finishes: finishes ?? this.finishes,
      sizes: sizes ?? this.sizes,
      description: description ?? this.description,
      minQty: minQty ?? this.minQty,
      tags: tags ?? this.tags,
      quantities: quantities ?? this.quantities,
      badge: badge ?? this.badge,
    );
  }

  @override
  List<Object?> get props => [id];
}
