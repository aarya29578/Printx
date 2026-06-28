# TODO: Custom design upload added to product detail + stored in orders

- [ ] Add fields to CartItem model:
  - customDesignUrl (String?)
  - customDesignFileName (String?)
  - customerInstructions (String)
- [ ] Update CartCubit.addProduct() to accept optional custom design/instructions and store defaults.
- [ ] Update CheckoutCubit.placeOrder() to include:
  - customDesignUrl
  - customDesignFileName
  - customerInstructions
  inside each order item map.
- [ ] Update FirestoreService._orderFromMap() and OrderItem model to parse these new fields with backward-compatible defaults.
- [ ] Backend upload:
  - [x] Create `upload-design.php` using same multipart architecture as `upload-profile.php`.
  - [x] Ensure it only accepts: JPG/JPEG/PNG/PDF.
  - [ ] Save under existing public storage location (mirror /profiles/ with /designs/ or similar) and return JSON: {"url": ..., "filename": ...}.
- [ ] Flutter upload method in `lib/services/upload_service.dart`:
  - add `uploadCustomerDesign(...)` using same multipart request code pattern.
- [ ] UI:
  - [ ] Add an optional upload section below the customization action in `product_detail_screen.dart`.
  - [ ] Support image preview for images; show filename for all.
  - [ ] Add multiline instructions textarea with placeholder.
  - [ ] On Add to Cart, upload (if chosen) then pass URL/filename/instructions to CartCubit.
- [ ] Run Flutter formatting/lint/build.
- [ ] Manual smoke test:
  - Order without upload works and Firestore writes null/"".
  - Order with image works; preview renders; Firestore stores url+filename.
  - Order with PDF works; Firestore stores url+filename.

