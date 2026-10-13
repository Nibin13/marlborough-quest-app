// Google AI Edge Eloquent - Web Speech & Audio Helper
window.eloquentSpeech = {
  recognition: null,
  isListening: false,
  onResultCallback: null,
  onErrorCallback: null,
  onStatusCallback: null,

  isSupported: function() {
    return ('webkitSpeechRecognition' in window) || ('SpeechRecognition' in window);
  },

  startListening: function(lang, onResult, onError, onStatus) {
    var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!SpeechRecognition) {
      if (onError) onError('Speech recognition is not supported in this browser. Please use Chrome or Edge.');
      return false;
    }

    if (this.recognition && this.isListening) {
      try { this.recognition.stop(); } catch(e) {}
    }

    var self = this;
    var recog = new SpeechRecognition();
    recog.continuous = true;
    recog.interimResults = true;
    // Auto-detect user device language for accurate transcription across accents
    recog.lang = navigator.language || lang || 'en-US';

    recog.onstart = function() {
      self.isListening = true;
      if (onStatus) onStatus('recording');
    };

    var accumulatedFinal = '';

    recog.onresult = function(event) {
      var interimTranscript = '';
      var currentFinal = '';

      for (var i = event.resultIndex; i < event.results.length; ++i) {
        if (event.results[i].isFinal) {
          currentFinal += event.results[i][0].transcript;
        } else {
          interimTranscript += event.results[i][0].transcript;
        }
      }

      if (currentFinal) {
        accumulatedFinal += (accumulatedFinal ? ' ' : '') + currentFinal.trim();
      }

      var fullText = accumulatedFinal;
      if (interimTranscript) {
        fullText += (fullText ? ' ' : '') + interimTranscript.trim();
      }

      if (onResult) {
        onResult(JSON.stringify({
          final: currentFinal.trim(),
          interim: interimTranscript.trim(),
          full: fullText.trim()
        }));
      }
    };

    recog.onerror = function(event) {
      self.isListening = false;
      if (onStatus) onStatus('idle');
      if (event.error === 'no-speech') {
        return;
      }
      if (event.error === 'not-allowed' || event.error === 'service-not-allowed') {
        if (onError) onError('Microphone access was blocked. Please tap allow microphone in your browser address bar.');
        return;
      }
      if (event.error === 'network') {
        if (onError) onError('Browser speech service timed out. Tap the microphone again or try the sample presets!');
        return;
      }
      if (onError) onError(event.error || 'Microphone error occurred');
    };

    recog.onend = function() {
      self.isListening = false;
      if (onStatus) onStatus('idle');
    };

    try {
      recog.start();
      this.recognition = recog;
      return true;
    } catch (e) {
      if (onError) onError(e.message);
      return false;
    }
  },

  stopListening: function() {
    if (this.recognition) {
      try {
        this.recognition.stop();
      } catch (e) {}
      this.isListening = false;
    }
  },

  speakText: function(text) {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
      var utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 1.0;
      utterance.pitch = 1.0;
      window.speechSynthesis.speak(utterance);
      return true;
    }
    return false;
  },

  stopSpeaking: function() {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }
  }
};
