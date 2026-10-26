import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Service for handling voice commands in the kitchen.
///
/// Supports commands like:
/// - "What can I cook?" → triggers recipe suggestions
/// - "Add tomatoes to shopping list" → adds item
/// - "Start timer for 5 minutes" → starts timer
class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  Timer? _timeoutTimer;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;

  final _textController = StreamController<String>.broadcast();
  final _statusController = StreamController<VoiceStatus>.broadcast();

  /// Stream of recognized text (updates as user speaks)
  Stream<String> get onText => _textController.stream;

  /// Stream of status changes (listening, done, error)
  Stream<VoiceStatus> get onStatus => _statusController.stream;

  /// Initialize the speech recognition engine.
  /// Must be called once before using [startListening].
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('[Voice] Speech error: ${error.errorMsg}');
          _cancelTimer();
          _isListening = false;
          _statusController.add(VoiceStatus.error);
        },
        onStatus: (status) {
          debugPrint('[Voice] Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _cancelTimer();
            _isListening = false;
            _statusController.add(VoiceStatus.done);
          }
        },
      );

      if (_isInitialized) {
        debugPrint('[Voice] Initialized successfully');
        _statusController.add(VoiceStatus.ready);
      } else {
        debugPrint('[Voice] Initialized returned false');
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('[Voice] Init exception: $e');
      _isInitialized = false;
      return false;
    }
  }

  void _cancelTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Start listening for voice input.
  /// Returns `true` if listening started successfully, `false` otherwise.
  Future<bool> startListening() async {
    try {
      if (!_isInitialized) {
        final ok = await initialize();
        if (!ok) {
          _isListening = false;
          _statusController.add(VoiceStatus.error);
          return false;
        }
      }

      if (_isListening) return true;

      _isListening = true;
      _statusController.add(VoiceStatus.listening);

      // Safety timeout: automatically reset after 8 seconds of silence/no final result
      _cancelTimer();
      _timeoutTimer = Timer(const Duration(seconds: 8), () {
        debugPrint('[Voice] Auto-stopping after silence timeout');
        stopListening();
      });

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _textController.add(result.recognizedWords);
          if (result.finalResult) {
            _cancelTimer();
            _isListening = false;
            _statusController.add(VoiceStatus.done);
          }
        },
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );
      return true;
    } catch (e) {
      debugPrint('[Voice] startListening failed: $e');
      _cancelTimer();
      _isListening = false;
      _statusController.add(VoiceStatus.error);
      return false;
    }
  }

  /// Stop listening immediately and ensure state is reset.
  Future<void> stopListening() async {
    _cancelTimer();
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('[Voice] stopListening exception: $e');
    } finally {
      _isListening = false;
      _statusController.add(VoiceStatus.done);
    }
  }

  /// Parse a voice command and return the intent.
  VoiceIntent parseCommand(String text) {
    final lower = text.toLowerCase().trim();

    // Recipe-related
    if (lower.contains('what can i cook') ||
        lower.contains('recipe') ||
        lower.contains('suggest') ||
        lower.contains('what should i make')) {
      return VoiceIntent(
        type: VoiceIntentType.askRecipe,
        text: text,
      );
    }

    // Shopping list
    if (lower.contains('add') && lower.contains('shopping')) {
      final match = RegExp(r'add (.+?) to', caseSensitive: false).firstMatch(lower);
      final item = match?.group(1) ?? lower.replaceAll(RegExp(r'add|to|shopping|list'), '').trim();
      return VoiceIntent(
        type: VoiceIntentType.addToShoppingList,
        text: text,
        parameter: item,
      );
    }

    // Timer
    if (lower.contains('timer') || lower.contains('set timer')) {
      final match = RegExp(r'(\d+)\s*(minute|min|second|sec|hour|hr)', caseSensitive: false).firstMatch(lower);
      return VoiceIntent(
        type: VoiceIntentType.setTimer,
        text: text,
        parameter: match?.group(0) ?? '5 minutes',
      );
    }

    // General question → send to chat assistant
    return VoiceIntent(
      type: VoiceIntentType.askAssistant,
      text: text,
    );
  }

  void dispose() {
    _cancelTimer();
    try {
      _speech.stop();
    } catch (_) {}
    _textController.close();
    _statusController.close();
  }
}

enum VoiceStatus { ready, listening, done, error }

enum VoiceIntentType { askRecipe, addToShoppingList, setTimer, askAssistant }

class VoiceIntent {
  final VoiceIntentType type;
  final String text;
  final String? parameter;

  const VoiceIntent({
    required this.type,
    required this.text,
    this.parameter,
  });

  @override
  String toString() => 'VoiceIntent($type, text="$text", param="$parameter")';
}
