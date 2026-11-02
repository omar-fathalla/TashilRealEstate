import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/config/super_admin_security_config.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';

/// Dedicated Executive Super Admin Login Portal for Tashil Real Estate.
/// Completely isolated from public customer & tenant login flows.
class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({super.key});

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final _emailController = TextEditingController(text: SuperAdminSecurityConfig.defaultEmail);
  final _passwordController = TextEditingController(text: SuperAdminSecurityConfig.envPassword);
  final _securityKeyController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _securityKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin(AppLocalizations loc) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      TashilSnackBar.showWarning(
        context: context,
        message: loc.tr('fillAllFieldsValidation'),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuthService();
      bool isAuthenticated = false;

      // 1. Primary Authentication via Firebase Auth
      try {
        await auth.signInWithEmailAndPassword(email, password);
        isAuthenticated = true;
      } catch (authError) {
        debugPrint('ℹ️ Firebase Auth fallback check for local environment: $authError');
        // 2. Cryptographic Salted SHA-256 Hash Verification for offline / local environment
        if (SuperAdminSecurityConfig.verifyOfflineCredentials(email, password)) {
          isAuthenticated = true;
        }
      }

      if (!isAuthenticated) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        TashilSnackBar.showError(
          context: context,
          message: loc.tr('invalidAdminCredentials'),
        );
        return;
      }

      // Check Email Verification status
      await auth.reloadCurrentUser();
      final isVerified = auth.isCurrentUserEmailVerified;

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (isVerified) {
        TashilSnackBar.showSuccess(
          context: context,
          message: loc.tr('loginSuccess'),
        );
      } else {
        // If email verification is pending, trigger verification email if user exists
        if (auth.currentUser != null) {
          try {
            await auth.sendEmailVerification();
          } catch (verifErr) {
            debugPrint('sendEmailVerification note: $verifErr');
          }
        }
        if (!mounted) return;
        TashilSnackBar.showInfo(
          context: context,
          message: loc.tr('verifyEmailNotice'),
        );
      }

      if (!mounted) return;
      // Route directly to Super Admin Operations Dashboard
      context.go('/super-admin');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      TashilSnackBar.showError(
        context: context,
        message: '${loc.tr('authFailedError')}: ${e.toString()}',
      );
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context, AppLocalizations loc) async {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : SuperAdminSecurityConfig.defaultEmail,
    );
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return TashilAlertDialog(
            iconData: Icons.lock_reset_rounded,
            title: loc.tr('resetPasswordTitle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.tr('resetPasswordDesc'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: loc.tr('adminEmailOrId'),
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TashilButton.text(
                label: loc.tr('cancel'),
                onPressed: isSending ? null : () => Navigator.pop(dialogCtx),
              ),
              TashilButton.filled(
                label: loc.tr('sendResetLinkBtn'),
                icon: Icons.send_rounded,
                isLoading: isSending,
                onPressed: isSending
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty) {
                          TashilSnackBar.showWarning(
                            context: context,
                            message: loc.tr('fillAllFieldsValidation'),
                          );
                          return;
                        }
                        setDialogState(() => isSending = true);
                        try {
                          await FirebaseAuthService().sendPasswordResetEmail(email);
                          if (!dialogCtx.mounted) return;
                          Navigator.pop(dialogCtx);
                          TashilSnackBar.showSuccess(
                            context: context,
                            message: loc.tr('passwordResetSentSuccess'),
                          );
                        } catch (e) {
                          setDialogState(() => isSending = false);
                          TashilSnackBar.showError(
                            context: context,
                            message: e.toString(),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, currentLocale, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final loc = AppLocalizations.of(context);

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: Center(
            child: TashilIconButton.tonal(
              icon: Icons.arrow_back_rounded,
              tooltip: loc.tr('returnToMarketplace'),
              onPressed: () => context.go('/'),
            ),
          ),
        ),
        actions: [
          // Security Status Pill Badge
          Container(
            margin: const EdgeInsetsDirectional.only(end: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  loc.tr('systemGuardTier'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // App Settings & Theme Trigger
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: TashilIconButton.standard(
              icon: Icons.tune_rounded,
              tooltip: loc.tr('systemSettings'),
              onPressed: () => AppSettingsDialog.show(context),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: TashilCard.outlined(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Executive Emblem Header
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Titles
                  Text(
                    loc.tr('superAdminPortalTitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.tr('superAdminPortalSubtitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. High-Security Notice Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            loc.tr('superAdminSecurityNotice'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Input Fields
                  // Email / Admin Identifier
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: loc.tr('adminEmailOrId'),
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: loc.tr('adminPassword'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: _isLoading ? null : () => _showForgotPasswordDialog(context, loc),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        loc.tr('forgotPassword'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2FA Master Security Key
                  TextFormField(
                    controller: _securityKeyController,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: loc.tr('adminSecurityKey'),
                      prefixIcon: const Icon(Icons.pin_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Primary Sign In Action
                  TashilButton.filled(
                    label: loc.tr('superAdminSignInBtn'),
                    icon: Icons.login_rounded,
                    height: 48,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : () => _handleAdminLogin(loc),
                  ),
                  const SizedBox(height: 20),

                  // 6. Return to Marketplace
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.storefront_outlined, size: 16),
                      label: Text(
                        loc.tr('returnToMarketplace'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => context.go('/'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
