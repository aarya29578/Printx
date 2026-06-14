# RUNTIME PATH TRACE: Category "aayo" → No Products Found

## 1️⃣ CATEGORY CLICK
**File:** `lib/features/home/home_screen.dart:170` OR `lib/features/categories/categories_screen.dart:56`
```dart
onTap: () => context.push('/products/${cat.id}'),
```
**Values:**
- `cat.id` = "cat-1780725700997" (Firestore document ID)
- URL: `/products/cat-1780725700997`

---

## 2️⃣ ROUTE HANDLER
**File:** `lib/app.dart:260-278`
```dart
GoRoute(
  path: '/products/:categoryId',
  pageBuilder: (c, s) {
    final catId = s.pathParameters['categoryId'] ?? '';  // "cat-1780725700997"
    print('🔍 [ROUTE] Category clicked: categoryId=$catId');
    
    final category = Category(
      id: catId,                    // "cat-1780725700997"
      name: catId,                  // "cat-1780725700997" (will be updated)
      icon: 'tag',
      productCount: 0,
      colorIndex: 0,
      imageUrl: '',
      description: '',
    );
    return ProductListingScreen(category: category);
  },
),
```
**Values Passed:**
- `category.id` = "cat-1780725700997"
- `category.name` = "cat-1780725700997"

---

## 3️⃣ PRODUCTLISTINGSCREEN INIT
**File:** `lib/features/products/product_listing_screen.dart:28-39`
```dart
@override
void initState() {
  super.initState();
  _displayCategory = widget.category;
  
  // Load full category details from Firestore
  _loadCategoryDetails();
  
  // Load products filtered by category ID
  context.read<ProductsCubit>().loadByCategory(widget.category.id);
  //                                           ↓
  //                                   "cat-1780725700997"
}
```
**Call:** `loadByCategory("cat-1780725700997")`

---

## 4️⃣ LOADBYCATEGORY
**File:** `lib/features/products/products_cubit.dart:130-155`
```dart
Future<void> loadByCategory(String categoryId) async {  // "cat-1780725700997"
  emit(ProductsLoading());
  await Future.delayed(const Duration(milliseconds: 200));
  await _productsSub?.cancel();
  
  _productsSub = FirestoreService.watchProducts().listen((allProducts) {
    print('📦 [FIRESTORE] watchProducts() returned ${allProducts.length} products');
    
    final products = categoryId == 'all'
        ? allProducts
        : allProducts.where((item) => item.category == categoryId).toList();
        //                       ↓                        ↓
        //                  product.category      "cat-1780725700997"
    
    print('🔎 After filtering by categoryId=$categoryId: ${products.length} products');
    
    if (products.isEmpty) {
      print('❌ No products match categoryId=$categoryId');
      print('Product.category values in allProducts: ${allProducts.map((p) => p.category).toSet().toList()}');
    }
    
    emit(ProductsLoaded(
      products: products,
      filtered: products,
      categoryId: categoryId,
    ));
  });
}
```

---

## 5️⃣ WATCHPRODUCTS STREAM
**File:** `lib/services/firestore_service.dart:158-175`
```dart
static Stream<List<Product>> watchProducts() {
  return products.snapshots().map((snapshot) {
    final result = snapshot.docs.isEmpty
      ? MockProducts.all                          // ⚠️ FALLBACK TO MOCK
      : snapshot.docs
          .map((doc) => _productFromMap(doc.id, doc.data()))
          .toList();
    
    print('📊 [FIRESTORE] watchProducts() returned ${result.length} products');
    final categories = result.map((p) => p.category).toSet();
    print('  Categories in products: ${categories.toList()}');
    
    final aayoProducts = result.where((p) => p.category == 'aayo').toList();
    print('  Products with category="aayo": ${aayoProducts.length}');
    
    return result;
  });
}
```

---

## 6️⃣ PRODUCT MODEL
**File:** `lib/data/models/product_model.dart`
```dart
class Product extends Equatable {
  final String id;
  final String name;
  final String category;           // ← The field being compared
  final String imageUrl;
  // ... other fields ...
}
```

---

## 7️⃣ PRODUCT FROM FIRESTORE
**File:** `lib/services/firestore_service.dart:185-205`
```dart
static Product _productFromMap(String id, Map<String, dynamic> data) {
  return Product(
    id: id,
    name: (data['name'] as String?) ?? 'Unnamed Product',
    category: (data['category'] as String?) ?? 'general',  // ← Read from Firestore
    // ... other fields ...
  );
}
```

---

## 🚨 CRITICAL QUESTION: What is product.category for "aayo" products?

### Scenario A: Products stored with category="aayo"
```
Filter: allProducts.where((item) => item.category == "cat-1780725700997")
Product.category = "aayo"
Result: ❌ NO MATCH ("aayo" != "cat-1780725700997")
Display: "No products found"
```

### Scenario B: Products stored with category="cat-1780725700997" 
```
Filter: allProducts.where((item) => item.category == "cat-1780725700997")
Product.category = "cat-1780725700997"
Result: ✅ MATCH
Display: Products grid
```

### Scenario C: No products in Firestore for this category
```
watchProducts() returns: [] (empty)
Filter result: [] (empty)
Display: "No products found"
```

---

## 8️⃣ UI RENDER
**File:** `lib/features/products/product_listing_screen.dart:85-103`
```dart
if (state is ProductsLoaded) {
  print('✅ [UI] ProductsLoaded state: ${state.products.length} products');
  
  if (state.products.isEmpty) {
    print('❌ Displaying "No products found" - categoryId=${state.categoryId}');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text('No products found',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
  
  // GridView of products...
}
```

---

## ✅ WHAT WE'VE CONFIRMED

1. ✅ `category.id` = "cat-1780725700997" (Firestore document ID)
2. ✅ `product.category == categoryId` comparison is correct
3. ✅ No filters on status, draft, published, active, visible, stock
4. ✅ Exact code: `allProducts.where((item) => item.category == categoryId).toList()`
5. ✅ No additional filters exist in ProductsCubit

---

## ❓ WHAT'S MISSING

We need to see the **actual runtime values**:

1. **First 5 products from watchProducts():**
   - product.id
   - product.name
   - product.category ← **CRITICAL**
   - product.status (if exists)

2. **After filter result for categoryId="cat-1780725700997":**
   - Count of matched products
   - List of unique category values in all products

3. **Firestore snapshot.docs count**

**THIS WILL TELL US:**
- Is the filter matching? (Scenario A vs B)
- Are products in Firestore? (Scenario C)
- What is the actual value of product.category in the database?
