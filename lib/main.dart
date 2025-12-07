import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'di/dependency_injection.dart';
import 'ui/screens/foodies_screen.dart';

void main() async {
  // Initialize all dependencies
  await DependencyInjection.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Food Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: FoodiesScreen(),
    );
  }
}
