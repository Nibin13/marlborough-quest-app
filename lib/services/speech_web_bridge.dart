// Web implementation of speech recognition bridge using dart:js_interop
import 'dart:js_interop';

@JS('eloquentSpeech.isSupported')
external bool _isSupported();

@JS('eloquentSpeech.startListening')
external bool _startListening(
  JSString lang,
  JSFunction onResult,
  JSFunction onError,
  JSFunction onStatus,
);

@JS('eloquentSpeech.stopListening')
external void _stopListening();

@JS('eloquentSpeech.speakText')
external bool _speakText(JSString text);

@JS('eloquentSpeech.stopSpeaking')
external void _stopSpeaking();

bool isSpeechSupported() {
  try {
    return _isSupported();
  } catch (_) {
    return false;
  }
}

bool startWebListening({
  required void Function(String) onResult,
  required void Function(String) onError,
  required void Function(bool) onStatusChange,
}) {
  try {
    final jsOnResult = ((JSString res) {
      onResult(res.toDart);
    }).toJS;

    final jsOnError = ((JSString err) {
      onError(err.toDart);
    }).toJS;

    final jsOnStatus = ((JSString status) {
      onStatusChange(status.toDart == 'recording');
    }).toJS;

    return _startListening('en-US'.toJS, jsOnResult, jsOnError, jsOnStatus);
  } catch (e) {
    onError(e.toString());
    return false;
  }
}

void stopWebListening() {
  try {
    _stopListening();
  } catch (_) {}
}

void speakWebText(String text) {
  try {
    _speakText(text.toJS);
  } catch (_) {}
}

void stopWebSpeaking() {
  try {
    _stopSpeaking();
  } catch (_) {}
}
