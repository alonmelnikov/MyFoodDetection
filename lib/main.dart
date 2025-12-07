import 'package:flutter/material.dart';

import 'dataModels/food_history_data_model.dart';
import 'services/api_service.dart';
import 'services/food_detection_service.dart';
import 'ui/screens/food_history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final FoodHistoryDataModel _dataModel;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    final apiService = HttpApiService();
    final detectionService = GoogleVisionFoodDetectionService(
      apiService: apiService,
    );

    _dataModel = FoodHistoryDataModelImpl(
      detectionService: detectionService,
    );

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _initialized
          ? FoodHistoryScreen(dataModel: _dataModel)
          : const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
