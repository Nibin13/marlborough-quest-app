import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

final stt.SpeechToText _speech = stt.SpeechToText();
bool _isInitialized = false;
String? _detectedLocaleId;

bool isSpeechSupported() => true;

bool startWebListening({
  required void Function(String) onResult,
  required void Function(String) onError,
  required void Function(bool) onStatusChange,
}) {
  Future<void> beginListening() async {
    onStatusChange(true);
    try {
      if (_detectedLocaleId == null) {
        final sysLoc = await _speech.systemLocale();
        _detectedLocaleId = sysLoc?.localeId;
      }
    } catch (_) {}

    await _speech.listen(
      onResult: (result) {
        final payload = jsonEncode({
          'final': result.finalResult ? result.recognizedWords : '',
          'interim': result.finalResult ? '' : result.recognizedWords,
          'full': result.recognizedWords,
        });
        onResult(payload);
      },
      localeId: _detectedLocaleId,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        autoPunctuation: true,
        enableHapticFeedback: true,
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
        onError('Microphone permission was denied or speech recognition is unavailable.');
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
