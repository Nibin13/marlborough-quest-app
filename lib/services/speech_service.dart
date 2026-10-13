// Platform interface for Speech & Audio
import 'dart:convert';

// Conditional import for web
import 'speech_web_bridge.dart' if (dart.library.io) 'speech_dummy_bridge.dart' as bridge;

class SpeechResult {
  final String finalTranscript;
  final String interimTranscript;
  SpeechResult({required this.finalTranscript, required this.interimTranscript});
}

class SpeechService {
  static bool get isSupported => bridge.isSpeechSupported();

  static bool startListening({
    required Function(SpeechResult) onResult,
    required Function(String) onError,
    required Function(bool isListening) onStatusChange,
  }) {
    return bridge.startWebListening(
      onResult: (jsonStr) {
        try {
          final data = jsonDecode(jsonStr);
          onResult(SpeechResult(
            finalTranscript: data['final'] ?? '',
            interimTranscript: data['interim'] ?? '',
          ));
        } catch (_) {}
      },
      onError: onError,
      onStatusChange: onStatusChange,
    );
  }

  static void stopListening() {
    bridge.stopWebListening();
  }

  static void speakText(String text) {
    bridge.speakWebText(text);
  }

  static void stopSpeaking() {
    bridge.stopWebSpeaking();
  }
}
