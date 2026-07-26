import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final int productCount;
  final int colorIndex;
  final String imageUrl;
  final String? description;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.productCount,
    required this.colorIndex,
    required this.imageUrl,
    this.description,
  });

  @override
  List<Object?> get props => [id];
}
