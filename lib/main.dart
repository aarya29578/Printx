import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'features/auth/auth_cubit.dart';
import 'features/products/products_cubit.dart';
import 'features/cart/cart_cubit.dart';
import 'features/orders/orders_cubit.dart';
import 'features/misc_cubits.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await StorageService.init();
  await Hive.initFlutter();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => HomeCubit()),
        BlocProvider(create: (_) => ProductsCubit()),
        BlocProvider(create: (_) => ProductDetailCubit()),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(create: (_) => CheckoutCubit()),
        BlocProvider(create: (_) => OrdersCubit()),
        BlocProvider(create: (_) => DesignsCubit()),
        BlocProvider(create: (_) => SearchCubit()),
        BlocProvider(create: (_) => NotificationsCubit()),
      ],
      child: const PrintXApp(),
    ),
  );
}
