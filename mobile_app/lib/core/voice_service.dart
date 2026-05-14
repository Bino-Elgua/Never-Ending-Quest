import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _isSttInitialized = false;

  VoiceService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(0.9); // Deeper for DM feel
    await _tts.setSpeechRate(0.5);
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _tts.speak(text);
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<bool> startListening(Function(String) onResult) async {
    if (!_isSttInitialized) {
      _isSttInitialized = await _stt.initialize();
    }

    if (_isSttInitialized) {
      _stt.listen(onResult: (result) {
        onResult(result.recognizedWords);
      });
      return true;
    }
    return false;
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});
