import 'dart:async';
import 'package:flutter/material.dart';
import 'package:plately_app/core/services/voice_command_service.dart';
import 'package:plately_app/core/services/api_service.dart';

/// Floating microphone button for voice commands.
///
/// Shows a pulsing animation while listening,
/// displays recognized text in a bottom sheet,
/// routes the command to the appropriate handler,
/// and provides a text input fallback if microphone is unavailable.
class VoiceCommandFab extends StatefulWidget {
  final String userId;
  final void Function(String message)? onAssistantReply;
  final void Function(String item)? onAddToShoppingList;

  const VoiceCommandFab({
    super.key,
    required this.userId,
    this.onAssistantReply,
    this.onAddToShoppingList,
  });

  @override
  State<VoiceCommandFab> createState() => _VoiceCommandFabState();
}

class _VoiceCommandFabState extends State<VoiceCommandFab>
    with SingleTickerProviderStateMixin {
  final VoiceCommandService _voice = VoiceCommandService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _recognizedText = '';
  bool _isListening = false;
  bool _isProcessing = false;
  StreamSubscription? _textSub;
  StreamSubscription? _statusSub;
  Timer? _safetyResetTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _textSub = _voice.onText.listen((text) {
      if (mounted) {
        setState(() => _recognizedText = text);
      }
    });

    _statusSub = _voice.onStatus.listen((status) {
      if (!mounted) return;
      if (status == VoiceStatus.done && _recognizedText.isNotEmpty) {
        _handleCommand(_recognizedText);
      }
      if (status == VoiceStatus.done || status == VoiceStatus.error) {
        _safetyResetTimer?.cancel();
        _pulseController.stop();
        _pulseController.reset();
        setState(() => _isListening = false);
      }
    });
  }

  @override
  void dispose() {
    _safetyResetTimer?.cancel();
    _pulseController.dispose();
    _textSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _safetyResetTimer?.cancel();
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
      await _voice.stopListening();
    } else {
      setState(() {
        _recognizedText = '';
      });

      final started = await _voice.startListening();
      if (!mounted) return;

      if (started) {
        setState(() => _isListening = true);
        _pulseController.repeat(reverse: true);

        // Safety fallback timer to prevent button from ever hanging
        _safetyResetTimer?.cancel();
        _safetyResetTimer = Timer(const Duration(seconds: 10), () {
          if (mounted && _isListening) {
            _pulseController.stop();
            _pulseController.reset();
            setState(() => _isListening = false);
            _voice.stopListening();
          }
        });
      } else {
        // Voice recognition unavailable or permission denied — fallback to text dialog
        setState(() => _isListening = false);
        _pulseController.stop();
        _pulseController.reset();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone unavailable. You can type directly to Plately AI!'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _showTextInputDialog();
      }
    }
  }

  void _showTextInputDialog() {
    if (!mounted) return;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.smart_toy, color: Color(0xFF4FC3F7), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Plately AI Kitchen Assistant',
                    style: TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.54), size: 18),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ask anything: "What can I cook?", "Add milk to shopping list", or "Set timer for 10 minutes".',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type your kitchen question...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
                        ),
                      ),
                      onSubmitted: (val) {
                        final trimmed = val.trim();
                        if (trimmed.isNotEmpty) {
                          Navigator.pop(sheetCtx);
                          _handleCommand(trimmed);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    onPressed: () {
                      final trimmed = textController.text.trim();
                      if (trimmed.isNotEmpty) {
                        Navigator.pop(sheetCtx);
                        _handleCommand(trimmed);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCommand(String text) async {
    final intent = _voice.parseCommand(text);

    setState(() => _isProcessing = true);

    try {
      switch (intent.type) {
        case VoiceIntentType.askRecipe:
        case VoiceIntentType.askAssistant:
          final api = ApiService();
          final result = await api.chatWithAssistant(
            messages: [
              {'role': 'user', 'content': text},
            ],
          );
          final reply = result['data']?['content'] ?? 'I couldn\'t process that. Try asking again!';
          widget.onAssistantReply?.call(reply);
          _showReply(reply, queryText: text);
          break;

        case VoiceIntentType.addToShoppingList:
          final param = intent.parameter ?? text;
          widget.onAddToShoppingList?.call(param);
          _showReply('Added "$param" to your shopping list! 🛒', queryText: text);
          break;

        case VoiceIntentType.setTimer:
          _showReply('Timer set for ${intent.parameter}! ⏰', queryText: text);
          break;
      }
    } catch (e) {
      _showReply('Sorry, something went wrong. Please try again.', queryText: text);
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showReply(String message, {String? queryText}) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smart_toy, color: Color(0xFF4FC3F7), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Plately AI',
                  style: TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54), size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (queryText != null && queryText.isNotEmpty) ...[
              Text(
                '"$queryText"',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _pulseAnimation.value : 1.0,
          child: FloatingActionButton(
            heroTag: 'voice_fab',
            onPressed: _isProcessing ? null : _toggleListening,
            backgroundColor: _isListening
                ? const Color(0xFFEF5350)
                : const Color(0xFF4FC3F7),
            elevation: _isListening ? 12 : 6,
            child: _isProcessing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onSurface,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 28,
                  ),
          ),
        );
      },
    );
  }
}
