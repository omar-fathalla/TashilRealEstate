import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_assist_chip.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_modal_dialog.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/design_system/text_fields/tashil_text_fields.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/core/utils/user_avatar_utils.dart';

/// Material Design 3 Dialog for viewing and editing personal profile info
/// Designed strictly with LTR left-aligned inputs, Phone OTP Verification,
/// balanced 50/50 full-width Action Buttons Group, and pure trilingual parity.
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const EditProfileDialog(),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _otpController;

  String _countryCode = '+20';
  String _preferredContactMethod = 'phone';
  bool _isSaving = false;
  String? _photoUrl;
  bool _isSyncingPhoto = false;

  // OTP Verification state
  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isPhoneVerified = false;
  String _verificationId = '';
  int _otpCountdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    final profile = UserProfileService().profileNotifier.value;
    _photoUrl = profile.photoUrl;

    _firstNameController = TextEditingController(text: profile.computedFirstName);
    _surnameController = TextEditingController(text: profile.computedSurname);
    _otpController = TextEditingController();

    // Parse country code from phone if present
    String rawPhone = profile.phone.trim();
    if (rawPhone.startsWith('+971')) {
      _countryCode = '+971';
      rawPhone = rawPhone.replaceFirst('+971', '').trim();
    } else if (rawPhone.startsWith('+20')) {
      _countryCode = '+20';
      rawPhone = rawPhone.replaceFirst('+20', '').trim();
    }
    _phoneController = TextEditingController(text: rawPhone);
    _preferredContactMethod = profile.preferredContactMethod;
    _isPhoneVerified = profile.isPhoneVerified && rawPhone.isNotEmpty;
  }

  Future<void> _handleSyncGooglePhoto(AppLocalizations loc) async {
    setState(() => _isSyncingPhoto = true);
    try {
      final success = await UserProfileService().syncFromGoogleAuth();
      if (!mounted) return;
      if (success) {
        setState(() {
          _photoUrl = UserProfileService().profileNotifier.value.photoUrl;
        });
        TashilSnackBar.showSuccess(
          context: context,
          message: loc.tr('photoSyncedSuccess'),
        );
      } else {
        TashilSnackBar.showWarning(
          context: context,
          message: loc.tr('noGooglePhotoFound'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingPhoto = false);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _firstNameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _otpCountdown = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown > 0) {
        setState(() => _otpCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp(AppLocalizations loc) async {
    final localPhone = _phoneController.text.trim();
    if (localPhone.length < 7) {
      TashilSnackBar.showWarning(
        context: context,
        message: 'يرجى إدخال رقم هاتف صحيح أولاً',
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final e164Number = FirebaseAuthService.formatE164Phone(_countryCode, localPhone);
      final verifId = await UserProfileService().sendPhoneVerificationOtp(e164Number);

      if (mounted) {
        setState(() {
          _isSendingOtp = false;
          _isOtpSent = true;
          _verificationId = verifId;
          _otpController.clear();
        });
        _startCountdown();
        TashilSnackBar.showSuccess(
          context: context,
          message: '${loc.tr('otpSentToPhone')} $e164Number',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingOtp = false);
        String errMsg = 'تعذر إرسال رمز التحقق: $e';
        final str = e.toString().toLowerCase();
        if (str.contains('quota-exceeded') || str.contains('too-many-requests')) {
          errMsg = 'تم تجاوز حد إرسال الرسائل لليوم، يرجى المحاولة لاحقاً';
        } else if (str.contains('invalid-phone-number')) {
          errMsg = 'رقم الهاتف غير صالح للدولة المحددة';
        } else if (str.contains('captcha')) {
          errMsg = 'يرجى إكمال اختبار التحقق reCAPTCHA';
        }
        TashilSnackBar.showError(
          context: context,
          message: errMsg,
        );
      }
    }
  }

  Future<void> _handleVerifyOtp(AppLocalizations loc) async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      TashilSnackBar.showWarning(
        context: context,
        message: 'يرجى إدخال رمز التحقق المكون من 6 أرقام',
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final localPhone = _phoneController.text.trim();
      final e164Number = FirebaseAuthService.formatE164Phone(_countryCode, localPhone);
      final success = await UserProfileService().verifyPhoneOtp(
        fullPhoneNumber: e164Number,
        verificationId: _verificationId,
        smsCode: code,
      );

      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
          if (success) {
            _isPhoneVerified = true;
            _isOtpSent = false;
          }
        });

        if (success) {
          _countdownTimer?.cancel();
          TashilSnackBar.showSuccess(
            context: context,
            message: loc.tr('phoneVerifiedSuccess'),
          );
        } else {
          TashilSnackBar.showError(
            context: context,
            message: loc.tr('otpInvalid'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
        String errMsg = loc.tr('otpInvalid');
        final str = e.toString().toLowerCase();
        if (str.contains('session-expired') || str.contains('code-expired')) {
          errMsg = 'انتهت صلاحية الرمز، يرجى طلب رمز جديد';
        }
        TashilSnackBar.showError(
          context: context,
          message: errMsg,
        );
      }
    }
  }

  Future<void> _handleSave(AppLocalizations loc) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final firstName = _firstNameController.text.trim();
      final surname = _surnameController.text.trim();
      final localPhone = _phoneController.text.trim();
      final phone = localPhone.isNotEmpty ? '$_countryCode $localPhone' : '';

      await UserProfileService().updateProfile(
        firstName: firstName,
        surname: surname,
        phone: phone,
        preferredContactMethod: _preferredContactMethod,
        photoUrl: _photoUrl,
        isPhoneVerified: _isPhoneVerified,
      );

      if (mounted) {
        Navigator.of(context).pop();
        TashilSnackBar.showSuccess(
          context: context,
          message: loc.tr('profileUpdatedSuccess'),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        TashilSnackBar.showError(
          context: context,
          message: 'حدث خطأ أثناء حفظ البيانات: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final profile = UserProfileService().profileNotifier.value;
    final fullName = '${_firstNameController.text} ${_surnameController.text}'.trim().isNotEmpty
        ? '${_firstNameController.text} ${_surnameController.text}'.trim()
        : profile.fullName;

    return TashilModalDialog(
      title: loc.tr('personalInfo'),
      subtitle: loc.tr('editProfileSubtitle'),
      icon: Icons.manage_accounts_rounded,
      maxWidth: 520,
      footer: Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // زر إلغاء (Cancel: 50% width)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          loc.tr('cancel'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // زر حفظ (Save: 50% width with primary background)
            Expanded(
              child: Material(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isSaving ? null : () => _handleSave(loc),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSaving)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        else
                          Icon(Icons.check_rounded, size: 16, color: colorScheme.onPrimary),
                        const SizedBox(width: 6),
                        Text(
                          loc.tr('save'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Google Avatar & User Identity Banner
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 2.5,
                            ),
                          ),
                          child: UserAvatarUtils.buildAvatar(
                            context: context,
                            photoUrl: _photoUrl ?? profile.photoUrl,
                            displayName: fullName.isNotEmpty ? fullName : profile.fullName,
                            fallbackInitials: 'MF',
                            radius: 42,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 2),
                          ),
                          child: Icon(
                            Icons.verified_user_rounded,
                            size: 13,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      fullName.isNotEmpty ? fullName : 'Mohamed Fathallah',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email.isNotEmpty ? profile.email : 'user@gmail.com',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.g_mobiledata_rounded, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            loc.tr('googleAccountLinked'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TashilAssistChip.outlined(
                      label: loc.tr('syncPhotoFromGoogle'),
                      icon: _isSyncingPhoto ? Icons.hourglass_top_rounded : Icons.sync_rounded,
                      onPressed: _isSyncingPhoto ? null : () => _handleSyncGooglePhoto(loc),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Personal Info M3 Form Fields
              TashilTextField.outlined(
                controller: _firstNameController,
                labelText: loc.tr('firstNameLabel'),
                prefixIcon: Icons.person_outline_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              TashilTextField.outlined(
                controller: _surnameController,
                labelText: loc.tr('surnameLabel'),
                prefixIcon: Icons.badge_outlined,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              TashilTextField.outlined(
                initialValue: profile.email.isNotEmpty ? profile.email : 'user@gmail.com',
                readOnly: true,
                labelText: loc.tr('emailAddress'),
                prefixIcon: Icons.email_outlined,
                suffixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TashilPhoneTextField(
                      textFieldKey: const Key('edit_profile_phone_input'),
                      controller: _phoneController,
                      countryCode: _countryCode,
                      onCountryCodeChanged: (newCode) {
                        setState(() {
                          _countryCode = newCode;
                          _isPhoneVerified = false;
                          _isOtpSent = false;
                        });
                      },
                      isPhoneVerified: _isPhoneVerified,
                      labelText: loc.tr('phoneNumberLabel'),
                      onChanged: (val) {
                        setState(() {
                          _isPhoneVerified = false;
                          _isOtpSent = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isPhoneVerified && _phoneController.text.trim().isNotEmpty) ...[
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 20, color: Colors.green),
                          const SizedBox(width: 6),
                          Text(
                            loc.tr('phoneVerifiedBadge'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      height: 56,
                      child: TashilButton.tonal(
                        onPressed: (_isSendingOtp || _phoneController.text.trim().isEmpty)
                            ? null
                            : () => _handleSendOtp(loc),
                        isLoading: _isSendingOtp,
                        icon: Icons.sms_outlined,
                        label: loc.tr('sendOtp'),
                        height: 56,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ],
              ),

              // Inline OTP Verification Block (when code is sent)
              if (_isOtpSent) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TashilTextField.outlined(
                              key: const Key('otp_code_field'),
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              labelText: loc.tr('enterOtpCode'),
                              prefixIcon: Icons.pin_rounded,
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 56,
                            child: TashilButton.filled(
                              label: 'تأكيد الرمز',
                              icon: Icons.check_rounded,
                              isLoading: _isVerifyingOtp,
                              onPressed: () => _handleVerifyOtp(loc),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_otpCountdown > 0)
                            Text(
                              '$_otpCountdown ${loc.tr('secondsRemaining')}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            )
                          else
                            InkWell(
                              onTap: () => _handleSendOtp(loc),
                              child: Text(
                                loc.tr('resendOtp'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // 3. Preferred Contact Method (Connected Button Group)
              Text(
                loc.tr('preferredContactMethodLabel'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TashilConnectedButtonGroup<String>(
                selectedValue: _preferredContactMethod,
                isFullWidth: true,
                onSelectionChanged: (val) {
                  setState(() => _preferredContactMethod = val);
                },
                segments: [
                  TashilConnectedButtonSegment(
                    value: 'phone',
                    label: loc.tr('contactMethodPhone'),
                    icon: Icons.phone_outlined,
                  ),
                  TashilConnectedButtonSegment(
                    value: 'whatsapp',
                    label: loc.tr('contactMethodWhatsApp'),
                    icon: Icons.chat_bubble_outline_rounded,
                  ),
                  TashilConnectedButtonSegment(
                    value: 'email',
                    label: loc.tr('contactMethodEmail'),
                    icon: Icons.mail_outline_rounded,
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
