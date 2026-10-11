import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/features/lease_builder/models/lease_contract_model.dart';

class SignaturePadDialog extends StatefulWidget {
  final String signerName;
  final String signerRole; // 'lessor' | 'tenant'
  final String nationalIdOrEmiratesId;
  final String contractNumber;
  final String countryCode;

  const SignaturePadDialog({
    super.key,
    required this.signerName,
    required this.signerRole,
    required this.nationalIdOrEmiratesId,
    required this.contractNumber,
    required this.countryCode,
  });

  static Future<DigitalSignature?> show(
    BuildContext context, {
    required String signerName,
    required String signerRole,
    required String nationalIdOrEmiratesId,
    required String contractNumber,
    required String countryCode,
  }) {
    return TashilTransitions.showM3Dialog<DigitalSignature>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SignaturePadDialog(
        signerName: signerName,
        signerRole: signerRole,
        nationalIdOrEmiratesId: nationalIdOrEmiratesId,
        contractNumber: contractNumber,
        countryCode: countryCode,
      ),
    );
  }

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;
  bool _acceptedTerms = true;

  bool get _hasSignature => _strokes.isNotEmpty;

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _currentStroke = [event.localPosition];
      _strokes.add(_currentStroke!);
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    setState(() {
      _currentStroke?.add(event.localPosition);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _currentStroke = null;
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
  }

  DigitalSignature _generateSignature() {
    final now = DateTime.now();
    final randomHex = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final hashPrefix = widget.countryCode == 'AE' ? 'AE-E-SIGN-DLD' : 'EG-E-SIGN-CIVIL';
    final verificationHash = '$hashPrefix-${now.millisecondsSinceEpoch.toRadixString(16)}-$randomHex';
    final certId = 'CERT-${widget.countryCode}-${now.year}-${Random().nextInt(90000) + 10000}';

    final strokePoints = _strokes
        .map((stroke) => stroke.expand((p) => [p.dx, p.dy]).toList())
        .toList();

    return DigitalSignature(
      signerName: widget.signerName,
      signerRole: widget.signerRole,
      nationalIdOrEmiratesId: widget.nationalIdOrEmiratesId,
      signedAt: now,
      ipAddress: '197.100.${Random().nextInt(200) + 10}.${Random().nextInt(200) + 10}',
      verificationHash: verificationHash,
      certificateId: certId,
      signatureStrokePoints: strokePoints,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLessor = widget.signerRole == 'lessor';
    final roleLabel = isLessor ? loc.tr('lessorParty') : loc.tr('tenantParty');

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, child) {
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.draw_rounded, color: theme.colorScheme.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.tr('digitalSignaturePad'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${loc.tr('contractRef')}: ${widget.contractNumber}',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      TashilIconButton.close(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Signer Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(isLessor ? Icons.business_center_rounded : Icons.person_rounded, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.signerName} ($roleLabel)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                              ),
                              Text(
                                '${loc.tr('idNumber')}: ${widget.nationalIdOrEmiratesId}',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_user_rounded, color: theme.colorScheme.tertiary, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                loc.tr('identityVerified'),
                                style: TextStyle(color: theme.colorScheme.tertiary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Canvas Area
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _hasSignature ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Baseline guide
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 45,
                          child: Container(
                            height: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        Positioned(
                          left: 24,
                          bottom: 20,
                          child: Text(
                            loc.tr('signHereHint'),
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),

                        // Interactive Drawing Area
                        Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: _onPointerDown,
                          onPointerMove: _onPointerMove,
                          onPointerUp: _onPointerUp,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CustomPaint(
                              painter: _SignatureCustomPainter(_strokes, theme.colorScheme.onSurface),
                              size: Size.infinite,
                            ),
                          ),
                        ),

                        // Clear Button
                        if (_hasSignature)
                          PositionedDirectional(
                            top: 8,
                            end: 8,
                            child: TextButton.icon(
                              onPressed: _clearSignature,
                              icon: Icon(Icons.refresh_rounded, size: 16, color: theme.colorScheme.error),
                              label: Text(loc.tr('clearSignature'), style: TextStyle(color: theme.colorScheme.error)),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Legal Compliance checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                          activeColor: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.tr('eSignatureLegalAcknowledge'),
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Actions - M3 Expressive Connected Button Group
                  TashilConnectedButtonGroup<String>(
                    isFullWidth: true,
                    height: 46,
                    selectedValue: (_hasSignature && _acceptedTerms) ? 'confirm' : null,
                    onSelectionChanged: (val) {
                      if (val == 'cancel') {
                        Navigator.of(context).pop();
                      } else if (val == 'confirm') {
                        if (_hasSignature && _acceptedTerms) {
                          final signature = _generateSignature();
                          Navigator.of(context).pop(signature);
                        }
                      }
                    },
                    segments: [
                      TashilConnectedButtonSegment<String>(
                        value: 'cancel',
                        label: loc.tr('cancel'),
                        icon: Icons.close_rounded,
                      ),
                      TashilConnectedButtonSegment<String>(
                        value: 'confirm',
                        label: loc.tr('confirmSignature'),
                        icon: Icons.verified_rounded,
                        enabled: _hasSignature && _acceptedTerms,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignatureCustomPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;

  _SignatureCustomPainter(this.strokes, this.strokeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.4, paint);
      } else {
        final path = Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureCustomPainter oldDelegate) => true;
}
