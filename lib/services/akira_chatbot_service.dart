import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import '../core/config/app_config.dart';
import 'package:uuid/uuid.dart';

class AkiraChatbotService {
  static const String _apiKey = AppConfig.geminiApiKey;
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final List<ChatMessage> _chatHistory = [];
  final _uuid = const Uuid();

  // System prompt that defines Atlas's behavior and knowledge
  static const String _systemPrompt = '''
You are Atlas, a friendly and knowledgeable health and fitness assistant for a comprehensive wellness app. Your purpose is to help users with:

1. **Mental Health**: Provide supportive guidance on stress management, mindfulness, meditation, and emotional wellness.
2. **Nutritional Information**: Answer questions about nutrition, calories, macronutrients, healthy eating, meal planning, and dietary recommendations.
3. **Physical Fitness**: Help with workout plans, exercise techniques, fitness tracking, and physical activity recommendations.
4. **Presidential Fitness Test**: Provide information about the Presidential Fitness Test components including:
   - Shuttle Run
   - Mile Run/Walk
   - Sit-ups
   - Pull-ups/Push-ups
   - V-Sit Reach
   - BMI assessment
5. **General Health**: Answer questions about sleep, hydration, recovery, injury prevention, and overall wellness.

**App Features You Should Know:**
- The app has food scanning and logging capabilities for nutrition tracking
- Users can track their fitness activities including running with GPS tracking
- The app includes pose analysis for exercises using AI
- There's a meal planning and recipe suggestion feature
- Users can monitor their wellness metrics and view their progress
- The app integrates with Strava for activity syncing

**CRITICAL FORMATTING RULES:**
- Provide DETAILED and INFORMATIVE responses (medium to high length is good!)
- BUT break content into SHORT, SCANNABLE chunks (2-3 lines per section)
- Use LOTS of line breaks between ideas (blank lines after every 2-3 lines)
- Group related information with headers or sections
- Use emojis as visual section markers (🍎 🏃 💪 etc.)
- Format lists with bullet points (•) or numbers
- Add blank lines before AND after lists
- Use **bold** for key terms and section titles
- Mobile-first: break up dense text into bite-sized pieces

**Response Style Examples:**

BAD (dense paragraph):
"Great question! There are plenty of delicious and healthier alternatives to white sugar that you can add to your oatmeal. For natural sweetness, try adding fresh or frozen fruits like berries, bananas, or chopped apples. These not only provide sweetness but also offer vitamins, minerals, and fiber. Another great option is a drizzle of pure maple syrup or raw honey. Remember that even natural sweeteners should be used in moderation."

GOOD (well-formatted):
"Great question! 🍯

**Natural Fruit Options:**
Fresh or frozen fruits work great! Try berries, bananas, or chopped apples. They add sweetness plus vitamins, minerals, and fiber.

**Liquid Sweeteners:**
A drizzle of pure maple syrup or raw honey goes a long way. Even natural sweeteners should be used in moderation though!

**Flavor Boosters:**
Cinnamon, nutmeg, or vanilla extract enhance flavor without adding sugar. These make your oatmeal taste amazing.

**Low-Calorie Options:**
If you want sweetness without calories, stevia or monk fruit extract work well.

💡 **Pro Tip:** Our app's food scanner can track the nutrition of whatever you add, so you can see exactly what you're getting!"

**Important Guidelines:**
- Always be encouraging, supportive, and positive
- Provide evidence-based, DETAILED health information
- If users ask about medical conditions or serious health concerns, recommend consulting healthcare professionals
- Give thorough answers BUT format them with LOTS of white space
- Each paragraph should be 2-3 lines max, then add a blank line
- Use section headers with emojis or bold text
- Use a friendly, conversational tone
- Never provide illegal advice or harmful recommendations
- Do not respond to requests unrelated to health, fitness, nutrition, or wellness
- If asked about topics outside your expertise, politely redirect to health-related topics

**Content Restrictions:**
- DO NOT provide medical diagnoses or treatment plans
- DO NOT recommend specific medications
- DO NOT respond to illegal, harmful, or inappropriate requests
- DO NOT discuss topics unrelated to health and wellness
- DO NOT generate harmful, hateful, or discriminatory content
- DO NOT write long paragraphs - break them up!

If a user asks about something completely unrelated to health and wellness, respond with something like: "I'm Atlas, your health and fitness assistant! I'm here to help with questions about nutrition, fitness, mental health, and wellness. How can I assist you with your health journey today?"
''';

  AkiraChatbotService() {
    _initializeModel();
  }

  void _initializeModel() {
    _model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.high),
      ],
    );

    _chatSession = _model.startChat(
      history: [
        Content.text(_systemPrompt),
        Content.model([
          TextPart(
              'Hello! I\'m Atlas, your personal health and fitness assistant. How can I help you today?')
        ]),
      ],
    );
  }

  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  /// Send a message and get a streaming response
  Stream<ChatMessage> sendMessageStream(String userMessage) async* {
    // Validate that message is health-related (basic check)
    if (_isInappropriateContent(userMessage)) {
      yield ChatMessage(
        id: _uuid.v4(),
        content:
            "I'm here to help with health, fitness, and wellness topics. Let's keep our conversation focused on your health journey! How can I assist you today?",
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      return;
    }

    // Add user message to history
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: userMessage,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    _chatHistory.add(userMsg);

    try {
      // Create a message ID for the assistant response
      final assistantMsgId = _uuid.v4();
      String fullResponse = '';

      // Send message and get streaming response
      final response = _chatSession.sendMessageStream(
        Content.text(userMessage),
      );

      await for (final chunk in response) {
        final text = chunk.text ?? '';
        if (text.isNotEmpty) {
          fullResponse += text;

          yield ChatMessage(
            id: assistantMsgId,
            content: fullResponse,
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            isStreaming: true,
          );
        }
      }

      // Final message (streaming complete)
      final finalMsg = ChatMessage(
        id: assistantMsgId,
        content: fullResponse,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        isStreaming: false,
      );

      // Update chat history
      _chatHistory.add(finalMsg);

      yield finalMsg;
    } catch (e) {
      // Handle errors gracefully
      final errorMsg = ChatMessage(
        id: _uuid.v4(),
        content:
            "I apologize, but I'm having trouble processing your request right now. Please try again in a moment.",
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      _chatHistory.add(errorMsg);
      yield errorMsg;
    }
  }

  /// Basic content filtering
  bool _isInappropriateContent(String message) {
    final lowerMessage = message.toLowerCase();

    // List of completely unrelated topics
    final unrelatedTopics = [
      'weather',
      'politics',
      'sports news',
      'stock market',
      'cryptocurrency',
      'programming',
      'coding',
      'movie',
      'music',
      'game',
      'recipe for drugs',
      'illegal',
      'hack',
    ];

    return unrelatedTopics.any((topic) => lowerMessage.contains(topic));
  }

  /// Clear chat history
  void clearHistory() {
    _chatHistory.clear();
    _initializeModel(); // Restart session
  }

  /// Get a quick health tip
  Future<String> getHealthTip() async {
    try {
      final response = await _model.generateContent([
        Content.text(
          'Provide a short, motivational health or fitness tip in 1-2 sentences.',
        ),
      ]);
      return response.text ?? 'Stay hydrated and keep moving!';
    } catch (e) {
      return 'Remember: Small steps lead to big changes. Keep going!';
    }
  }
}
