import 'package:flutter/material.dart';
import '../services/gemini_live_voice_broker_service.dart';

class GeminiVoiceBrokerOrb extends StatefulWidget {
  final VoiceBrokerState state;
  final List<double> waveformBars;
  final VoidCallback onTap;

  const GeminiVoiceBrokerOrb({
    super.key,
    required this.state,
    required this.waveformBars,
    required this.onTap,
  });

  @override
  State<GeminiVoiceBrokerOrb> createState() => _GeminiVoiceBrokerOrbState();
}

class _GeminiVoiceBrokerOrbState extends State<GeminiVoiceBrokerOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpeaking = widget.state == VoiceBrokerState.speaking;
    final isListening = widget.state == VoiceBrokerState.listening;
    final isThinking = widget.state == VoiceBrokerState.thinking;

    Color primaryGlow = theme.colorScheme.primary;
    Color secondaryGlow = theme.colorScheme.secondary;

    if (isListening) {
      primaryGlow = theme.colorScheme.error;
      secondaryGlow = theme.colorScheme.tertiary;
    } else if (isSpeaking) {
      primaryGlow = theme.colorScheme.primary;
      secondaryGlow = theme.colorScheme.primaryContainer;
    } else if (isThinking) {
      primaryGlow = theme.colorScheme.tertiary;
      secondaryGlow = theme.colorScheme.secondary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulseValue = _pulseController.value;
              final scale = 1.0 + (isSpeaking || isListening ? (pulseValue * 0.12) : (pulseValue * 0.04));

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryGlow.withValues(alpha: 0.9),
                        secondaryGlow.withValues(alpha: 0.6),
                        theme.colorScheme.surface,
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGlow.withValues(alpha: isSpeaking || isListening ? 0.6 : 0.25),
                        blurRadius: isSpeaking || isListening ? 32 : 16,
                        spreadRadius: isSpeaking || isListening ? 8 : 2,
                      ),
                      BoxShadow(
                        color: secondaryGlow.withValues(alpha: 0.3),
                        blurRadius: 48,
                        spreadRadius: 10,
                      ),
                    ],
                    border: Border.all(
                      color: primaryGlow.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isListening
                          ? Icons.mic_rounded
                          : isThinking
                              ? Icons.psychology_rounded
                              : isSpeaking
                                  ? Icons.graphic_eq_rounded
                                  : Icons.smart_toy_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Real-time Audio Frequency Waveform Visualizer
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(
              widget.waveformBars.length,
              (index) {
                final barHeight = (widget.waveformBars[index] * 32.0).clamp(4.0, 32.0);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 3.5,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: primaryGlow.withValues(
                      alpha: (0.4 + (widget.waveformBars[index] * 0.6)).clamp(0.4, 1.0),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
