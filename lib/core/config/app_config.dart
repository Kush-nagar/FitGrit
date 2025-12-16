/// Configuration constants for the app
class AppConfig {
  // API Keys - Move these to environment variables or secure storage in production
  static const String geminiApiKey = "AIzaSyByyWOfPxo7q9Ae8EuPVTQV8sr-KJA9O_4";

  // API Configuration
  static const String geminiModel = 'gemini-2.0-flash-exp';
  static const int maxImageDimension = 1024;

  // Feature Flags
  static const bool enableGeminiApi = true;

  // TODO: In production, use flutter_dotenv or flutter_config to load from .env file
  // Example:
  // static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
}
