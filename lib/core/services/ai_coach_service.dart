import 'package:google_generative_ai/google_generative_ai.dart';

class AiCoachService {
  AiCoachService({String? apiKey, String? model})
      : _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY'),
        _model = _normalizeModel(
          model ??
              const String.fromEnvironment(
                'GEMINI_MODEL',
                defaultValue: 'gemini-1.0-pro',
              ),
        );

  final String _apiKey;
  final String _model;

  static String _normalizeModel(String value) {
    const prefix = 'models/';
    if (value.startsWith(prefix)) {
      return value.substring(prefix.length);
    }
    return value;
  }

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
      model: _model,
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
