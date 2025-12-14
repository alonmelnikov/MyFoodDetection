# MyFoodDetection

A Flutter application that detects food from images using Google Cloud Vision API and fetches nutritional information from USDA FoodData Central API.

## Features

- 📸 Capture food images using camera
- 🔍 Detect food labels using Google Cloud Vision API
- 🥗 Fetch nutritional data (calories, carbs, protein, fat) from USDA API
- 📊 Display food history with nutrition information
- 🔄 Smart retry logic - tries up to 5 detected labels to find nutrition data
- 🔐 Secure API key management: API keys are managed by Google Secret Manager, ensuring sensitive credentials are not stored in the codebase

## Architecture

### Clean Architecture Layers

```
ui/screens/           # Presentation layer
  └── FoodHistoryScreen
  
controllers/          # State management (GetX)
  └── FoodHistoryController
  
dataModels/          # Business logic
  └── FoodHistoryDataModelImpl
  
services/            # Data layer
  ├── VisionDetectionService    # Google Cloud Vision API
  ├── FoodDetectionService      # Label sorting and processing
  ├── FoodDataService           # USDA nutrition API
  ├── ApiService                # Generic HTTP client
  └── SecretsService            # API key management
  
models/              # Data models
  ├── FoodItem
  ├── FoodNutrients
  ├── VisionLabel
  └── VisionDetectionData
```

### Flow

1. User captures food image
2. `VisionDetectionService` sends image to Google Cloud Vision API
3. `FoodDetectionService` sorts labels by combined score (topicality × 0.7 + score × 0.3)
4. `FoodHistoryDataModelImpl` tries each label (up to 5) with USDA API:
   - Tries best label → Search USDA → Get nutrients ✅
   - If fails → Try next label → Search USDA...
   - Continues until success or all 5 labels tried
5. Creates `FoodItem` with real nutrition data
6. Displays in history list


### Prerequisites

- Flutter SDK (^3.10.1)
- Dart SDK
- iOS/Android device or simulator
- Google Cloud Vision API access (via Cloud Run endpoint)
- USDA FoodData Central API key

### API Key Management

API keys are managed by Google Secret Manager. The application retrieves API keys securely from Google Secret Manager at runtime, ensuring sensitive credentials are not stored in the codebase or environment files.



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
├── controllers/
│   └── food_history_controller.dart    # GetX controller
├── dataModels/
│   └── food_history_data_model.dart    # Business logic
├── enums/
│   └── network_errors.dart             # Network error types
├── models/
│   ├── food_item.dart                  # Food item model
│   ├── food_nutrients.dart             # Nutrients model
│   ├── result.dart                     # Result<T, E> wrapper
│   ├── vision_detection_data.dart      # Vision API response
│   └── vision_label.dart               # Single label data
├── services/
│   ├── api_service.dart                # Generic HTTP client
│   ├── food_data_service.dart          # USDA API integration
│   ├── food_detection_service.dart     # Label processing
│   ├── secrets_service.dart            # API key management
│   └── vision_detection_service.dart   # Google Vision API
└── ui/
    └── screens/
        └── food_history_screen.dart    # Main UI screen
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
- `timeout`
- `noInternet`
- `unauthorized`
- `notFound`
- `serverError`
- `badResponse`
- `unknown`

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
