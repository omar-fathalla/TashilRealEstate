import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/services/second_factor.dart';

/// TAQ-25: asks for the 6-digit code from the authenticator app. Returns null on cancel.
Future<String?> askSecondFactorCode(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CodeDialog(),
  );
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = SecondFactor.normaliseCode(_controller.text);
    if (code == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      icon: const Icon(Icons.verified_user_outlined),
      title: Text(loc.tr('mfaSignInTitle')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.tr('mfaSignInPrompt')),
          const SizedBox(height: 16),
          _CodeField(controller: _controller, invalid: _invalid, onSubmitted: _submit),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(loc.tr('cancel'))),
        FilledButton(onPressed: _submit, child: Text(loc.tr('mfaVerify'))),
      ],
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller, required this.invalid, required this.onSubmitted});

  final TextEditingController controller;
  final bool invalid;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return TextField(
      key: const Key('mfaCodeField'),
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d ]')), LengthLimitingTextInputFormatter(8)],
      decoration: InputDecoration(
        labelText: loc.tr('mfaCodeLabel'),
        errorText: invalid ? loc.tr('mfaWrongCode') : null,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

/// TAQ-25: lets the signed-in user add an authenticator app as a second factor.
class SecondFactorSetupDialog extends StatefulWidget {
  const SecondFactorSetupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(context: context, builder: (_) => const SecondFactorSetupDialog());
  }

  @override
  State<SecondFactorSetupDialog> createState() => _SecondFactorSetupDialogState();
}

class _SecondFactorSetupDialogState extends State<SecondFactorSetupDialog> {
  final _controller = TextEditingController();
  bool? _enrolled;
  bool _busy = false;
  TotpSecret? _secret;
  String? _qrUrl;
  String? _errorKey;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final user = _user;
    if (user == null) {
      setState(() => _errorKey = 'mfaUnavailable');
      return;
    }
    try {
      final factors = await user.multiFactor.getEnrolledFactors();
      if (mounted) setState(() => _enrolled = factors.any((f) => f.factorId == SecondFactor.totpFactorId));
    } catch (_) {
      if (mounted) setState(() => _errorKey = 'mfaUnavailable');
    }
  }

  String _errorFor(Object e) {
    if (e is FirebaseAuthException) {
      if (e.code == 'requires-recent-login') return 'mfaRecentLogin';
      if (e.code == 'invalid-verification-code' || e.code == 'invalid-credential') return 'mfaWrongCode';
    }
    return 'mfaUnavailable';
  }

  Future<void> _start() async {
    final user = _user;
    if (user == null) return;
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      final session = await user.multiFactor.getSession();
      final secret = await TotpMultiFactorGenerator.generateSecret(session);
      final url = await secret.generateQrCodeUrl(accountName: user.email ?? user.uid, issuer: 'Tashil Aqar');
      if (mounted) {
        setState(() {
          _secret = secret;
          _qrUrl = url;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorKey = _errorFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final user = _user;
    final secret = _secret;
    final code = SecondFactor.normaliseCode(_controller.text);
    if (user == null || secret == null) return;
    if (code == null) {
      setState(() => _errorKey = 'mfaWrongCode');
      return;
    }
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      final assertion = await TotpMultiFactorGenerator.getAssertionForEnrollment(secret, code);
      await user.multiFactor.enroll(assertion, displayName: 'Authenticator app');
      if (mounted) {
        setState(() {
          _enrolled = true;
          _secret = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorKey = _errorFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secret = _secret;
    final children = <Widget>[];

    if (_enrolled == null && _errorKey == null) {
      children.add(const Center(child: CircularProgressIndicator()));
    } else if (_enrolled == true) {
      children.add(Text(loc.tr('mfaOn')));
    } else if (secret == null) {
      children.add(Text(loc.tr('mfaOff')));
    } else {
      children.addAll([
        Text(loc.tr('mfaSecretHint')),
        const SizedBox(height: 12),
        if (_qrUrl != null)
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsetsDirectional.all(8),
              child: QrImageView(data: _qrUrl!, size: 168),
            ),
          ),
        const SizedBox(height: 12),
        Text(loc.tr('mfaSetupKey'), style: theme.textTheme.labelMedium),
        SelectableText(secret.secretKey, style: theme.textTheme.bodyLarge?.copyWith(fontFamily: 'monospace')),
        const SizedBox(height: 12),
        _CodeField(controller: _controller, invalid: false, onSubmitted: _verify),
      ]);
    }
    if (_errorKey != null) {
      children.addAll([
        const SizedBox(height: 12),
        Text(loc.tr(_errorKey!), style: TextStyle(color: theme.colorScheme.error)),
      ]);
    }

    return AlertDialog(
      icon: const Icon(Icons.verified_user_outlined),
      title: Text(loc.tr('mfaTitle')),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(loc.tr('close'))),
        if (_enrolled == false && secret == null)
          FilledButton(onPressed: _busy ? null : _start, child: Text(loc.tr('mfaSetUp'))),
        if (_enrolled == false && secret != null)
          FilledButton(onPressed: _busy ? null : _verify, child: Text(loc.tr('mfaVerify'))),
      ],
    );
  }
}
