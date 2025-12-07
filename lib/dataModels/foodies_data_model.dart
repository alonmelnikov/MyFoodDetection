import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../enums/network_errors.dart';
import '../models/food_item.dart';
import '../core/result.dart';
import '../core/food_detection_exception.dart';
import '../models/vision_label.dart';
import '../services/food_data_service.dart';
import '../services/food_detection_service.dart';
import '../services/foodies_storage_service.dart';

/// Interface for the foodies view model / data model.
abstract class FoodiesDataModelInterface {
  Future<List<FoodItem>> loadHistory();
  Future<FoodItem> captureAndDetectFood(File imageFile);
  Future<void> clearAll();
}

class FoodiesDataModelImpl implements FoodiesDataModelInterface {
  FoodiesDataModelImpl({
    required FoodDetectionService detectionService,
    required FoodDataService foodDataService,
    required FoodiesStorageService storageService,
  }) : _foodDetectionService = detectionService,
       _foodDataService = foodDataService,
       _storageService = storageService;

  final FoodDetectionService _foodDetectionService;
  final FoodDataService _foodDataService;
  final FoodiesStorageService _storageService;

  @override
  Future<List<FoodItem>> loadHistory() async {
    return await _storageService.loadFoodItems();
  }

  @override
  Future<FoodItem> captureAndDetectFood(File imageFile) async {
    print('[FoodiesDataModel] 🎯 captureAndDetectFood called');
    print('[FoodiesDataModel] 📂 Validating image file: ${imageFile.path}');

    if (!await imageFile.exists()) {
      print('[FoodiesDataModel] ❌ Image file does not exist!');
      throw Exception('Captured image file does not exist.');
    }

    print(
      '[FoodiesDataModel] ✅ Image file validated, calling detection service...',
    );

    final Result<List<VisionLabel>, NetworkError?> detectionResult =
        await _foodDetectionService.detectFood(imageFile);

    if (!detectionResult.isSuccess || detectionResult.data == null) {
      print('[FoodiesDataModel] ❌ Detection service returned failure');
      print('[FoodiesDataModel] ⚠️ Error: ${detectionResult.error}');

      final errorType = detectionResult.error;
      if (errorType == NetworkError.timeout) {
        throw FoodDetectionException(
          type: FoodDetectionErrorType.timeout,
          message:
              'Request timed out. Please check your connection and try again.',
        );
      } else if (errorType == NetworkError.noInternet) {
        throw FoodDetectionException(
          type: FoodDetectionErrorType.noInternet,
          message:
              'No internet connection. Please check your network and try again.',
        );
      } else {
        throw FoodDetectionException(
          type: FoodDetectionErrorType.general,
          message: 'Failed to detect food in image. Please try again.',
        );
      }
    }

    final labels = detectionResult.data!;

    if (labels.isEmpty) {
      print('[FoodiesDataModel] ❌ No labels detected');
      throw FoodDetectionException(
        type: FoodDetectionErrorType.foodNotRecognized,
        message:
            'Could not recognize food in the image. Please try a clearer photo.',
      );
    }

    print(
      '[FoodiesDataModel] ✅ Detection service returned ${labels.length} labels',
    );

    // Reverse labels to get highest scores first and limit to 5
    final labelsToTry = labels.reversed.take(5).toList();
    print(
      '[FoodiesDataModel] 🔄 Will try ${labelsToTry.length} labels (highest scores first, max 5)',
    );

    // Try each label until we get nutrition data
    String? selectedLabel;
    double calories = 0;
    double carbs = 0;
    double protein = 0;
    double fat = 0;
    int? fdcId;

    NetworkError? lastError;
    for (var i = 0; i < labelsToTry.length; i++) {
      final label = labelsToTry[i];
      print(
        '[FoodiesDataModel] 🔄 Trying label ${i + 1}/${labelsToTry.length}: ${label.description}',
      );

      final nutrientsResult = await _foodDataService.getFoodNutrientsByName(
        label.description,
      );

      if (nutrientsResult.isSuccess && nutrientsResult.data != null) {
        final nutrients = nutrientsResult.data!;
        selectedLabel = label.description;
        calories = nutrients.calories;
        carbs = nutrients.carbs;
        protein = nutrients.protein;
        fat = nutrients.fat;
        fdcId = nutrients.fdcId;

        print(
          '[FoodiesDataModel] ✅ Successfully got nutrients for: $selectedLabel',
        );
        break;
      } else {
        print(
          '[FoodiesDataModel] ⚠️ Failed to get nutrients for: ${label.description}',
        );
        lastError = nutrientsResult.error;
      }
    }

    // If all labels failed, throw error
    if (selectedLabel == null) {
      print(
        '[FoodiesDataModel] ❌ Failed to get nutrients for all ${labelsToTry.length} labels tried',
      );

      // Check if the last error was a timeout
      if (lastError == NetworkError.timeout) {
        throw FoodDetectionException(
          type: FoodDetectionErrorType.timeout,
          message:
              'Request timed out while searching for nutrition data. Please check your connection and try again.',
        );
      } else if (lastError == NetworkError.noInternet) {
        throw FoodDetectionException(
          type: FoodDetectionErrorType.noInternet,
          message:
              'No internet connection. Please check your network and try again.',
        );
      } else {
        throw FoodDetectionException(
          type: FoodDetectionErrorType.foodNotRecognized,
          message:
              'Could not find nutrition data for the detected food. Please try a different photo.',
        );
      }
    }

    final now = DateTime.now();
    final itemId = '${now.millisecondsSinceEpoch}_${imageFile.path.hashCode}';

    // Copy image to permanent location
    final permanentImagePath = await _copyImageToPermanentLocation(
      imageFile,
      itemId,
    );

    print('[FoodiesDataModel] 🔨 Building FoodItem...');
    print('[FoodiesDataModel]    - ID: $itemId');
    print('[FoodiesDataModel]    - Name: $selectedLabel');
    print('[FoodiesDataModel]    - Original Path: ${imageFile.path}');
    print('[FoodiesDataModel]    - Permanent Path: $permanentImagePath');
    print('[FoodiesDataModel]    - Calories: $calories');
    print('[FoodiesDataModel]    - Carbs: ${carbs}g');
    print('[FoodiesDataModel]    - Protein: ${protein}g');
    print('[FoodiesDataModel]    - Fat: ${fat}g');
    print('[FoodiesDataModel]    - Time: $now');

    final item = FoodItem(
      id: itemId,
      name: selectedLabel,
      imagePath: permanentImagePath,
      calories: calories,
      carbs: carbs,
      protein: protein,
      fat: fat,
      capturedAt: now,
      fdcId: fdcId,
    );

    // Save the item to storage
    await _saveFoodItem(item);

    print('[FoodiesDataModel] ✅ FoodItem created successfully');
    return item;
  }

  /// Copy image from temporary location to permanent storage
  Future<String> _copyImageToPermanentLocation(
    File sourceFile,
    String itemId,
  ) async {
    print('[FoodiesDataModel] 📸 Copying image to permanent location...');

    try {
      // Get application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDocDir.path}/food_images');

      // Create images directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        print(
          '[FoodiesDataModel] 📁 Created images directory: ${imagesDir.path}',
        );
      }

      // Generate permanent file name with item ID
      final fileExtension = sourceFile.path.split('.').last;
      final permanentFile = File('${imagesDir.path}/${itemId}.$fileExtension');

      // Copy the file
      await sourceFile.copy(permanentFile.path);
      print('[FoodiesDataModel] ✅ Image copied to: ${permanentFile.path}');

      return permanentFile.path;
    } catch (e) {
      print('[FoodiesDataModel] ❌ Failed to copy image: $e');
      // If copy fails, return original path as fallback
      print('[FoodiesDataModel] ⚠️ Using original path as fallback');
      return sourceFile.path;
    }
  }

  @override
  Future<void> clearAll() async {
    print('[FoodiesDataModel] 🗑️ Clearing all data...');

    // Load items first to get image paths
    final items = await _storageService.loadFoodItems();

    // Delete all image files
    for (final item in items) {
      try {
        final imageFile = File(item.imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
          print('[FoodiesDataModel] 🗑️ Deleted image: ${item.imagePath}');
        }
      } catch (e) {
        print(
          '[FoodiesDataModel] ⚠️ Failed to delete image ${item.imagePath}: $e',
        );
      }
    }

    // Clear storage
    await _storageService.clearAll();
    print('[FoodiesDataModel] ✅ All data cleared');
  }

  /// Save FoodItem to storage
  Future<void> _saveFoodItem(FoodItem item) async {
    print('[FoodiesDataModel] 💾 Saving FoodItem to storage...');
    final currentItems = await _storageService.loadFoodItems();
    // Remove existing item with same ID if exists, then add updated one
    final updatedItems = currentItems.where((i) => i.id != item.id).toList();
    updatedItems.insert(0, item); // Add to beginning
    await _storageService.saveFoodItems(updatedItems);
    print('[FoodiesDataModel] ✅ FoodItem saved to storage');
  }
}
