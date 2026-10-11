import 'package:flutter/material.dart';
import '../../localization/app_localizations.dart';
import '../buttons/tashil_buttons.dart';
import '../dialogs/tashil_dialogs.dart';
import '../dividers/tashil_dividers.dart';
import 'tashil_motion.dart';

/// Interactive showcase dialog allowing live visual inspection and testing of
/// the official Google Material Design 3 (M3) Motion & Transitions System,
/// including easing curves, duration tokens, transition patterns, and physics springs.
class M3MotionShowcaseDialog extends StatefulWidget {
  const M3MotionShowcaseDialog({super.key});

  static Future<void> show(BuildContext context) {
    return TashilTransitions.showM3Dialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => const M3MotionShowcaseDialog(),
    );
  }

  @override
  State<M3MotionShowcaseDialog> createState() => _M3MotionShowcaseDialogState();
}

class _M3MotionShowcaseDialogState extends State<M3MotionShowcaseDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _demoController;
  Curve _selectedCurve = TashilMotionEasing.emphasized;
  Duration _selectedDuration = TashilMotionDuration.long2;
  String _activeCurveName = 'Emphasized (0.2, 0.0, 0.0, 1.0)';
  int _activePatternIndex = 0; // 0: Container, 1: Shared Axis, 2: Fade Through, 3: Fade

  @override
  void initState() {
    super.initState();
    _demoController = AnimationController(
      vsync: this,
      duration: _selectedDuration,
    );
  }

  @override
  void dispose() {
    _demoController.dispose();
    super.dispose();
  }

  void _triggerMotion() {
    _demoController.duration = _selectedDuration;
    if (_demoController.isCompleted) {
      _demoController.reverse();
    } else {
      _demoController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return TashilModalDialog(
      title: loc.tr('m3MotionShowcase'),
      subtitle: loc.tr('m3MotionSubtitle'),
      icon: Icons.animation_rounded,
      maxWidth: 720,
      footer: TashilButton(
        label: loc.tr('close'),
        icon: Icons.check_rounded,
        variant: TashilButtonVariant.filled,
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Live Interactive Motion Track Canvas
            Container(
              height: 120,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: AnimatedBuilder(
                animation: _demoController,
                builder: (context, child) {
                  final curvedValue = _selectedCurve.transform(_demoController.value);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final maxTravel = constraints.maxWidth - 56.0;
                      final isRtl = Directionality.of(context) == TextDirection.rtl;
                      final currentOffset = curvedValue * maxTravel;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Target Track Line
                          Positioned(
                            left: 28,
                            right: 28,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Animated Surface Pill
                          Positioned(
                            left: isRtl ? null : currentOffset,
                            right: isRtl ? currentOffset : null,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(
                                  curvedValue > 0.5 ? 28.0 : 12.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: colorScheme.onPrimary,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Motion Play Trigger Button
            Center(
              child: TashilButton(
                label: loc.tr('playMotionDemo'),
                icon: Icons.play_arrow_rounded,
                variant: TashilButtonVariant.filled,
                onPressed: _triggerMotion,
              ),
            ),
            const SizedBox(height: 16),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 16),

            // 2. Official Easing Curves Selector
            Text(
              loc.tr('motionEasingCurves'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeCurveName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCurveChip(
                  label: 'Emphasized',
                  curve: TashilMotionEasing.emphasized,
                  curveName: 'Emphasized (0.2, 0.0, 0.0, 1.0) - On Screen',
                ),
                _buildCurveChip(
                  label: 'Emphasized Decelerate',
                  curve: TashilMotionEasing.emphasizedDecelerate,
                  curveName: 'Emphasized Decelerate (0.05, 0.7, 0.1, 1.0) - Enter',
                ),
                _buildCurveChip(
                  label: 'Emphasized Accelerate',
                  curve: TashilMotionEasing.emphasizedAccelerate,
                  curveName: 'Emphasized Accelerate (0.3, 0.0, 0.8, 0.15) - Exit',
                ),
                _buildCurveChip(
                  label: 'Standard',
                  curve: TashilMotionEasing.standard,
                  curveName: 'Standard (0.2, 0.0, 0.0, 1.0) - Utility',
                ),
                _buildCurveChip(
                  label: 'Standard Decelerate',
                  curve: TashilMotionEasing.standardDecelerate,
                  curveName: 'Standard Decelerate (0.0, 0.0, 0.2, 1.0) - Small Enter',
                ),
              ],
            ),

            const SizedBox(height: 16),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 16),

            // 3. Official Duration Tokens Selector
            Text(
              loc.tr('motionDurations'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDurationChip(label: 'short2 (100ms)', duration: TashilMotionDuration.short2),
                _buildDurationChip(label: 'short4 (200ms)', duration: TashilMotionDuration.short4),
                _buildDurationChip(label: 'medium2 (300ms)', duration: TashilMotionDuration.medium2),
                _buildDurationChip(label: 'medium4 (400ms)', duration: TashilMotionDuration.medium4),
                _buildDurationChip(label: 'long2 (500ms)', duration: TashilMotionDuration.long2),
                _buildDurationChip(label: 'long4 (600ms)', duration: TashilMotionDuration.long4),
              ],
            ),

            const SizedBox(height: 16),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 16),

            // 4. The 4 Official Transition Patterns
            Text(
              loc.tr('motionTransitionsHeading'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _buildPatternRow(
              index: 0,
              icon: Icons.aspect_ratio_rounded,
              title: loc.tr('containerTransformPattern'),
              description: '500ms Emphasized container morphing with elevation sync',
            ),
            const SizedBox(height: 8),
            _buildPatternRow(
              index: 1,
              icon: Icons.sync_alt_rounded,
              title: loc.tr('sharedAxisPattern'),
              description: 'Horizontal (X-Axis RTL/LTR), Vertical (Y), Depth (Z)',
            ),
            const SizedBox(height: 8),
            _buildPatternRow(
              index: 2,
              icon: Icons.layers_outlined,
              title: loc.tr('fadeThroughPattern'),
              description: 'Outgoing fades out, incoming fades in and scales 92% to 100%',
            ),
            const SizedBox(height: 8),
            _buildPatternRow(
              index: 3,
              icon: Icons.opacity_rounded,
              title: loc.tr('fadePattern'),
              description: 'Simple opacity fade for dialog scrims and tooltips',
            ),

            const SizedBox(height: 16),
            const TashilDivider.fullWidth(),
            const SizedBox(height: 16),

            // 5. Modern Physics Springs
            Text(
              loc.tr('motionSpringPhysics'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('criticallyDampedSpring'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'zeta = 1.0 (Stiffness: 300, Damping: 34.64) - No bounce',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('expressiveBouncySpring'),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'zeta approx 0.76 (Stiffness: 320, Damping: 27.15) - Tactile',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurveChip({
    required String label,
    required Curve curve,
    required String curveName,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedCurve == curve;

    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        ),
      ),
      selectedColor: colorScheme.primaryContainer,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCurve = curve;
            _activeCurveName = curveName;
          });
          _triggerMotion();
        }
      },
    );
  }

  Widget _buildDurationChip({
    required String label,
    required Duration duration,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedDuration == duration;

    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        ),
      ),
      selectedColor: colorScheme.primaryContainer,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedDuration = duration;
          });
          _triggerMotion();
        }
      },
    );
  }

  Widget _buildPatternRow({
    required int index,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _activePatternIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _activePatternIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.35)
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.6)
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
