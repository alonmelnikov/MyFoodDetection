import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Protocol (interface) for accessing API secrets
abstract class SecretsService {
  /// Get the USDA FoodData Central API key
  String? get usdaApiKey;
}

/// Implementation of SecretsService that reads from .env file
class EnvSecretsService implements SecretsService {
  EnvSecretsService();

  /// Load environment variables from .env file
  /// Must be called before accessing any secrets
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }

  @override
  String? get usdaApiKey {
    return dotenv.env['USDA_API_KEY'];
  }
}
