/// AI calls go through the `geminiGenerateContent` Cloud Function.
/// The Gemini API key lives in Secret Manager and is not compiled into the app.
class AiConfig {
  static const String gatewayFunction = 'geminiGenerateContent';
}
