# MyFoodDetection

A Flutter food detection application that uses Google Cloud Vision API to identify food items and display their nutritional information.

## Features

- 📸 **Camera Integration**: Capture food images directly from your device
- 🤖 **AI-Powered Detection**: Uses Google Cloud Vision API to identify food items
- 📊 **Food History**: View your previously captured food items
- 🎨 **Clean Architecture**: Organized with data models, services, and UI layers
- ⚡ **Riverpod State Management**: Efficient and reactive state management
- 🔍 **Debug Logging**: Comprehensive logging for easy debugging

## Architecture

The app follows clean architecture principles:

- **Models**: Data structures (`FoodItem`, `FoodDetectionResult`, `Result<T,E>`)
- **Services**: 
  - `FoodDetectionService`: Handles image analysis via Cloud Run endpoint
  - `ApiService`: Generic HTTP client with error handling
- **Data Models**: Business logic layer (`FoodHistoryDataModel`)
- **UI**: Stateless screens powered by Riverpod (`FoodHistoryScreen`)

## Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Riverpod** - State management
- **Google Cloud Vision** - Food detection AI
- **HTTP** - API communication
- **Image Picker** - Camera integration

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Xcode (for iOS development)
- Android Studio (for Android development)
- Google Cloud Vision API endpoint

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

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── dataModels/          # Business logic & state management
│   ├── food_history_data_model.dart
│   ├── food_history_notifier.dart
│   └── food_history_state.dart
├── enums/               # Enumerations
│   └── network_errors.dart
├── models/              # Data models
│   ├── food_detection_result.dart
│   ├── food_item.dart
│   └── result.dart
├── services/            # API & external services
│   ├── api_service.dart
│   └── food_detection_service.dart
├── ui/                  # User interface
│   └── screens/
│       └── food_history_screen.dart
└── main.dart            # App entry point
```

## How It Works

1. User taps "Capture Food" button
2. Camera opens to capture image
3. Image is sent to Google Cloud Vision endpoint
4. AI detects food label and confidence
5. Result is displayed in the history list
6. All steps are logged for debugging

## Debug Logs

The app includes comprehensive logging at each layer:
- `[FoodDetection]` - Detection service logs
- `[DataModel]` - Business logic logs  
- `[CaptureFood]` - UI/state management logs

## Future Enhancements

- [ ] Add nutrition database integration (USDA FoodData Central)
- [ ] Implement local persistence (Hive/SharedPreferences)
- [ ] Add macro tracking (calories, carbs, protein, fat)
- [ ] Food item editing capabilities
- [ ] Export history as CSV/JSON

## License

This project is open source and available under the MIT License.

## Author

**Alon Melnikov**
- GitHub: [@alonmelnikov](https://github.com/alonmelnikov)
