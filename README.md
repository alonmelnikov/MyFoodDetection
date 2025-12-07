# MyFoodDetection

A Flutter application that detects food from images using Google Cloud Vision API and fetches nutritional information from USDA FoodData Central API.

## Features

- 📸 Capture food images using camera
- 🔍 Detect food labels using Google Cloud Vision API
- 🥗 Fetch nutritional data (calories, carbs, protein, fat) from USDA API
- 📊 Display food history with nutrition information and saved photos
- 🔄 Smart retry logic - tries up to 5 detected labels to find nutrition data
- 🎯 Topicality filtering - only considers labels with topicality >= 0.1
- 💾 Persistent storage - photos and food items saved locally
- 🗑️ Clear all functionality - remove all food items and cached data
- 📱 Food detail screen - view comprehensive nutrition information
- 🔐 Secure API key storage using environment variables
- ⚡ Disk caching - API responses cached for 7 days with 30-item limit
- 🎨 Clean, modern UI with error handling

## Architecture

### Clean Architecture Layers

```
ui/
  ├── screens/                    # Presentation layer
  │   ├── FoodiesScreen          # Main food history screen
  │   └── FoodDetailScreen       # Detailed food information
  └── custom_widgets/             # Reusable UI components
      ├── GenericList
      └── GenericListItem

controllers/                      # State management (GetX)
  ├── FoodiesController          # Main screen controller
  └── FoodDetailsController      # Detail screen controller

useCases/                         # Business logic (Use Cases)
  ├── CaptureAndDetectFoodUseCase      # Capture, detect, and save food
  ├── LoadFoodHistoryUseCase           # Load saved food items
  ├── LoadFoodDetailUseCase            # Load detailed food info
  └── ClearAllUseCase                  # Clear all data

services/                         # Data layer
  ├── VisionDetectionService     # Google Cloud Vision API
  ├── FoodDetectionService        # Label sorting and processing
  ├── FoodDataService            # USDA nutrition API
  ├── FoodiesStorageService      # Food items & API response caching
  ├── StorageService             # Generic file storage
  ├── ApiService                 # Generic HTTP client
  └── SecretsService             # API key management

models/                          # Data models
  ├── FoodItem                   # Food entry with nutrition
  ├── FoodNutrients              # Parsed nutrition data
  ├── FoodDetail                 # Comprehensive food information
  ├── VisionLabel                # Single detected label
  └── VisionDetectionData       # Vision API response

core/                            # Core utilities
  ├── Result<T, E>               # Functional error handling
  └── FoodDetectionException     # Custom exception types

di/                              # Dependency Injection
  └── DependencyInjection        # Centralized DI container
```

### Flow

1. User captures food image
2. `CaptureAndDetectFoodUseCase`:
   - Validates image file
   - `VisionDetectionService` sends image to Google Cloud Vision API
   - `FoodDetectionService` sorts labels by combined score (topicality × 0.7 + score × 0.3)
   - Filters labels with topicality >= 0.1
   - Tries each label (up to 5) with USDA API:
     - Tries best label → Search USDA → Get nutrients ✅
     - If fails → Try next label → Search USDA...
     - Continues until success or all 5 labels tried
   - Saves image to permanent storage (`food_images/` directory)
   - Creates `FoodItem` with real nutrition data
   - Saves to persistent storage
3. `FoodiesScreen` displays food history with photos
4. User can tap item to view detailed nutrition in `FoodDetailScreen`

## Setup

### Prerequisites

- Flutter SDK (^3.10.1)
- Dart SDK
- iOS/Android device or simulator
- Google Cloud Vision API access (via Cloud Run endpoint)
- USDA FoodData Central API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/alonmelnikov/MyFoodDetection.git
cd MyFoodDetection
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create `.env` file in the project root:
```bash
# USDA FoodData Central API Key
USDA_API_KEY=your-api-key-here
```

4. Run the app:
```bash
# iOS Simulator
flutter run -d "iPhone Simulator"

# Android Emulator
flutter run -d emulator

# Physical device
flutter run -d <device-id>
```

## Configuration

### API Keys

The app uses environment variables to store API keys securely:

- **USDA API Key**: Get yours at [USDA FoodData Central](https://fdc.nal.usda.gov/api-key-signup.html)
- **Google Cloud Vision**: Currently uses a Cloud Run endpoint (hardcoded in `VisionDetectionService`)

### Environment Variables

Create a `.env` file with:
```env
USDA_API_KEY=your-usda-api-key-here
```

**Note**: The `.env` file is gitignored and will not be committed.

## Dependencies

```yaml
dependencies:
  flutter_dotenv: ^5.1.0        # Environment variables
  get: ^4.6.6                   # State management
  image_picker: ^1.1.2          # Camera access
  http: ^1.2.2                  # HTTP client
  path_provider: ^2.1.4         # File paths
```

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── controllers/                        # GetX controllers
│   ├── foodies_controller.dart        # Main screen controller
│   └── food_detail_controller.dart     # Detail screen controller
├── useCases/                           # Business logic (Use Cases)
│   ├── capture_and_detect_food_use_case.dart
│   ├── load_food_history_use_case.dart
│   ├── load_food_detail_use_case.dart
│   └── clear_all_use_case.dart
├── services/                           # Data layer
│   ├── api_service.dart                # Generic HTTP client
│   ├── food_data_service.dart          # USDA API integration
│   ├── food_detection_service.dart     # Label processing
│   ├── foodies_storage_service.dart    # Food items & caching
│   ├── storage_service.dart            # Generic file storage
│   ├── secrets_service.dart            # API key management
│   └── vision_detection_service.dart   # Google Vision API
├── models/                             # Data models
│   ├── food_item.dart                  # Food entry model
│   ├── food_nutrients.dart             # Nutrients model
│   ├── food_detail.dart                # Detailed food info
│   ├── vision_detection_data.dart      # Vision API response
│   └── vision_label.dart               # Single label data
├── core/                               # Core utilities
│   ├── result.dart                     # Result<T, E> wrapper
│   └── food_detection_exception.dart   # Custom exceptions
├── enums/
│   └── network_errors.dart             # Network error types
├── di/                                 # Dependency Injection
│   └── dependency_injection.dart      # DI container
└── ui/
    ├── screens/
    │   ├── foodies_screen.dart         # Main food history screen
    │   └── food_detail_screen.dart     # Detailed food view
    └── custom_widgets/
        ├── generic_list.dart           # Reusable list widget
        └── generic_list_item.dart     # Reusable list item
```

## API Documentation

### Google Cloud Vision API

Endpoint: `https://analyze-image-698327160260.europe-west1.run.app`

**Request:**
```json
{
  "imageBase64": "base64-encoded-image"
}
```

**Response:**
```json
{
  "responses": [
    {
      "labelAnnotations": [
        {
          "description": "Food",
          "score": 0.95,
          "topicality": 0.92
        }
      ]
    }
  ]
}
```

### USDA FoodData Central API

Base URL: `https://api.nal.usda.gov/fdc/v1`

**Endpoint:** `/foods/search`
- Query: Food name
- Returns: List of foods with nutrition data

## Error Handling

The app uses a `Result<T, E>` pattern for error handling:

```dart
Result<FoodNutrients?, NetworkError?>
```

Network errors are categorized:
- `timeout` - Request timed out (30s timeout)
- `noInternet` - No internet connection
- `unauthorized` - API key invalid
- `notFound` - Resource not found
- `serverError` - Server error (5xx)
- `badResponse` - Invalid response format
- `unknown` - Unknown error

### User-Friendly Error Messages

The app provides specific error messages for different scenarios:
- ⏱️ **Timeout**: "Request timed out. Please check your connection and try again."
- 📶 **No Internet**: "No internet connection. Please check your network and try again."
- 🍽️ **Food Not Recognized**: "Could not recognize food in the image. Please try a clearer photo."
- ⚠️ **General Error**: "An unexpected error occurred. Please try again."

## Storage & Caching

### Food Items Storage
- Food items are persisted to disk using JSON serialization
- Images are saved to `{AppDocuments}/food_images/` directory
- Images persist across app restarts

### API Response Caching
- Search results cached for 7 days
- Food details cached for 7 days
- Maximum 30 cached items (oldest-first eviction)
- Automatic cleanup of expired cache entries

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is a demo application.

## Authors

- [Alon Melnikov](https://github.com/alonmelnikov)
