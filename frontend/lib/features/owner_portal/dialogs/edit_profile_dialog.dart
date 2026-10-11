import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/chips/tashil_assist_chip.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_modal_dialog.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/design_system/text_fields/tashil_text_fields.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/bank_directory_service.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/core/utils/image_utils.dart';
import 'package:tashil_real_estate/core/utils/user_avatar_utils.dart';
import 'package:tashil_real_estate/features/document_ocr/models/document_ocr_result_model.dart';
import 'package:tashil_real_estate/features/document_ocr/widgets/ai_document_ocr_modal.dart';

/// Material Design 3 Dialog for viewing and editing personal profile info.
/// Fully equipped with:
/// 1. AI Document OCR National ID Scanner & High-Res Card Image Preview
/// 2. Official National ID (14 digits EG / Emirates ID AE) & Full Official Address
/// 3. Updateable Email Address & Phone OTP Verification
/// 4. Landlord Bank Payout Details (Bank Name, Account/IBAN)
/// 5. Live M3 Profile Completeness Progress Indicator
/// 6. Connected Button Group for Preferred Contact Method & 100% Trilingual Parity
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
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _otpController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _addressController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _bankAccountNumberController;
  late final TextEditingController _customBankController;

  String? _selectedBankCode;
  bool _isCustomBank = false;

  String _countryCode = '+20';
  String _preferredContactMethod = 'phone';
  bool _isSaving = false;
  String? _photoUrl;
  String? _idCardPhotoUrl;
  bool _isSyncingPhoto = false;
  bool _isScanningOcr = false;

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
    _idCardPhotoUrl = profile.idCardPhotoUrl;

    _firstNameController = TextEditingController(text: profile.computedFirstName);
    _surnameController = TextEditingController(text: profile.computedSurname);
    _emailController = TextEditingController(text: profile.email);
    _otpController = TextEditingController();
    _nationalIdController = TextEditingController(text: profile.nationalId);
    _addressController = TextEditingController(text: profile.address);
    _bankNameController = TextEditingController(text: profile.bankName);
    _bankAccountNumberController = TextEditingController(
      text: profile.bankAccountNumber.isNotEmpty ? profile.bankAccountNumber : profile.iban,
    );
    _customBankController = TextEditingController();

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

    _initBankSelection(profile.bankName);
  }

  void _initBankSelection(String savedBankName) {
    final activeCountry = (CountryController.isUAE || _countryCode == '+971') ? 'AE' : 'EG';
    final bank = BankDirectoryService.findBank(savedBankName, activeCountry);
    if (bank != null) {
      if (bank.isOther) {
        _selectedBankCode = BankDirectoryService.otherBankCode;
        _isCustomBank = true;
        _customBankController.text = savedBankName;
      } else {
        _selectedBankCode = bank.code;
        _isCustomBank = false;
      }
    } else if (savedBankName.trim().isNotEmpty) {
      _selectedBankCode = BankDirectoryService.otherBankCode;
      _isCustomBank = true;
      _customBankController.text = savedBankName;
    } else {
      _selectedBankCode = null;
      _isCustomBank = false;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _customBankController.dispose();
    super.dispose();
  }

  double _calculateCurrentCompleteness() {
    int points = 0;
    const int total = 6;
    if (_emailController.text.trim().isNotEmpty) points++;
    if ('${_firstNameController.text} ${_surnameController.text}'.trim().isNotEmpty) points++;
    if (_phoneController.text.trim().isNotEmpty) points++;
    if (_nationalIdController.text.trim().isNotEmpty) points++;
    if (_addressController.text.trim().isNotEmpty) points++;
    if (_bankNameController.text.trim().isNotEmpty || _bankAccountNumberController.text.trim().isNotEmpty) points++;
    return points / total;
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

  /// Trigger AI Document OCR scanning for Landlord ID Card
  Future<void> _handleScanIdWithAi(AppLocalizations loc) async {
    if (_isScanningOcr) return;
    setState(() => _isScanningOcr = true);

    try {
      final country = _countryCode == '+971' ? 'AE' : 'EG';
      final docType = country == 'AE' ? DocumentOcrType.emiratesId : DocumentOcrType.egyptianNationalId;

      final result = await AiDocumentOcrModal.show(
        context,
        countryCode: country,
        targetParty: 'profile',
        docType: docType,
      );

      if (result != null && mounted) {
        setState(() {
          final extractedName = result.fullNameAr.isNotEmpty ? result.fullNameAr : result.fullNameEn;
          if (extractedName.isNotEmpty) {
            _firstNameController.text = UserAvatarUtils.getFirstName(extractedName);
            _surnameController.text = UserAvatarUtils.getSurname(extractedName);
          }
          if (result.idNumber.isNotEmpty) {
            _nationalIdController.text = result.idNumber;
          }
          if (result.address.isNotEmpty) {
            _addressController.text = result.address;
          }
          if (result.documentImageUrl.isNotEmpty) {
            _idCardPhotoUrl = result.documentImageUrl;
          }
        });

        TashilSnackBar.showSuccess(
          context: context,
          message: loc.tr('idCardScannedSuccess'),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanningOcr = false);
    }
  }

  /// Open full-screen zoomed preview for the scanned ID card image
  void _showFullCardPreview(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(ctx).colorScheme.outlineVariant,
              width: 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.badge_rounded, color: Theme.of(ctx).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(ctx).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    TashilIconButton.close(
                      onPressed: () => Navigator.of(ctx).pop(),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),
              const TashilDivider.fullWidth(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 480),
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Padding(
                      padding: const EdgeInsets.all(40),
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(AppLocalizations loc) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final firstName = _firstNameController.text.trim();
      final surname = _surnameController.text.trim();
      final localPhone = _phoneController.text.trim();
      final phone = localPhone.isNotEmpty ? '$_countryCode $localPhone' : '';
      final nationalId = _nationalIdController.text.trim();
      final address = _addressController.text.trim();
      final bankName = _isCustomBank
          ? _customBankController.text.trim()
          : _bankNameController.text.trim();
      final bankAccountNumber = _bankAccountNumberController.text.trim();

      await UserProfileService().updateProfile(
        firstName: firstName,
        surname: surname,
        phone: phone,
        preferredContactMethod: _preferredContactMethod,
        photoUrl: _photoUrl,
        isPhoneVerified: _isPhoneVerified,
        nationalId: nationalId,
        address: address,
        idCardPhotoUrl: _idCardPhotoUrl,
        bankName: bankName,
        bankAccountNumber: bankAccountNumber,
        iban: bankAccountNumber,
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

    final completenessRatio = _calculateCurrentCompleteness();
    final completenessPercent = (completenessRatio * 100).round();
    final isUAE = CountryController.isUAE || _countryCode == '+971';

    return TashilModalDialog(
      title: loc.tr('personalInfo'),
      subtitle: loc.tr('editProfileSubtitle'),
      icon: Icons.manage_accounts_rounded,
      maxWidth: 560,
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
                            radius: 40,
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
                      _emailController.text.isNotEmpty ? _emailController.text : 'mohamed.fathalla@gmail.com',
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
              const SizedBox(height: 14),

              // 2. Profile Completeness Live Progress Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: completenessRatio >= 1.0
                      ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                      : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: completenessRatio >= 1.0
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              completenessRatio >= 1.0
                                  ? Icons.check_circle_rounded
                                  : Icons.shield_outlined,
                              size: 15,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              loc.tr('profileCompleteness'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$completenessPercent%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completenessRatio,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. AI Document OCR National ID Scanner Banner & Card Preview
              if (_idCardPhotoUrl != null && _idCardPhotoUrl!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Thumbnail with click-to-zoom
                      GestureDetector(
                        onTap: () => _showFullCardPreview(
                          context,
                          _idCardPhotoUrl!,
                          isUAE ? loc.tr('emiratesIdLabel') : loc.tr('idCardPreviewTitle'),
                        ),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ImageUtils.cachedImage(
                                imageUrl: _idCardPhotoUrl!,
                                width: 100,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.zoom_in_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.verified_rounded, size: 16, color: colorScheme.primary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    isUAE ? loc.tr('emiratesIdLabel') : loc.tr('idCardPreviewTitle'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.tr('tapToViewFullCard'),
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _isScanningOcr ? null : () => _handleScanIdWithAi(loc),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 14, color: colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    loc.tr('rescanIdCard'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.5),
                        colorScheme.surfaceContainerHigh,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.document_scanner_rounded, size: 18, color: colorScheme.onPrimary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.tr('scanIdWithAi'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              isUAE
                                  ? 'استخراج بيانات الهوية الإماراتية وحفظ الصورة تلقائياً'
                                  : 'استخراج الرقم القومي والاسم والعنوان وتعبئة الحقول فورياً',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TashilButton.tonal(
                        label: 'مسح AI',
                        icon: Icons.flash_on_rounded,
                        isLoading: _isScanningOcr,
                        onPressed: () => _handleScanIdWithAi(loc),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // 4. Basic Info M3 Form Fields
              Row(
                children: [
                  Expanded(
                    child: TashilTextField.outlined(
                      controller: _firstNameController,
                      labelText: loc.tr('firstNameLabel'),
                      prefixIcon: Icons.person_outline_rounded,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TashilTextField.outlined(
                      controller: _surnameController,
                      labelText: loc.tr('surnameLabel'),
                      prefixIcon: Icons.badge_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Editable Email Address field
              TashilTextField.outlined(
                controller: _emailController,
                labelText: loc.tr('emailAddress'),
                prefixIcon: Icons.email_outlined,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              // Phone with OTP Verification
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
                          _initBankSelection(_bankNameController.text);
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

              // 5. Official Identity & Address Section
              Row(
                children: [
                  Icon(Icons.badge_rounded, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    loc.tr('officialIdentitySectionTitle'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // National ID (14 digits) or Emirates ID
              TashilTextField.outlined(
                controller: _nationalIdController,
                labelText: isUAE ? loc.tr('emiratesIdLabel') : loc.tr('nationalIdLabel'),
                prefixIcon: Icons.credit_card_rounded,
                keyboardType: TextInputType.number,
                maxLength: isUAE ? 18 : 14,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              // Full Address as on ID Card
              TashilTextField.outlined(
                controller: _addressController,
                labelText: loc.tr('officialAddressLabel'),
                prefixIcon: Icons.location_on_outlined,
                suffixIcon: Icons.my_location_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // 6. Landlord Bank Payout Details Section
              Row(
                children: [
                  Icon(Icons.account_balance_rounded, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    loc.tr('bankPayoutSectionTitle'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dynamic Bank Directory Dropdown Menu
              Builder(
                builder: (ctx) {
                  final activeCountry = isUAE ? 'AE' : 'EG';
                  final bankList = BankDirectoryService.getBanksForCountry(activeCountry);
                  final lang = LocaleController.languageCode;

                  final bankItems = bankList.map((bank) {
                    return TashilDropdownMenuItem<String?>(
                      value: bank.code,
                      label: bank.localizedName(lang),
                      icon: bank.isOther ? Icons.edit_note_rounded : Icons.account_balance_outlined,
                      supportingText: bank.isOther ? null : (isUAE ? 'CBUAE' : 'CBE'),
                    );
                  }).toList();

                  // Validate selected bank code belongs to active directory
                  final validSelection = bankList.any((b) => b.code == _selectedBankCode)
                      ? _selectedBankCode
                      : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TashilDropdownMenu<String?>(
                        value: validSelection,
                        items: bankItems,
                        labelText: loc.tr('bankNameLabel'),
                        hintText: loc.tr('selectBankPlaceholder'),
                        prefixIcon: Icons.account_balance_outlined,
                        isSearchable: true,
                        searchHintText: loc.tr('searchBankPlaceholder'),
                        height: 52,
                        maxMenuHeight: 320,
                        onChanged: (val) {
                          setState(() {
                            _selectedBankCode = val;
                            if (val == BankDirectoryService.otherBankCode) {
                              _isCustomBank = true;
                              _bankNameController.text = _customBankController.text.trim();
                            } else if (val != null) {
                              _isCustomBank = false;
                              final selectedBank = bankList.firstWhere((b) => b.code == val);
                              _bankNameController.text = selectedBank.localizedName(lang);
                            } else {
                              _isCustomBank = false;
                              _bankNameController.clear();
                            }
                          });
                        },
                      ),
                      if (_isCustomBank) ...[
                        const SizedBox(height: 10),
                        TashilTextField.outlined(
                          controller: _customBankController,
                          labelText: loc.tr('customBankNameLabel'),
                          prefixIcon: Icons.edit_note_rounded,
                          onChanged: (text) {
                            setState(() {
                              _bankNameController.text = text.trim();
                            });
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              TashilTextField.outlined(
                controller: _bankAccountNumberController,
                labelText: loc.tr('bankAccountOrIbanLabel'),
                prefixIcon: Icons.payments_outlined,
                textDirection: TextDirection.ltr,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // 7. Preferred Contact Method (Connected Button Group)
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
