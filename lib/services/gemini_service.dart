import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Wrapper around Google Gemini API for food/ingredient detection.
/// Uploads an image, asks Gemini to return ONLY JSON.
class GeminiService {
  final String apiKey;
  final String model;
  final int maxDimension;

  GeminiService({
    required this.apiKey,
    this.model = 'gemini-2.0-flash-exp', // use latest stable model
    this.maxDimension = 1024,
  });

  Future<List<Map<String, dynamic>>> detectFoods(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image not found: $imagePath');
    }

    // Read and resize if necessary
    final bytes = await file.readAsBytes();
    final safeBytes = _resizeIfNeeded(bytes, maxDimension);
    final mimeType = _mimeTypeFromPath(imagePath);
    final base64Data = base64Encode(safeBytes);

    final prompt = '''
You are a helpful assistant that must identify ALL the different ingredients and food items visible in the image. 
YOU MUST ONLY OUTPUT a JSON array (no markdown, no text outside JSON).

IMPORTANT: Identify EACH distinct food item or ingredient separately. If there are multiple items, list them all individually.

Each element must have:
- "name": string, the detected food/ingredient (be specific, e.g., "Red Onion", "Cherry Tomatoes", "Ground Beef")
- "confidence": number between 0 and 1 (higher means more confident)

Examples:

If the image shows a salad with multiple ingredients:
[
  {"name":"Lettuce","confidence":0.95},
  {"name":"Tomato","confidence":0.93},
  {"name":"Cucumber","confidence":0.90},
  {"name":"Red Onion","confidence":0.87},
  {"name":"Feta Cheese","confidence":0.85},
  {"name":"Olive Oil","confidence":0.78}
]

If the image shows ingredients for a recipe:
[
  {"name":"Chicken Breast","confidence":0.94},
  {"name":"Broccoli","confidence":0.92},
  {"name":"Garlic","confidence":0.88},
  {"name":"Soy Sauce","confidence":0.82}
]

Return nothing else. Identify as many distinct items as you can see clearly.
''';

    final body = {
      "contents": [
        {
          "parts": [
            {
              "inline_data": {"mime_type": mimeType, "data": base64Data},
            },
            {"text": prompt},
          ],
        },
      ],
    };

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    final headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };

    final resp = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (resp.statusCode != 200) {
      // Parse error response
      String errorMessage = 'Gemini API error ${resp.statusCode}';
      try {
        final errorData = jsonDecode(resp.body);
        if (errorData['error'] != null &&
            errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];

          // Provide user-friendly messages for common errors
          if (resp.statusCode == 403) {
            errorMessage =
                'API access denied. Please enable the Generative Language API in Google Cloud Console.';
          } else if (resp.statusCode == 429) {
            errorMessage = 'API quota exceeded. Please try again later.';
          } else if (resp.statusCode == 401) {
            errorMessage = 'Invalid API key. Please check your Gemini API key.';
          }
        }
      } catch (_) {
        // Use default error message if parsing fails
      }
      throw Exception(errorMessage);
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    String modelText = _extractText(decoded);

    if (modelText.isEmpty) {
      throw Exception('No text returned by Gemini: ${resp.body}');
    }

    // Parse JSON strictly
    try {
      final parsed = jsonDecode(modelText);
      if (parsed is List) {
        return parsed
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (parsed is Map) {
        return [Map<String, dynamic>.from(parsed)];
      }
    } catch (_) {
      // fallback: try regex extract
      final arrayMatch = RegExp(
        r'(\[.*\])',
        dotAll: true,
      ).firstMatch(modelText);
      if (arrayMatch != null) {
        return (jsonDecode(arrayMatch.group(1)!) as List<dynamic>)
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    // If still failing, fallback to simple list
    return [
      {"name": modelText.trim(), "confidence": 0.5},
    ];
  }

  // --- helpers ---

  String _extractText(Map<String, dynamic> decoded) {
    String fullText = '';
    if (decoded.containsKey('candidates')) {
      for (final c in decoded['candidates'] as List<dynamic>) {
        final content = c['content'];
        if (content is Map && content['parts'] is List) {
          for (final p in content['parts']) {
            if (p is Map && p['text'] is String) {
              fullText += p['text'];
            }
          }
        }
      }
    }
    return fullText.trim();
  }

  String _mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  List<int> _resizeIfNeeded(List<int> bytes, int maxDim) {
    try {
      final original = img.decodeImage(Uint8List.fromList(bytes));
      if (original == null) return bytes;
      final w = original.width, h = original.height;
      if (w <= maxDim && h <= maxDim) return bytes;

      final ratio = maxDim / (w > h ? w : h);
      final resized = img.copyResize(
        original,
        width: (w * ratio).round(),
        height: (h * ratio).round(),
      );
      return img.encodeJpg(resized, quality: 85);
    } catch (_) {
      return bytes;
    }
  }

  /// normalize instructions to always be a list of clean step strings
  List<String> _normalizeInstructions(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (raw is String) {
      // Split by numbers, bullets, or line breaks
      return raw
          .split(RegExp(r'(\d+\.|\n|•|- )'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return [];
  }

  /// Get nutrition information for food items from an image
  Future<Map<String, dynamic>> getNutritionInfo({
    required String imagePath,
    required List<String> ingredients,
    bool includeImagePath = true,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image not found: $imagePath');
    }

    // Read and resize if necessary
    final bytes = await file.readAsBytes();
    final safeBytes = _resizeIfNeeded(bytes, maxDimension);
    final mimeType = _mimeTypeFromPath(imagePath);
    final base64Data = base64Encode(safeBytes);

    final prompt = '''
You are a nutrition analysis assistant. Analyze the food in the image and the provided ingredients list.
YOU MUST ONLY OUTPUT a JSON object (no markdown, no text outside JSON).

The object must have:
- "foodName": string (main dish/food name)
- "ingredients": array of strings (detected ingredients)
- "calories": number (estimated total calories)
- "protein": number (grams)
- "carbs": number (grams, also known as carbohydrates)
- "fat": number (grams)
- "fiber": number (grams)
- "sugar": number (grams)
- "sodium": number (milligrams)
- "servingSize": string (e.g., "1 serving", "200g", "1 cup")
- "additionalInfo": object (optional vitamins, minerals, health notes)

Provided ingredients: ${jsonEncode(ingredients)}

Example output:
{
  "foodName": "Grilled Chicken Salad",
  "ingredients": ["Chicken breast", "Lettuce", "Tomatoes", "Cucumber", "Olive oil"],
  "calories": 320,
  "protein": 35,
  "carbs": 15,
  "fat": 12,
  "fiber": 5,
  "sugar": 6,
  "sodium": 450,
  "servingSize": "1 serving (250g)",
  "additionalInfo": {
    "vitaminC": "25% DV",
    "iron": "15% DV",
    "healthNote": "High in protein, low in carbs"
  }
}

Return nothing else than the JSON object.
''';

    final body = {
      "contents": [
        {
          "parts": [
            {
              "inline_data": {"mime_type": mimeType, "data": base64Data},
            },
            {"text": prompt},
          ],
        },
      ],
    };

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    final headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };

    final resp = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (resp.statusCode != 200) {
      String errorMessage = 'Gemini API error ${resp.statusCode}';
      try {
        final errorData = jsonDecode(resp.body);
        if (errorData['error'] != null &&
            errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];

          if (resp.statusCode == 403) {
            errorMessage =
                'API access denied. Please enable the Generative Language API in Google Cloud Console.';
          } else if (resp.statusCode == 429) {
            errorMessage = 'API quota exceeded. Please try again later.';
          } else if (resp.statusCode == 401) {
            errorMessage = 'Invalid API key. Please check your Gemini API key.';
          }
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    String modelText = _extractText(decoded);

    if (modelText.isEmpty) {
      throw Exception('No text returned by Gemini: ${resp.body}');
    }

    // Parse JSON strictly
    try {
      final parsed = jsonDecode(modelText);
      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
    } catch (_) {
      // fallback: try regex extract
      final objectMatch = RegExp(
        r'(\{.*\})',
        dotAll: true,
      ).firstMatch(modelText);
      if (objectMatch != null) {
        return jsonDecode(objectMatch.group(1)!) as Map<String, dynamic>;
      }
    }

    // If still failing, return basic structure
    return {
      "foodName": ingredients.isNotEmpty ? ingredients.join(", ") : "Unknown",
      "ingredients": ingredients,
      "calories": 0,
      "protein": 0,
      "carbs": 0,
      "fat": 0,
      "fiber": 0,
      "sugar": 0,
      "sodium": 0,
      "servingSize": "1 serving",
    };
  }

  /// Get text recommendations from Gemini (for onboarding, nutrition advice, etc.)
  Future<String> getTextRecommendations(String prompt) async {
    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    };

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    final headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };

    final resp = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (resp.statusCode != 200) {
      String errorMessage = 'Gemini API error ${resp.statusCode}';
      try {
        final errorData = jsonDecode(resp.body);
        if (errorData['error'] != null &&
            errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];

          if (resp.statusCode == 403) {
            errorMessage =
                'API access denied. Please enable the Generative Language API in Google Cloud Console.';
          } else if (resp.statusCode == 429) {
            errorMessage = 'API quota exceeded. Please try again later.';
          } else if (resp.statusCode == 401) {
            errorMessage = 'Invalid API key. Please check your Gemini API key.';
          }
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final modelText = _extractText(decoded);

    if (modelText.isEmpty) {
      throw Exception('No text returned by Gemini: ${resp.body}');
    }

    return modelText;
  }

  Future<List<Map<String, dynamic>>> generateRecipesFromIngredients(
    List<String> ingredients, {
    int maxRecipes = 8,
  }) async {
    final prompt = '''
You are a recipe generator. ONLY OUTPUT a JSON ARRAY (no markdown, explanation or extraneous text).
Return EXACTLY $maxRecipes recipe objects that can be made using the provided ingredients.

CRITICAL REQUIREMENTS:
1. Generate ONLY food, drink, and edible recipes. DO NOT generate beauty products, face masks, skincare items, or any non-edible items.
2. Focus exclusively on recipes for meals, snacks, beverages, desserts, and other consumable food items.
3. PRIORITIZE recipes that use MULTIPLE ingredients from the provided list. The best recipes should incorporate as many of the detected ingredients as possible.
4. Each recipe should clearly utilize at least 2-3 of the provided ingredients as main components.
5. You may add common pantry items (salt, pepper, oil, water, etc.) but the core of each recipe should feature the provided ingredients.

IMPORTANT: Each recipe object MUST include ALL of these fields:

{
  "name": string (recipe name),
  "description": string (brief description mentioning which detected ingredients are used),
  "ingredients": array of strings (complete ingredient list with quantities - HIGHLIGHT the detected ingredients),
  "steps": array of strings (detailed cooking steps),
  "nutrition": {
    "calories": number (total calories per serving),
    "protein": number (grams),
    "carbs": number (grams),
    "fat": number (grams),
    "fiber": number (grams),
    "sugar": number (grams),
    "sodium": number (milligrams)
  },
  "prepTimeMinutes": number,
  "cookTimeMinutes": number,
  "servings": number
}

Example with detected ingredients [Chicken Breast, Tomato, Garlic, Olive Oil]:
[
  {
    "name": "Garlic Tomato Chicken",
    "description": "A flavorful one-pan dish featuring chicken breast, fresh tomatoes, and aromatic garlic from your scanned ingredients",
    "ingredients": ["2 chicken breasts (from scan)", "4 tomatoes, diced (from scan)", "4 cloves garlic, minced (from scan)", "2 tbsp olive oil (from scan)", "1 tsp dried basil", "Salt and pepper to taste", "Fresh parsley for garnish"],
    "steps": [
      "Season chicken breasts with salt and pepper",
      "Heat olive oil in a large skillet over medium-high heat",
      "Add minced garlic and sauté for 30 seconds until fragrant",
      "Add chicken breasts and cook for 5-6 minutes per side until golden",
      "Add diced tomatoes and basil, reduce heat to medium",
      "Simmer for 10-12 minutes until chicken is cooked through and tomatoes have broken down",
      "Garnish with fresh parsley and serve hot"
    ],
    "nutrition": {
      "calories": 320,
      "protein": 42,
      "carbs": 12,
      "fat": 12,
      "fiber": 3,
      "sugar": 7,
      "sodium": 380
    },
    "prepTimeMinutes": 10,
    "cookTimeMinutes": 20,
    "servings": 2
  }
]

Available ingredients (USE THESE IN YOUR RECIPES):
${jsonEncode(ingredients)}

Generate $maxRecipes diverse recipes that maximize the use of these detected ingredients. Return nothing else than the JSON array.
''';

    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
    };

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
    );

    final headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': apiKey,
    };

    final resp = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (resp.statusCode != 200) {
      String errorMessage = 'Gemini API error ${resp.statusCode}';
      try {
        final errorData = jsonDecode(resp.body);
        if (errorData['error'] != null &&
            errorData['error']['message'] != null) {
          errorMessage = errorData['error']['message'];

          if (resp.statusCode == 403) {
            errorMessage =
                'API access denied. Please enable the Generative Language API in Google Cloud Console.';
          } else if (resp.statusCode == 429) {
            errorMessage = 'API quota exceeded. Please try again later.';
          } else if (resp.statusCode == 401) {
            errorMessage = 'Invalid API key. Please check your Gemini API key.';
          }
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    final modelText = _extractText(decoded);

    if (modelText.isEmpty) {
      throw Exception('No text returned by Gemini: ${resp.body}');
    }

    // Parse JSON strictly, fallback to regex array extraction
    try {
      final parsed = jsonDecode(modelText);
      if (parsed is List) {
        return parsed.map<Map<String, dynamic>>((e) {
          final map = Map<String, dynamic>.from(e);
          // Ensure steps is a list
          if (map['steps'] != null) {
            map['steps'] = _normalizeInstructions(map['steps']);
          }
          return map;
        }).toList();
      } else if (parsed is Map) {
        final map = Map<String, dynamic>.from(parsed);
        if (map['steps'] != null) {
          map['steps'] = _normalizeInstructions(map['steps']);
        }
        return [map];
      }
    } catch (_) {
      final arrayMatch = RegExp(
        r'(\[.*\])',
        dotAll: true,
      ).firstMatch(modelText);
      if (arrayMatch != null) {
        try {
          return (jsonDecode(arrayMatch.group(1)!) as List<dynamic>)
              .map<Map<String, dynamic>>((e) {
            final map = Map<String, dynamic>.from(e);
            if (map['steps'] != null) {
              map['steps'] = _normalizeInstructions(map['steps']);
            }
            return map;
          }).toList();
        } catch (_) {
          // Continue to fallback
        }
      }
    }

    // Last resort: return empty list
    throw Exception('Failed to parse recipes from Gemini response');
  }
}
