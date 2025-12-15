import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../core/food_detection_exception.dart';
import '../core/result.dart';
import '../enums/network_errors.dart';
import '../domain/models/food_item.dart';
import '../domain/models/vision_label.dart';
import '../services/food_data_service.dart';
import '../services/food_detection_service.dart';
import '../services/food_history_storage_service.dart';

/// Use case for capturing and detecting food from an image
abstract class CaptureAndDetectFoodUseCase {
  Future<FoodItem> execute(XFile photo);
}

class CaptureAndDetectFoodUseCaseImpl implements CaptureAndDetectFoodUseCase {
  CaptureAndDetectFoodUseCaseImpl({
    required FoodDetectionService detectionService,
    required FoodDataService foodDataService,
    required FoodHistoryStorageService historyStorageService,
  }) : _foodDetectionService = detectionService,
       _foodDataService = foodDataService,
       _historyStorageService = historyStorageService;

  final FoodDetectionService _foodDetectionService;
  final FoodDataService _foodDataService;
  final FoodHistoryStorageService _historyStorageService;

  @override
  Future<FoodItem> execute(XFile photo) async {
    // Convert XFile to File
    final File imageFile = File(photo.path);

    if (!await imageFile.exists()) {
      throw Exception('Captured image file does not exist.');
    }

    final Result<List<VisionLabel>, NetworkError?> detectionResult =
        await _foodDetectionService.detectFood(imageFile);

    if (!detectionResult.isSuccess || detectionResult.data == null) {
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
      throw FoodDetectionException(
        type: FoodDetectionErrorType.foodNotRecognized,
        message:
            'Could not recognize food in the image. Please try a clearer photo.',
      );
    }

    // Filter out labels with topicality < 0.1
    final filteredLabels = labels
        .where((label) => label.topicality >= 0.1)
        .toList();

    if (filteredLabels.isEmpty) {
      throw FoodDetectionException(
        type: FoodDetectionErrorType.foodNotRecognized,
        message:
            'Could not recognize food in the image. Please try a clearer photo.',
      );
    }

    // Reverse labels to get highest scores first and limit to 5
    final labelsToTry = filteredLabels.reversed.take(5).toList();

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
        break;
      } else {
        lastError = nutrientsResult.error;
      }
    }

    // If all labels failed, throw error
    if (selectedLabel == null) {
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

    // Generate item ID and copy image to permanent location AFTER successful detection
    final now = DateTime.now();
    final itemId = '${now.millisecondsSinceEpoch}_${imageFile.path.hashCode}';

    final permanentImagePath = await _copyImageToPermanentLocation(
      imageFile,
      itemId,
    );

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

    return item;
  }

  /// Copy image from temporary location to permanent storage
  Future<String> _copyImageToPermanentLocation(
    File sourceFile,
    String itemId,
  ) async {
    try {
      // Verify source file exists and is readable
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: ${sourceFile.path}');
      }

      // Read the file bytes first to ensure we have the data
      final bytes = await sourceFile.readAsBytes();

      // Get application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDocDir.path}/food_images');

      // Create images directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate permanent file name with item ID
      final fileExtension = sourceFile.path.split('.').last;
      final permanentFile = File('${imagesDir.path}/$itemId.$fileExtension');

      // Write the bytes to the permanent location
      await permanentFile.writeAsBytes(bytes);

      // Verify the file was written successfully
      if (await permanentFile.exists()) {
        return permanentFile.path;
      } else {
        throw Exception('File was not created at: ${permanentFile.path}');
      }
    } catch (e) {
      // Re-throw instead of falling back to original path
      // This ensures we know if image saving fails
      throw Exception('Failed to save image: $e');
    }
  }

  /// Save FoodItem to storage
  Future<void> _saveFoodItem(FoodItem item) async {
    final currentItems = await _historyStorageService.loadFoodItems();
    // Remove existing item with same ID if exists, then add updated one
    final updatedItems = currentItems.where((i) => i.id != item.id).toList();
    updatedItems.insert(0, item); // Add to beginning
    await _historyStorageService.saveFoodItems(updatedItems);
  }
}
