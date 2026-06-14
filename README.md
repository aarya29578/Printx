# PrintX

Production-ready Flutter mobile app for custom printing and branded merchandise (Vistaprint-style, India-focused).

## Overview

- App name: PrintX
- Platforms: Android + iOS
- Min SDK: Android 21, iOS 13
- Data source: 100% mock data (no real API calls)
- Currency: INR formatting with GST-inclusive checkout flow

## Tech Stack

- Flutter + Dart
- State management: flutter_bloc (Cubit)
- Navigation: go_router with ShellRoute + custom page transitions
- Persistence: shared_preferences, flutter_secure_storage, hive_flutter
- UI/animations: animate_do, carousel_slider, shimmer, smooth_page_indicator, flutter_staggered_animations

## Architecture

Layered structure with feature-first organization:

```
lib/
	app.dart
	main.dart
	core/
		constants/
		theme/
		utils/
		widgets/
	data/
		mock_data/
		models/
	services/
	features/
		auth/
		cart/
		categories/
		checkout/
		design_editor/
		home/
		my_designs/
		notifications/
		onboarding/
		orders/
		products/
		profile/
		search/
		splash/
		misc_cubits.dart
```

## Implemented Screens

1. Splash
2. Onboarding
3. Register
4. Login
5. OTP Verification
6. Home
7. Categories
8. Product Listing
9. Product Detail
10. Design Editor
11. Design Preview
12. Cart
13. Checkout
14. Orders
15. Order Tracking
16. My Designs
17. Profile
18. Search
19. Notifications

## Routing

- Root onboarding/auth flow: `/splash`, `/onboarding`, `/auth/*`
- Bottom shell tabs: `/home`, `/categories`, `/designs`, `/orders`, `/profile`
- Feature routes: `/products/:categoryId`, `/product/:productId`, `/editor`, `/preview`, `/cart`, `/checkout`, `/order/:orderId/track`, `/search`, `/notifications`

## State Management

The app is bootstrapped with MultiBlocProvider and includes:

- ThemeCubit
- AuthCubit
- HomeCubit
- ProductsCubit
- ProductDetailCubit
- CartCubit
- CheckoutCubit
- OrdersCubit
- DesignsCubit
- SearchCubit
- NotificationsCubit

## Key Features

- Custom light/dark theme
- Hero transitions and animated page entries
- Bottom navigation with custom center action
- Product variations (size, finish, quantity)
- Coupon + GST checkout calculations
- Order tracking timeline
- Recent searches and local settings persistence

## Run Locally

```bash
flutter pub get
flutter run
```

Optional checks:

```bash
flutter analyze
flutter test
```

## Notes

- All images use `https://picsum.photos` seeds for consistent mock visuals.
- No external backend integration is required.
