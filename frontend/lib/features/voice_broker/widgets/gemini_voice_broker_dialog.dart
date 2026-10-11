import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../public_marketplace/models/property_item.dart';
import '../models/viewing_appointment_model.dart';
import '../models/voice_broker_message.dart';
import '../services/gemini_live_voice_broker_service.dart';
import 'gemini_voice_broker_orb.dart';

class GeminiVoiceBrokerDialog extends StatefulWidget {
  final PropertyItem property;

  const GeminiVoiceBrokerDialog({super.key, required this.property});

  static Future<void> show(BuildContext context, PropertyItem property) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GeminiVoiceBrokerDialog(property: property),
    );
  }

  @override
  State<GeminiVoiceBrokerDialog> createState() => _GeminiVoiceBrokerDialogState();
}

class _GeminiVoiceBrokerDialogState extends State<GeminiVoiceBrokerDialog> {
  final _service = GeminiLiveVoiceBrokerService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  late VoiceBrokerDialect _selectedDialect;
  final List<VoiceBrokerMessage> _messages = [];
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    final isUAE = widget.property.countryCode == 'AE';
    final currentLang = LocaleController.languageCode;

    if (currentLang == 'en') {
      _selectedDialect = VoiceBrokerDialect.english;
    } else if (currentLang == 'hi') {
      _selectedDialect = VoiceBrokerDialect.hindi;
    } else {
      _selectedDialect = isUAE ? VoiceBrokerDialect.emiratiArabic : VoiceBrokerDialect.egyptianArabic;
    }

    _sendInitialGreeting();
  }

  @override
  void dispose() {
    _service.stopSpeaking();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendInitialGreeting() {
    final greetingMsg = _service.processUserSpeech(
      userSpeechText: 'مرحباً',
      property: widget.property,
      dialect: _selectedDialect,
      conversationHistory: [],
    );

    greetingMsg.then((msg) {
      if (mounted) {
        setState(() {
          _messages.add(msg);
        });
        if (!_isMuted) {
          _service.speakResponseText(msg.text, onComplete: () {
            if (mounted) setState(() {});
          });
        }
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    _textController.clear();
    final now = DateTime.now();

    final userMsg = VoiceBrokerMessage(
      id: 'msg_user_${now.millisecondsSinceEpoch}',
      sender: MessageSender.user,
      text: cleanText,
      timestamp: now,
    );

    setState(() {
      _messages.add(userMsg);
    });
    _scrollToBottom();

    final brokerReply = await _service.processUserSpeech(
      userSpeechText: cleanText,
      property: widget.property,
      dialect: _selectedDialect,
      conversationHistory: _messages,
    );

    if (mounted) {
      setState(() {
        _messages.add(brokerReply);
      });
      _scrollToBottom();

      if (!_isMuted) {
        _service.speakResponseText(brokerReply.text, onComplete: () {
          if (mounted) setState(() {});
        });
      }
    }
  }

  void _toggleMicListening() {
    final currentState = _service.stateNotifier.value;
    if (currentState == VoiceBrokerState.listening) {
      _service.stateNotifier.value = VoiceBrokerState.idle;
    } else {
      _service.stopSpeaking();
      _service.stateNotifier.value = VoiceBrokerState.listening;

      // Simulated voice speech transcription after listening window
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted && _service.stateNotifier.value == VoiceBrokerState.listening) {
          final sampleQuery = _getSampleQueryForDialect(_selectedDialect);
          _handleSendMessage(sampleQuery);
        }
      });
    }
  }

  String _getSampleQueryForDialect(VoiceBrokerDialect dialect) {
    switch (dialect) {
      case VoiceBrokerDialect.egyptianArabic:
        return 'هل الشقة قريبة من محطة المترو والمواصلات؟ واحجزلي موعد معاينة بكرة';
      case VoiceBrokerDialect.emiratiArabic:
        return 'كم شيك بالسنة لهالعقار؟ وهل قريب من محطة المترو والمارينا؟';
      case VoiceBrokerDialect.english:
        return 'Is this property close to the Metro? I would like to book a viewing for tomorrow.';
      case VoiceBrokerDialect.hindi:
        return 'क्या यह संपत्ति मेट्रो स्टेशन के पास है? क्या हम कल देखने का समय बुक कर सकते हैं?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final lang = LocaleController.languageCode;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 16 : 30,
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 780),
        child: Column(
          children: [
            // 1. Top Header with Property Card & Dialect Selector
            _buildTopBar(theme, loc, isMobile, lang),

            // 2. Main Conversational Body
            Expanded(
              child: Stack(
                children: [
                  // Background Subtle Tech Glow
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.4),
                          radius: 0.9,
                          colors: [
                            theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                            theme.colorScheme.surface,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      const SizedBox(height: 12),

                      // Animated Gemini Live Voice Orb
                      ValueListenableBuilder<VoiceBrokerState>(
                        valueListenable: _service.stateNotifier,
                        builder: (context, state, _) {
                          return ValueListenableBuilder<List<double>>(
                            valueListenable: _service.audioWaveformNotifier,
                            builder: (context, waveform, _) {
                              return GeminiVoiceBrokerOrb(
                                state: state,
                                waveformBars: waveform,
                                onTap: _toggleMicListening,
                              );
                            },
                          );
                        },
                      ),

                      // Status Badge
                      _buildStateStatusBadge(theme, loc),
                      const SizedBox(height: 12),

                      // Messages List View
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return _buildMessageItem(theme, msg, loc);
                          },
                        ),
                      ),

                      // Quick Voice Prompt Chips
                      _buildQuickPromptChips(theme, loc),

                      // Bottom Voice Input & Action Bar
                      _buildBottomInputBar(theme, loc, isMobile),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, AppLocalizations loc, bool isMobile, String lang) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Property Thumbnail & Badge
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: widget.property.imageUrls.isNotEmpty
                ? Image.network(
                    widget.property.imageUrls.first,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 44,
                      height: 44,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.apartment, color: theme.colorScheme.onSurfaceVariant, size: 20),
                    ),
                  )
                : Container(
                    width: 44,
                    height: 44,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.apartment, color: theme.colorScheme.onSurfaceVariant, size: 20),
                  ),
          ),
          const SizedBox(width: 12),

          // Property Title & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.property.countryCode == 'AE' ? '🇦🇪 UAE' : '🇪🇬 EGY',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.property.getTitle(lang),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.formatAmount(widget.property.pricePerMonth, langCode: lang)} ${widget.property.currencyCode == 'AED' ? loc.tr('currency_ae') : loc.tr('currency_eg')}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Dialect Dropdown Menu
          _buildDialectDropdown(theme, loc, isMobile),
          const SizedBox(width: 6),

          // Close Dialog
          TashilIconButton(
            icon: Icons.close_rounded,
            tooltip: loc.tr('close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDialectDropdown(ThemeData theme, AppLocalizations loc, bool isMobile) {
    return PopupMenuButton<VoiceBrokerDialect>(
      initialValue: _selectedDialect,
      onSelected: (dialect) {
        setState(() => _selectedDialect = dialect);
        _handleSendMessage('مرحباً، تحدث معي بهذه اللهجة من فضلك.');
      },
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: VoiceBrokerDialect.egyptianArabic,
          child: Row(
            children: [
              const Text('🇪🇬', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                loc.tr('dialectEG'),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: VoiceBrokerDialect.emiratiArabic,
          child: Row(
            children: [
              const Text('🇦🇪', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                loc.tr('dialectAE'),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: VoiceBrokerDialect.english,
          child: Row(
            children: [
              const Text('🇬🇧', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                loc.tr('dialectEN'),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: VoiceBrokerDialect.hindi,
          child: Row(
            children: [
              const Text('🇮🇳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                loc.tr('dialectHI'),
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getDialectFlag(_selectedDialect), style: const TextStyle(fontSize: 14)),
            if (!isMobile) ...[
              const SizedBox(width: 6),
              Text(
                _getDialectLabel(_selectedDialect, loc),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }

  String _getDialectFlag(VoiceBrokerDialect dialect) {
    switch (dialect) {
      case VoiceBrokerDialect.egyptianArabic:
        return '🇪🇬';
      case VoiceBrokerDialect.emiratiArabic:
        return '🇦🇪';
      case VoiceBrokerDialect.english:
        return '🇬🇧';
      case VoiceBrokerDialect.hindi:
        return '🇮🇳';
    }
  }

  String _getDialectLabel(VoiceBrokerDialect dialect, AppLocalizations loc) {
    switch (dialect) {
      case VoiceBrokerDialect.egyptianArabic:
        return loc.tr('dialectEG');
      case VoiceBrokerDialect.emiratiArabic:
        return loc.tr('dialectAE');
      case VoiceBrokerDialect.english:
        return loc.tr('dialectEN');
      case VoiceBrokerDialect.hindi:
        return loc.tr('dialectHI');
    }
  }

  Widget _buildStateStatusBadge(ThemeData theme, AppLocalizations loc) {
    return ValueListenableBuilder<VoiceBrokerState>(
      valueListenable: _service.stateNotifier,
      builder: (context, state, _) {
        String label = loc.tr('voiceBrokerIdle');
        Color color = theme.colorScheme.secondary;
        Color bgColor = theme.colorScheme.secondaryContainer;

        switch (state) {
          case VoiceBrokerState.listening:
            label = loc.tr('voiceBrokerListening');
            color = theme.colorScheme.error;
            bgColor = theme.colorScheme.errorContainer.withValues(alpha: 0.5);
            break;
          case VoiceBrokerState.thinking:
            label = loc.tr('voiceBrokerThinking');
            color = theme.colorScheme.tertiary;
            bgColor = theme.colorScheme.tertiaryContainer;
            break;
          case VoiceBrokerState.speaking:
            label = loc.tr('voiceBrokerSpeaking');
            color = theme.colorScheme.primary;
            bgColor = theme.colorScheme.primaryContainer;
            break;
          case VoiceBrokerState.idle:
            label = loc.tr('voiceBrokerIdle');
            color = theme.colorScheme.secondary;
            bgColor = theme.colorScheme.secondaryContainer;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageItem(ThemeData theme, VoiceBrokerMessage msg, AppLocalizations loc) {
    final isUser = msg.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.smart_toy_rounded, color: theme.colorScheme.primary, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isUser ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_rounded, color: theme.colorScheme.onPrimaryContainer, size: 16),
                ),
              ],
            ],
          ),

          // Render Function Calling Cards
          if (msg.appointmentData != null)
            _buildAppointmentConfirmedCard(theme, msg.appointmentData!, loc),
          if (msg.affordabilityData != null)
            _buildAffordabilityCard(theme, msg.affordabilityData!, loc),
          if (msg.facilitiesData != null && msg.facilitiesData!.isNotEmpty)
            _buildFacilitiesCard(theme, msg.facilitiesData!, loc),
        ],
      ),
    );
  }

  Widget _buildAppointmentConfirmedCard(ThemeData theme, ViewingAppointmentModel appointment, AppLocalizations loc) {
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 8, start: 28, end: 28),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: theme.colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.tr('appointmentBookedSuccess'),
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'CRM Sync ✓',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: theme.colorScheme.outlineVariant, height: 16),
          Row(
            children: [
              Icon(Icons.person_outline, color: theme.colorScheme.onSurfaceVariant, size: 14),
              const SizedBox(width: 6),
              Text(
                '${loc.tr('clientNameLabel')}: ${appointment.clientName}',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, color: theme.colorScheme.onSurfaceVariant, size: 14),
              const SizedBox(width: 6),
              Text(
                '${loc.tr('appointmentDateLabel')}: ${appointment.scheduledDateTime.toString().substring(0, 16)}',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAffordabilityCard(ThemeData theme, AffordabilityResult result, AppLocalizations loc) {
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 8, start: 28, end: 28),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.tr('affordabilityAnalysisTitle'),
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${loc.tr('monthlyInstallmentEst')}: ${result.estimatedMonthlyPayment.toInt()}',
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              result.affordabilityLevel,
              style: TextStyle(
                color: theme.colorScheme.onSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesCard(ThemeData theme, List<FacilityDistanceResult> facilities, AppLocalizations loc) {
    return Container(
      margin: const EdgeInsetsDirectional.only(top: 8, start: 28, end: 28),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: facilities.map((f) {
          IconData icon = Icons.train_rounded;
          if (f.facilityType == 'school') icon = Icons.school_rounded;
          if (f.facilityType == 'mall') icon = Icons.local_mall_rounded;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.facilityName,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  f.travelTimeMinutes,
                  style: TextStyle(
                    color: theme.colorScheme.tertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickPromptChips(ThemeData theme, AppLocalizations loc) {
    final prompts = [
      loc.tr('quickPromptMetro'),
      loc.tr('quickPromptPayment'),
      loc.tr('quickPromptBookViewing'),
      loc.tr('quickPromptSchools'),
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 10, top: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
            label: Text(
              prompts[index],
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11),
            ),
            onPressed: () => _handleSendMessage(prompts[index]),
          );
        },
      ),
    );
  }

  Widget _buildBottomInputBar(ThemeData theme, AppLocalizations loc, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // Audio Mute/Unmute Toggle
          TashilIconButton(
            icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            tooltip: _isMuted ? loc.tr('audioMuted') : loc.tr('audioUnmuted'),
            onPressed: () {
              setState(() {
                _isMuted = !_isMuted;
                if (_isMuted) {
                  _service.stopSpeaking();
                }
              });
            },
          ),
          const SizedBox(width: 4),

          // Text Input Field Fallback
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: loc.tr('sendVoiceMessage'),
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              onSubmitted: _handleSendMessage,
            ),
          ),
          const SizedBox(width: 8),

          // Send Text Button
          TashilIconButton(
            icon: Icons.send_rounded,
            tooltip: loc.tr('send'),
            variant: TashilIconButtonVariant.filled,
            onPressed: () => _handleSendMessage(_textController.text),
          ),
          const SizedBox(width: 6),

          // Live Mic Toggle Button
          ValueListenableBuilder<VoiceBrokerState>(
            valueListenable: _service.stateNotifier,
            builder: (context, state, _) {
              final isListening = state == VoiceBrokerState.listening;

              return TashilFloatingActionButton(
                onPressed: _toggleMicListening,
                icon: isListening ? Icons.stop_rounded : Icons.mic_rounded,
                tooltip: loc.tr('talkToVoiceBroker'),
                size: TashilFabSize.small,
              );
            },
          ),
        ],
      ),
    );
  }
}
