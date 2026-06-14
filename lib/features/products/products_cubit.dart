import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/app_models.dart';
import '../../data/mock_data/mock_banners.dart';
import '../../services/firestore_service.dart';

// ─── Home ─────────────────────────────────────────────────────────────────────

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<BannerModel> banners;
  final List<Category> categories;
  final List<Product> trending;
  final List<CouponModel> coupons;
  final int notificationCount;

  const HomeLoaded({
    required this.banners,
    required this.categories,
    required this.trending,
    required this.coupons,
    this.notificationCount = 2,
  });

  @override
  List<Object?> get props =>
      [banners, categories, trending, coupons, notificationCount];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeLoading());

  StreamSubscription<List<Product>>? _productsSub;

  Future<void> load() async {
    emit(HomeLoading());
    await Future.delayed(const Duration(milliseconds: 300));
    final banners = await FirestoreService.fetchBanners();
    final categories = await FirestoreService.fetchCategories();
    final trending = await FirestoreService.fetchProducts();
    emit(HomeLoaded(
      banners: banners,
      categories: categories.take(8).toList(),
      trending: trending.take(6).toList(),
      coupons: MockCoupons.all,
    ));

    await _productsSub?.cancel();
    _productsSub = FirestoreService.watchProducts().listen((items) {
      final current = state;
      if (current is! HomeLoaded) return;
      emit(HomeLoaded(
        banners: current.banners,
        categories: current.categories,
        trending: items.take(6).toList(),
        coupons: current.coupons,
        notificationCount: current.notificationCount,
      ));
    });
  }

  @override
  Future<void> close() async {
    await _productsSub?.cancel();
    return super.close();
  }
}

// ─── Products ─────────────────────────────────────────────────────────────────

abstract class ProductsState extends Equatable {
  const ProductsState();
  @override
  List<Object?> get props => [];
}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final List<Product> filtered;
  final String? categoryId;
  final String sortBy;
  final List<String> selectedFinishes;

  const ProductsLoaded({
    required this.products,
    required this.filtered,
    this.categoryId,
    this.sortBy = 'popular',
    this.selectedFinishes = const [],
  });

  @override
  List<Object?> get props => [products, filtered, categoryId, sortBy];
}

class ProductsError extends ProductsState {
  final String message;
  const ProductsError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit() : super(ProductsLoading());

  StreamSubscription<List<Product>>? _productsSub;

  Future<void> loadByCategory(String categoryId) async {
    emit(ProductsLoading());
    print('\n🔄 [PRODUCTSCUBIT] loadByCategory(categoryId=$categoryId)');
    await Future.delayed(const Duration(milliseconds: 200));
    await _productsSub?.cancel();
    _productsSub = FirestoreService.watchProducts().listen((allProducts) {
      print(
          '  📥 Received ${allProducts.length} total products from Firestore');
      final products = categoryId == 'all'
          ? allProducts
          : allProducts.where((item) => item.category == categoryId).toList();
      print(
          '  🔎 After filtering by categoryId=$categoryId: ${products.length} products');
      if (products.isNotEmpty) {
        print('    First 5 filtered products:');
        for (final p in products.take(5)) {
          print('      - id=${p.id}, name=${p.name}, category=${p.category}');
        }
      } else {
        print('    ❌ No products match categoryId=$categoryId');
        print(
            '    Product.category values in allProducts: ${allProducts.map((p) => p.category).toSet().toList()}');
      }
      emit(ProductsLoaded(
        products: products,
        filtered: products,
        categoryId: categoryId,
      ));
    });
  }

  void sortProducts(String sortBy) {
    final current = state;
    if (current is! ProductsLoaded) return;
    final sorted = [...current.filtered];
    switch (sortBy) {
      case 'price_asc':
        sorted.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.basePrice.compareTo(a.basePrice));
        break;
      case 'rating':
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        sorted.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    }
    emit(ProductsLoaded(
      products: current.products,
      filtered: sorted,
      categoryId: current.categoryId,
      sortBy: sortBy,
    ));
  }

  @override
  Future<void> close() async {
    await _productsSub?.cancel();
    return super.close();
  }
}

// ─── Product Detail ───────────────────────────────────────────────────────────

abstract class ProductDetailState extends Equatable {
  const ProductDetailState();
  @override
  List<Object?> get props => [];
}

class ProductDetailInitial extends ProductDetailState {}

class ProductDetailLoaded extends ProductDetailState {
  final Product product;
  final int selectedQty;
  final String selectedFinish;
  final String selectedSize;
  final int calculatedPrice;
  final bool isFavorite;
  final int currentImageIndex;

  const ProductDetailLoaded({
    required this.product,
    required this.selectedQty,
    required this.selectedFinish,
    required this.selectedSize,
    required this.calculatedPrice,
    this.isFavorite = false,
    this.currentImageIndex = 0,
  });

  ProductDetailLoaded copyWith({
    Product? product,
    int? selectedQty,
    String? selectedFinish,
    String? selectedSize,
    int? calculatedPrice,
    bool? isFavorite,
    int? currentImageIndex,
  }) {
    return ProductDetailLoaded(
      product: product ?? this.product,
      selectedQty: selectedQty ?? this.selectedQty,
      selectedFinish: selectedFinish ?? this.selectedFinish,
      selectedSize: selectedSize ?? this.selectedSize,
      calculatedPrice: calculatedPrice ?? this.calculatedPrice,
      isFavorite: isFavorite ?? this.isFavorite,
      currentImageIndex: currentImageIndex ?? this.currentImageIndex,
    );
  }

  @override
  List<Object?> get props => [
        product,
        selectedQty,
        selectedFinish,
        selectedSize,
        calculatedPrice,
        isFavorite
      ];
}

class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit() : super(ProductDetailInitial());

  void loadProduct(Product product) {
    // Prevent RangeError if quantities length is 1 (valid indices: 0 only)
    final quantities = product.quantities;
    final hasSecondQty = quantities.length > 1;
    final selectedQty = hasSecondQty
        ? quantities[1]
        : (quantities.isNotEmpty ? quantities[0] : 100);

    emit(ProductDetailLoaded(
      product: product,
      selectedQty: selectedQty,
      selectedFinish: product.finishes.isNotEmpty ? product.finishes[0] : '',
      selectedSize: product.sizes.isNotEmpty ? product.sizes[0] : '',
      calculatedPrice: product.basePrice,
    ));
  }

  Future<void> loadProductById(String productId) async {
    print('\n🔍 [ProductDetailCubit] loadProductById(productId=$productId)');
    final all = await FirestoreService.fetchProducts();
    final product = all.firstWhere(
      (p) => p.id == productId,
      orElse: () => all.first,
    );
    print(
        '  ✅ [ProductDetailCubit] Loaded product id=${product.id} name=${product.name}');
    loadProduct(product);
  }

  void selectQty(int qty) {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    emit(current.copyWith(selectedQty: qty));
  }

  void selectFinish(String finish) {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    emit(current.copyWith(selectedFinish: finish));
  }

  void selectSize(String size) {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    emit(current.copyWith(selectedSize: size));
  }

  void toggleFavorite() {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    emit(current.copyWith(isFavorite: !current.isFavorite));
  }

  void setImageIndex(int idx) {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    emit(current.copyWith(currentImageIndex: idx));
  }
}
