import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/routing/app_router.dart';
import 'package:tashil_real_estate/core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tashil_real_estate/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TashilRealEstateApp());
}

class TashilRealEstateApp extends StatelessWidget {
  const TashilRealEstateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TashilRealEstate',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
