import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../core/food_detection_exception.dart';
import '../core/result.dart';
import '../enums/network_errors.dart';
import '../models/food_item.dart';
import '../models/vision_label.dart';
import '../services/food_data_service.dart';
import '../services/food_detection_service.dart';
import '../services/foodies_storage_service.dart';

/// Use case for capturing and detecting food from an image
abstract class CaptureAndDetectFoodUseCase {
  Future<FoodItem> execute(XFile photo);
}

class CaptureAndDetectFoodUseCaseImpl implements CaptureAndDetectFoodUseCase {
  CaptureAndDetectFoodUseCaseImpl({
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
  Future<FoodItem> execute(XFile photo) async {
    print('[CaptureAndDetectFoodUseCase] 🎯 execute called');
    print('[CaptureAndDetectFoodUseCase] 📸 Photo path: ${photo.path}');

    // Convert XFile to File
    final File imageFile = File(photo.path);

    print(
      '[CaptureAndDetectFoodUseCase] 📂 Validating image file: ${imageFile.path}',
    );

    if (!await imageFile.exists()) {
      print('[CaptureAndDetectFoodUseCase] ❌ Image file does not exist!');
      throw Exception('Captured image file does not exist.');
    }

    print(
      '[CaptureAndDetectFoodUseCase] ✅ Image file validated, calling detection service...',
    );

    final Result<List<VisionLabel>, NetworkError?> detectionResult =
        await _foodDetectionService.detectFood(imageFile);

    if (!detectionResult.isSuccess || detectionResult.data == null) {
      print(
        '[CaptureAndDetectFoodUseCase] ❌ Detection service returned failure',
      );
      print('[CaptureAndDetectFoodUseCase] ⚠️ Error: ${detectionResult.error}');

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
      print('[CaptureAndDetectFoodUseCase] ❌ No labels detected');
      throw FoodDetectionException(
        type: FoodDetectionErrorType.foodNotRecognized,
        message:
            'Could not recognize food in the image. Please try a clearer photo.',
      );
    }

    print(
      '[CaptureAndDetectFoodUseCase] ✅ Detection service returned ${labels.length} labels',
    );

    // Filter out labels with topicality < 0.1
    final filteredLabels = labels
        .where((label) => label.topicality >= 0.1)
        .toList();
    print(
      '[CaptureAndDetectFoodUseCase] 🔍 Filtered to ${filteredLabels.length} labels (topicality >= 0.1)',
    );

    if (filteredLabels.isEmpty) {
      print(
        '[CaptureAndDetectFoodUseCase] ❌ No labels with sufficient topicality',
      );
      throw FoodDetectionException(
        type: FoodDetectionErrorType.foodNotRecognized,
        message:
            'Could not recognize food in the image. Please try a clearer photo.',
      );
    }

    // Reverse labels to get highest scores first and limit to 5
    final labelsToTry = filteredLabels.reversed.take(5).toList();
    print(
      '[CaptureAndDetectFoodUseCase] 🔄 Will try ${labelsToTry.length} labels (highest scores first, max 5)',
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
        '[CaptureAndDetectFoodUseCase] 🔄 Trying label ${i + 1}/${labelsToTry.length}: ${label.description}',
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
          '[CaptureAndDetectFoodUseCase] ✅ Successfully got nutrients for: $selectedLabel',
        );
        break;
      } else {
        print(
          '[CaptureAndDetectFoodUseCase] ⚠️ Failed to get nutrients for: ${label.description}',
        );
        lastError = nutrientsResult.error;
      }
    }

    // If all labels failed, throw error
    if (selectedLabel == null) {
      print(
        '[CaptureAndDetectFoodUseCase] ❌ Failed to get nutrients for all ${labelsToTry.length} labels tried',
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

    // Generate item ID and copy image to permanent location AFTER successful detection
    final now = DateTime.now();
    final itemId = '${now.millisecondsSinceEpoch}_${imageFile.path.hashCode}';

    print(
      '[CaptureAndDetectFoodUseCase] 📸 Saving image to permanent location...',
    );
    final permanentImagePath = await _copyImageToPermanentLocation(
      imageFile,
      itemId,
    );

    print('[CaptureAndDetectFoodUseCase] 🔨 Building FoodItem...');
    print('[CaptureAndDetectFoodUseCase]    - ID: $itemId');
    print('[CaptureAndDetectFoodUseCase]    - Name: $selectedLabel');
    print(
      '[CaptureAndDetectFoodUseCase]    - Original Path: ${imageFile.path}',
    );
    print(
      '[CaptureAndDetectFoodUseCase]    - Permanent Path: $permanentImagePath',
    );
    print('[CaptureAndDetectFoodUseCase]    - Calories: $calories');
    print('[CaptureAndDetectFoodUseCase]    - Carbs: ${carbs}g');
    print('[CaptureAndDetectFoodUseCase]    - Protein: ${protein}g');
    print('[CaptureAndDetectFoodUseCase]    - Fat: ${fat}g');
    print('[CaptureAndDetectFoodUseCase]    - Time: $now');

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

    print('[CaptureAndDetectFoodUseCase] ✅ FoodItem created successfully');
    return item;
  }

  /// Copy image from temporary location to permanent storage
  Future<String> _copyImageToPermanentLocation(
    File sourceFile,
    String itemId,
  ) async {
    print(
      '[CaptureAndDetectFoodUseCase] 📸 Copying image to permanent location...',
    );
    print('[CaptureAndDetectFoodUseCase] 📂 Source file: ${sourceFile.path}');
    print(
      '[CaptureAndDetectFoodUseCase] 📂 Source exists: ${await sourceFile.exists()}',
    );

    try {
      // Verify source file exists and is readable
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist: ${sourceFile.path}');
      }

      // Read the file bytes first to ensure we have the data
      final bytes = await sourceFile.readAsBytes();
      print(
        '[CaptureAndDetectFoodUseCase] 📦 Read ${bytes.length} bytes from source',
      );

      // Get application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDocDir.path}/food_images');

      // Create images directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
        print(
          '[CaptureAndDetectFoodUseCase] 📁 Created images directory: ${imagesDir.path}',
        );
      }

      // Generate permanent file name with item ID
      final fileExtension = sourceFile.path.split('.').last;
      final permanentFile = File('${imagesDir.path}/${itemId}.$fileExtension');

      // Write the bytes to the permanent location
      await permanentFile.writeAsBytes(bytes);
      print(
        '[CaptureAndDetectFoodUseCase] ✅ Image written to: ${permanentFile.path}',
      );

      // Verify the file was written successfully
      if (await permanentFile.exists()) {
        final savedSize = await permanentFile.length();
        print(
          '[CaptureAndDetectFoodUseCase] ✅ Verified: Saved file exists (${savedSize} bytes)',
        );
        return permanentFile.path;
      } else {
        throw Exception('File was not created at: ${permanentFile.path}');
      }
    } catch (e, stackTrace) {
      print('[CaptureAndDetectFoodUseCase] ❌ Failed to copy image: $e');
      print('[CaptureAndDetectFoodUseCase] 📚 Stack trace: $stackTrace');
      // Re-throw instead of falling back to original path
      // This ensures we know if image saving fails
      throw Exception('Failed to save image: $e');
    }
  }

  /// Save FoodItem to storage
  Future<void> _saveFoodItem(FoodItem item) async {
    print('[CaptureAndDetectFoodUseCase] 💾 Saving FoodItem to storage...');
    print('[CaptureAndDetectFoodUseCase]    - Item ID: ${item.id}');
    print('[CaptureAndDetectFoodUseCase]    - Item Name: ${item.name}');
    print('[CaptureAndDetectFoodUseCase]    - Image Path: ${item.imagePath}');

    // Verify the image file exists before saving
    final imageFile = File(item.imagePath);
    final imageExists = await imageFile.exists();
    print('[CaptureAndDetectFoodUseCase]    - Image exists: $imageExists');
    if (imageExists) {
      final imageSize = await imageFile.length();
      print('[CaptureAndDetectFoodUseCase]    - Image size: $imageSize bytes');
    } else {
      print(
        '[CaptureAndDetectFoodUseCase] ⚠️ WARNING: Image file does not exist at saved path!',
      );
    }

    final currentItems = await _storageService.loadFoodItems();
    // Remove existing item with same ID if exists, then add updated one
    final updatedItems = currentItems.where((i) => i.id != item.id).toList();
    updatedItems.insert(0, item); // Add to beginning
    await _storageService.saveFoodItems(updatedItems);
    print(
      '[CaptureAndDetectFoodUseCase] ✅ FoodItem saved to storage (${updatedItems.length} total items)',
    );
  }
}
