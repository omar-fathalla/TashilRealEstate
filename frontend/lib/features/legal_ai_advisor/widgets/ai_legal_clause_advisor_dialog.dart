import 'package:flutter/material.dart';
import '../../../core/design_system/buttons/tashil_buttons.dart';
import '../../../core/design_system/chips/tashil_chips.dart';
import '../../../core/design_system/loading/tashil_loading_indicator.dart';
import '../../../core/design_system/motion/tashil_motion.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/country_controller.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../lease_builder/models/lease_contract_model.dart';
import '../models/legal_advisor_model.dart';
import '../services/ai_legal_advisor_service.dart';

class AiLegalClauseAdvisorDialog extends StatefulWidget {
  final String? initialClauseText;
  final ValueChanged<String>? onClauseApplied;
  final ValueChanged<LegalClause>? onLegalClauseApplied;

  const AiLegalClauseAdvisorDialog({
    super.key,
    this.initialClauseText,
    this.onClauseApplied,
    this.onLegalClauseApplied,
  });

  static Future<void> show(
    BuildContext context, {
    String? initialClauseText,
    ValueChanged<String>? onClauseApplied,
    ValueChanged<LegalClause>? onLegalClauseApplied,
  }) {
    return TashilTransitions.showM3Dialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AiLegalClauseAdvisorDialog(
        initialClauseText: initialClauseText,
        onClauseApplied: onClauseApplied,
        onLegalClauseApplied: onLegalClauseApplied,
      ),
    );
  }

  @override
  State<AiLegalClauseAdvisorDialog> createState() =>
      _AiLegalClauseAdvisorDialogState();
}

class _AiLegalClauseAdvisorDialogState
    extends State<AiLegalClauseAdvisorDialog> {
  final _service = AiLegalAdvisorService();
  late final TextEditingController _clauseController;
  bool _isAuditing = false;
  LegalClauseAuditResult? _auditResult;

  @override
  void initState() {
    super.initState();
    _clauseController = TextEditingController(
      text: widget.initialClauseText ?? '',
    );
    if (_clauseController.text.trim().isNotEmpty) {
      _runAudit();
    }
  }

  @override
  void dispose() {
    _clauseController.dispose();
    super.dispose();
  }

  Future<void> _runAudit() async {
    final text = _clauseController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAuditing = true);
    final country = CountryController.countryCode;

    final res = await _service.auditAndRefineClause(
      clauseDraft: text,
      countryCode: country,
    );

    if (mounted) {
      setState(() {
        _auditResult = res;
        _isAuditing = false;
      });
    }
  }

  void _applyQuickSuggestion(String suggestion) {
    _clauseController.text = suggestion;
    _runAudit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final lang = LocaleController.languageCode;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: EdgeInsets.all(isMobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 880,
        height: 720,
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          children: [
            // Header
            _buildHeader(loc),
            const SizedBox(height: 14),
            Divider(color: theme.colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 14),

            // Main Body: Editor & Legal RAG Results
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clause Input Box
                    Text(
                      loc.tr('legalClauseDraftInputLabel'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _clauseController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: loc.tr('aiLegalAdvisorPromptHint'),
                        hintStyle: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
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
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Suggestion Chips
                    Text(
                      loc.tr('quickSuggestionsLabel'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        TashilAssistChip(
                          label: loc.tr('clauseSuggestionSublease'),
                          icon: Icons.hotel_rounded,
                          onPressed: () => _applyQuickSuggestion(loc.tr('clauseSuggestionSublease')),
                        ),
                        TashilAssistChip(
                          label: loc.tr('clauseSuggestionMaintenance'),
                          icon: Icons.build_circle_outlined,
                          onPressed: () => _applyQuickSuggestion(loc.tr('clauseSuggestionMaintenance')),
                        ),
                        TashilAssistChip(
                          label: loc.tr('clauseSuggestionLateFee'),
                          icon: Icons.receipt_long_rounded,
                          onPressed: () => _applyQuickSuggestion(loc.tr('clauseSuggestionLateFee')),
                        ),
                        TashilAssistChip(
                          label: loc.tr('clauseSuggestionPets'),
                          icon: Icons.pets_rounded,
                          onPressed: () => _applyQuickSuggestion(loc.tr('clauseSuggestionPets')),
                        ),
                        TashilAssistChip(
                          label: loc.tr('clauseSuggestionDeposit'),
                          icon: Icons.shield_outlined,
                          onPressed: () => _applyQuickSuggestion(loc.tr('clauseSuggestionDeposit')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Action Trigger
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TashilButton(
                          onPressed: _isAuditing ? null : _runAudit,
                          icon: Icons.auto_awesome_rounded,
                          label: loc.tr('auditClauseWithRagBtn'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Audit Result
                    if (_isAuditing)
                      _buildLoadingIndicator(loc)
                    else if (_auditResult != null)
                      _buildAuditResultCard(_auditResult!, loc, lang),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.balance_rounded, color: theme.colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    loc.tr('legalAiAdvisorTitle'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Gemini 2.5 Pro Legal',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.travel_explore_rounded, size: 12, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Google Search Grounded',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                loc.tr('legalAiAdvisorSubtitle'),
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        // M3 Shaded Close Button standard
        TashilIconButton.close(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator(AppLocalizations loc) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const TashilLoadingIndicator(size: 48),
            const SizedBox(height: 16),
            Text(
              loc.tr('geminiAuditingLegalReasoning'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditResultCard(
    LegalClauseAuditResult res,
    AppLocalizations loc,
    String lang,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compliance & Legal Validity Badge
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('legalComplianceStatusPass'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      res.getLawReference(lang),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(res.legalValidityScore * 100).toStringAsFixed(1)}% ${loc.tr('validityScore')}',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Legal Reasoning Analysis
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    loc.tr('legalAnalysisAndJustification'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                res.getReasoning(lang),
                style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant, height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Suggested Legally Balanced Clause
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${loc.tr('recommendedLegalClauseHeading')} - ${res.getTitle(lang)}',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                res.getSuggestedClause(lang),
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TashilButton(
                    onPressed: () {
                      final suggested = res.getSuggestedClause(lang);
                      if (widget.onClauseApplied != null) {
                        widget.onClauseApplied!(suggested);
                      }
                      if (widget.onLegalClauseApplied != null) {
                        widget.onLegalClauseApplied!(res.toLegalClause());
                      }
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.tr('clauseAppliedToLeaseSuccessNotification')),
                          backgroundColor: theme.colorScheme.inverseSurface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icons.check_circle_rounded,
                    label: loc.tr('applyClauseToLeaseBtn'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
