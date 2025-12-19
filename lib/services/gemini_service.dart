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
You are a helpful assistant that must identify the different ingredients / food items in the image. 
YOU MUST ONLY OUTPUT a JSON array (no markdown, no text outside JSON).
Each element must have:
- "name": string, the detected food/ingredient
- "confidence": number between 0 and 1

Example:
[
  {"name":"Tomato","confidence":0.93},
  {"name":"Onion","confidence":0.87}
]
Return nothing else.
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

  Future<List<Map<String, dynamic>>> generateRecipesFromIngredients(
    List<String> ingredients, {
    int maxRecipes = 8,
  }) async {
    final prompt = '''
You are a recipe generator. ONLY OUTPUT a JSON ARRAY (no markdown, explanation or extraneous text).
Return EXACTLY $maxRecipes recipe objects that can be made using the provided ingredients.

IMPORTANT: Each recipe object MUST include ALL of these fields:

{
  "name": string (recipe name),
  "description": string (brief description),
  "ingredients": array of strings (complete ingredient list with quantities),
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

Example:
[
  {
    "name": "Tomato Basil Pasta",
    "description": "A simple and delicious Italian pasta dish with fresh tomatoes and basil",
    "ingredients": ["200g pasta", "3 tomatoes, diced", "2 cloves garlic, minced", "Fresh basil leaves", "2 tbsp olive oil", "Salt and pepper to taste", "Parmesan cheese"],
    "steps": [
      "Boil pasta according to package instructions until al dente",
      "Heat olive oil in a pan and sauté garlic until fragrant",
      "Add diced tomatoes and cook for 5-7 minutes until softened",
      "Toss cooked pasta with tomato sauce and fresh basil",
      "Season with salt and pepper, garnish with Parmesan cheese"
    ],
    "nutrition": {
      "calories": 420,
      "protein": 12,
      "carbs": 65,
      "fat": 14,
      "fiber": 5,
      "sugar": 6,
      "sodium": 320
    },
    "prepTimeMinutes": 10,
    "cookTimeMinutes": 15,
    "servings": 2
  }
]

Available ingredients:
${jsonEncode(ingredients)}

Generate $maxRecipes diverse recipes. Return nothing else than the JSON array.
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
