# TODO - Orders UI completion (spec-driven)

## Status
- Orders UI foundation exists but is not spec-complete.
- `OrdersCubit` currently uses legacy `FirestoreService.fetchOrders()`.
- `OrdersScreen` empty state text is not correct.
- Order list and details UIs are not updated to required fields.
- Routing still uses `MockOrders` for `/order/:orderId/track`.

## Steps
1. Update `printx/lib/features/orders/orders_cubit.dart`
   - Replace all `FirestoreService.fetchOrders()` usage.
   - Use `FirestoreService.fetchOrdersForUser(userId: currentUser.uid)`.
   - Ensure auth null-safety.

2. Update `printx/lib/features/orders/orders_screen.dart`
   - If no orders exist: show exactly `No Orders Found`.
   - Update order card UI to render required fields:
     - product image, product name, quantity, selected size, selected finish,
       order status, order date, total amount.

3. Implement/Update Order Details Screen
   - Create `printx/lib/features/orders/order_details_screen.dart` (or update existing if present).
   - Display required fields:
     - product image, product name, quantity, price, selected size, selected finish,
       order status, order date, total amount.
   - Add route from order card (remove dependency on tracking route if necessary).

4. Remove all mock/fallback order dependencies
   - Ensure `MockOrders` is not used anywhere in Flutter app code.
   - Remove dummy/fallback order lists.

5. Build verification
   - Run `flutter analyze` until compile-time errors are zero.
   - Run Flutter build successfully.

6. Runtime verification (capture proof)
   1) Add product to cart
   2) Checkout
   3) Place order
   4) Firestore document created (screenshot/log)
   5) Cart cleared (screenshot/log)
   6) Orders screen shows newly created order (screenshot/log)
   7) Only current user's orders visible
   8) No mock data anywhere
   9) Provide exact files modified + logs + screenshots


