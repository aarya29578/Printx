# TODO: Fix Product Detail shows mock data

## Step 1: Trace current flow (already identified)
- Listing uses Firestore products.
- Navigation to `/product/:productId` is currently constructing `ProductDetailScreen(product: MockProducts...)`.

## Step 2: Implement fix (will be executed after confirmation)
- Edit `printx/lib/app.dart` route `/product/:productId`:
  - Remove `MockProducts` lookup.
  - Pass only `productId` into `ProductDetailScreen`.
- Edit `printx/lib/features/products/product_detail_screen.dart`:
  - Change constructor to accept `productId`.
  - In `initState`, load product by id using FirestoreService.
- Edit `printx/lib/features/products/products_cubit.dart`:
  - Ensure we use the existing `ProductDetailCubit` (currently located in this file) to load product by id from Firestore.
  - Remove any dependency on `MockProducts` for the detail screen.


## Step 3: Verification proof
- Add debug prints for:
  - clicked product id (already printed on listing via product.id if we add it)
  - route received productId
  - fetched product id on detail page
- Verify:
  - clickedId == fetchedId
  - name/image/price/description match fetched product fields.

