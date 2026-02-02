import 'package:google_generative_ai/google_generative_ai.dart';

class AiCoachService {
  AiCoachService({String? apiKey})
      : _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY');

  final String _apiKey;

  void validate() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Missing GEMINI_API_KEY. Provide it via --dart-define.',
      );
    }
  }

  Future<String> getCoachAdvice({
    required String logsJson,
    required String question,
  }) async {
    validate();

    final model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
    );

    final prompt = '''
You are a helpful fitness and nutrition coach.
Use the last 7 days of logs below to answer the user.

Logs (JSON):
$logsJson

User question:
$question
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('Gemini returned an empty response.');
    }
    return text;
  }
}
