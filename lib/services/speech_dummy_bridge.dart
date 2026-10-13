import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final stt.SpeechToText _speech = stt.SpeechToText();
bool _isInitialized = false;

bool isSpeechSupported() => true;

bool startWebListening({
  required void Function(String) onResult,
  required void Function(String) onError,
  required void Function(bool) onStatusChange,
}) {
  void beginListening() {
    onStatusChange(true);
    _speech.listen(
      onResult: (result) {
        final payload = jsonEncode({
          'final': result.recognizedWords,
          'interim': '',
        });
        onResult(payload);
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  if (!_isInitialized) {
    _speech.initialize(
      onError: (val) {
        onStatusChange(false);
        onError(val.errorMsg);
      },
      onStatus: (val) {
        onStatusChange(val == 'listening');
      },
    ).then((available) {
      _isInitialized = available;
      if (available) {
        beginListening();
      } else {
        onError('Microphone speech recognition is not available or permission was denied.');
      }
    }).catchError((err) {
      onError(err.toString());
    });
  } else {
    beginListening();
  }

  return true;
}

void stopWebListening() {
  if (_speech.isListening) {
    _speech.stop();
  }
}

void speakWebText(String text) {}

void stopWebSpeaking() {}
