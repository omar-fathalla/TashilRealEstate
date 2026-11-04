import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/features/market_index/services/ai_market_index_service.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialog_frame.dart';

class AiMarketAnalystChatDialog extends StatefulWidget {
  const AiMarketAnalystChatDialog({super.key});

  static Future<void> show(BuildContext context) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AiMarketAnalystChatDialog(),
    );
  }

  @override
  State<AiMarketAnalystChatDialog> createState() => _AiMarketAnalystChatDialogState();
}

class _AiMarketAnalystChatDialogState extends State<AiMarketAnalystChatDialog> {
  final _service = AiMarketIndexService();
  final _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preload greeting
    final isEgypt = !CountryController.isUAE;
    final defaultGreeting = isEgypt
        ? AppLocalizations.trStatic('uiCopy286')
        : 'Welcome! I am your AI Real Estate Market Analyst for the UAE and Dubai Property Index. Ask me anything regarding rental yields, price trends, or investment timing.';
    _messages.add({'role': 'assistant', 'text': defaultGreeting});
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String query) async {
    if (query.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': query.trim()});
      _isLoading = true;
    });
    _textController.clear();

    final countryCode = CountryController.isUAE ? 'AE' : 'EG';
    final langCode = LocaleController.languageCode;

    final response = await _service.askMarketAnalyst(
      userQuery: query,
      countryCode: countryCode,
      langCode: langCode,
    );

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': response});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isUAE = CountryController.isUAE;

    final sampleQuestionsEG = [
      AppLocalizations.trStatic('uiCopy323'),
      AppLocalizations.trStatic('uiCopy275'),
      AppLocalizations.trStatic('uiCopy269'),
    ];

    final sampleQuestionsAE = [
      'What are the highest yielding rental districts in Dubai?',
      'How does the Golden Visa impact luxury property demand?',
      'When is the optimal time to renew an annual lease in Marina?',
    ];

    final sampleQuestions = isUAE ? sampleQuestionsAE : sampleQuestionsEG;

    return TashilDialogFrame(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 36,
        vertical: isMobile ? 16 : 28,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Symbols.psychology_alt_rounded,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                loc.tr('aiMarketAnalystTitle'),
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Gemini 1.5 Flash',
                                  style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            loc.tr('aiMarketAnalystSubtitle'),
                            style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TashilIconButton(
                    icon: Symbols.close_rounded,
                    tooltip: loc.tr('close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(height: 24, color: theme.colorScheme.outlineVariant),

              // Chat Messages
              Expanded(
                child: ListView.separated(
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isLoading) {
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  loc.tr('geminiAnalyzingMarketData'),
                                  style: Theme.of(context).textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';

                    return Align(
                      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: isMobile ? 300 : 540),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: isUser ? null : Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            height: 1.45),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Suggested prompts chips
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sampleQuestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final q = sampleQuestions[index];
                    return ActionChip(
                      label: Text(
                        q,
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurface),
                      ),
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      onPressed: () => _sendMessage(q),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Input bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: loc.tr('askMarketAnalystPlaceholder'),
                        hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        prefixIcon: Icon(Symbols.search_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TashilIconButton(
                    icon: Symbols.send_rounded,
                    tooltip: loc.tr('send'),
                    variant: TashilIconButtonVariant.filled,
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
