import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/food_detection_service.dart';
import 'food_history_data_model.dart';
import 'food_history_state.dart';

/// Provider for the data model, wiring detection service (no persistence).
final foodHistoryDataModelProvider = Provider<FoodHistoryDataModel>((ref) {
  final apiService = HttpApiService();
  final detectionService = GoogleVisionFoodDetectionService(
    apiService: apiService,
  );

  return FoodHistoryDataModelImpl(detectionService: detectionService);
});

/// Riverpod state notifier that exposes FoodHistoryState to the UI.
final foodHistoryNotifierProvider =
    StateNotifierProvider<FoodHistoryNotifier, FoodHistoryState>((ref) {
      final model = ref.read(foodHistoryDataModelProvider);
      final notifier = FoodHistoryNotifier(dataModel: model);
      notifier.loadHistory(); // initial load
      return notifier;
    });

class FoodHistoryNotifier extends StateNotifier<FoodHistoryState> {
  FoodHistoryNotifier({required this.dataModel})
    : super(const FoodHistoryState.initial());

  final FoodHistoryDataModel dataModel;

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await dataModel.loadHistory();
      state = state.copyWith(items: items, isLoading: false, error: null);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load history');
    }
  }

  Future<void> captureFood(File imageFile) async {
    print('[CaptureFood] 🎬 Starting captureFood flow...');
    print('[CaptureFood] 📸 Image file: ${imageFile.path}');
    print('[CaptureFood] 📂 File exists: ${await imageFile.exists()}');

    state = state.copyWith(isLoading: true, error: null);
    print('[CaptureFood] ⏳ State set to loading, calling data model...');

    try {
      final item = await dataModel.captureAndDetectFood(imageFile);
      print('[CaptureFood] ✅ Detection successful!');
      print('[CaptureFood] 🍕 Food name: ${item.name}');
      print('[CaptureFood] 🆔 Item ID: ${item.id}');
      print('[CaptureFood] 📁 Saved at: ${item.imagePath}');
      print('[CaptureFood] 🕐 Captured at: ${item.capturedAt}');
      print('[CaptureFood] 📊 Current items count: ${state.items.length}');

      state = state.copyWith(
        items: [item, ...state.items],
        isLoading: false,
        error: null,
      );

      print(
        '[CaptureFood] ✅ State updated, new items count: ${state.items.length}',
      );
    } catch (e, stackTrace) {
      print('[CaptureFood] ❌ Error occurred: $e');
      print('[CaptureFood] 📚 Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to analyze food. Please try again.',
      );

      print('[CaptureFood] ⚠️ Error state set');
    }
  }
}
