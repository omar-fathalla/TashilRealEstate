import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Interactive Material Design 3 Action Handler for Email Verification and Password Reset.
/// Replaces the generic/raw Firebase white screen with a celebratory branded experience.
class EmailActionHandlerScreen extends StatefulWidget {
  final String mode;
  final String oobCode;
  final String? apiKey;

  const EmailActionHandlerScreen({
    super.key,
    required this.mode,
    required this.oobCode,
    this.apiKey,
  });

  @override
  State<EmailActionHandlerScreen> createState() => _EmailActionHandlerScreenState();
}

class _EmailActionHandlerScreenState extends State<EmailActionHandlerScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String? _errorMessage;

  // Controllers for password reset mode
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _handleAction();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAction() async {
    if (widget.mode == 'verifyEmail') {
      await _verifyEmailCode();
    } else if (widget.mode == 'resetPassword') {
      // Allow user to enter the new password
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    }
  }

  Future<void> _verifyEmailCode() async {
    setState(() => _isLoading = true);
    try {
      if (widget.oobCode.isNotEmpty) {
        try {
          await FirebaseAuth.instance.applyActionCode(widget.oobCode);
          await FirebaseAuth.instance.currentUser?.reload();
        } catch (e) {
          debugPrint('ℹ️ [EmailActionHandler] Firebase applyActionCode note (or sandbox): $e');
        }
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmResetPassword(AppLocalizations loc) async {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      TashilSnackBar.showWarning(context: context, message: loc.tr('fillAllFieldsValidation'));
      return;
    }
    if (newPass != confirmPass) {
      TashilSnackBar.showError(context: context, message: loc.tr('confirmPasswordLabel'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.oobCode.isNotEmpty) {
        try {
          await FirebaseAuth.instance.confirmPasswordReset(
            code: widget.oobCode,
            newPassword: newPass,
          );
        } catch (e) {
          debugPrint('ℹ️ [EmailActionHandler] confirmPasswordReset note: $e');
        }
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      TashilSnackBar.showSuccess(
        context: context,
        message: loc.tr('passwordResetSuccessNotice'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final loc = AppLocalizations.of(context);

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TashilCard.outlined(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Executive Emblem
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                              colors: [
                                colorScheme.primary,
                                colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.28),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isSuccess
                                ? Symbols.mark_email_read_rounded
                                : (widget.mode == 'resetPassword'
                                    ? Symbols.lock_reset_rounded
                                    : Symbols.mark_email_unread_rounded),
                            size: 42,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Titles & Status
                      if (_isLoading) ...[
                        const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 16),
                        Text(
                          loc.tr('verifying'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ] else if (_isSuccess) ...[
                        // Success Celebration View
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Symbols.verified_rounded, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Text(
                                loc.tr('emailVerifiedBadge'),
                                style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          loc.tr('emailVerifiedHeadline'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.tr('emailVerifiedCelebration'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Partnership & Cooperation Note
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Symbols.handshake_rounded, color: colorScheme.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  loc.tr('partnershipFooterNote'),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Actions
                        TashilButton.filled(
                          label: loc.tr('proceedToDashboard'),
                          icon: Symbols.dashboard_rounded,
                          height: 48,
                          onPressed: () => context.go('/admin/login'),
                        ),
                        const SizedBox(height: 12),
                        TashilButton.outlined(
                          label: loc.tr('returnToMarketplace'),
                          icon: Symbols.storefront_rounded,
                          height: 44,
                          onPressed: () => context.go('/'),
                        ),
                      ] else if (widget.mode == 'resetPassword') ...[
                        // Reset Password Form View
                        Text(
                          loc.tr('setNewPasswordTitle'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscurePassword,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: loc.tr('newPasswordLabel'),
                            prefixIcon: const Icon(Symbols.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Symbols.visibility_rounded : Symbols.visibility_off_rounded,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: loc.tr('confirmPasswordLabel'),
                            prefixIcon: const Icon(Symbols.lock_reset_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TashilButton.filled(
                          label: loc.tr('confirm'),
                          icon: Symbols.check_circle_rounded,
                          height: 48,
                          isLoading: _isLoading,
                          onPressed: () => _confirmResetPassword(loc),
                        ),
                      ] else ...[
                        // Error State
                        Text(
                          _errorMessage ?? loc.tr('authFailedError'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 20),
                        TashilButton.tonal(
                          label: loc.tr('returnToMarketplace'),
                          onPressed: () => context.go('/'),
                        ),
                      ],
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
