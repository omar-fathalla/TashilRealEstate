import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/services/firebase_auth_service.dart';
import 'package:tashil_real_estate/core/services/firestore_service.dart';
import 'package:tashil_real_estate/core/utils/responsive_layout.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/snackbars/tashil_snackbars.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/core/services/storage/property_draft_cache_service.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/core/utils/user_avatar_utils.dart';
import 'package:tashil_real_estate/core/widgets/app_settings_dialog.dart';

enum AuthMethod {
  google,
  apple,
  email,
  phoneOtp,
}

class LoginScreen extends StatefulWidget {
  final FirebaseAuthService? authService;
  final FirestoreService? firestoreService;

  const LoginScreen({
    super.key,
    this.authService,
    this.firestoreService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  AuthMethod _selectedAuthMethod = AuthMethod.email;
  String _selectedRole = 'Owner'; // 'Owner', 'AgencyAdmin', 'Tenant', 'SuperAdmin'
  bool _isSignUpMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Email form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Phone OTP form controllers
  final _phoneController = TextEditingController(text: '01012345678');
  final _otpController = TextEditingController(text: '123456');
  bool _isOtpSent = false;
  String? _verificationId;
  int _resendCountdown = 45;
  Timer? _countdownTimer;

  FirebaseAuthService? _customAuthService;
  FirebaseAuthService get _authService => widget.authService ?? (_customAuthService ??= FirebaseAuthService());

  FirestoreService? _customFirestoreService;
  FirestoreService get _firestoreService => widget.firestoreService ?? (_customFirestoreService ??= FirestoreService());

  late AnimationController _cardAnimController;
  late Animation<double> _cardFadeAnim;
  late Animation<Offset> _cardSlideAnim;

  @override
  void initState() {
    super.initState();
    if (CountryController.isUAE) {
      _phoneController.text = '0501234567';
    }

    _cardAnimController = AnimationController(
      vsync: this,
      duration: TashilMotionDuration.medium4,
    );

    _cardFadeAnim = CurvedAnimation(
      parent: _cardAnimController,
      curve: TashilMotionEasing.emphasizedDecelerate,
    );

    _cardSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimController,
      curve: TashilMotionEasing.emphasizedDecelerate,
    ));

    _cardAnimController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _countdownTimer?.cancel();
    _cardAnimController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 45;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handlePostAuthNavigation(User user, String role) async {
    final uid = user.uid;
    final photoUrl = UserAvatarUtils.getPhotoUrl(user);
    String? existingRole = await _firestoreService.getUserRole(uid);

    if (existingRole == null || existingRole.isEmpty) {
      existingRole = role;
      await _firestoreService.setUserRole(
        uid: uid,
        email: user.email ?? 'user@tashil.com',
        role: existingRole,
        fullName: user.displayName,
        photoUrl: photoUrl,
      );
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      await _firestoreService.updateUserPhoto(uid: uid, photoUrl: photoUrl);
    }

    await UserProfileService().loadProfile();

    if (!mounted) return;

    // Check if user has a pending property onboarding draft or requested redirect
    try {
      final uri = GoRouterState.of(context).uri;
      final redirect = uri.queryParameters['redirect'];
      if (redirect == '/fast-onboarding' || PropertyDraftCacheService().hasDraft()) {
        context.go('/fast-onboarding');
        return;
      }
    } catch (_) {}

    switch (existingRole) {
      case 'SuperAdmin':
        context.go('/super-admin');
        break;
      case 'AgencyAdmin':
        context.go('/agency');
        break;
      case 'Tenant':
        context.go('/tenant');
        break;
      case 'Owner':
      default:
        context.go('/owner');
        break;
    }
  }

  Future<void> _handleEmailAuth(AppLocalizations loc) async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      TashilSnackBar.showWarning(
        context: context,
        message: loc.tr('fillAllFieldsValidation'),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential? creds;
      if (_isSignUpMode) {
        creds = await _authService.signUpWithEmail(email, pass);
        if (name.isNotEmpty && creds?.user != null) {
          await creds!.user!.updateDisplayName(name);
        }
      } else {
        creds = await _authService.signInWithEmail(email, pass);
      }

      if (creds?.user != null) {
        await _handlePostAuthNavigation(creds!.user!, _selectedRole);
      }
    } catch (e) {
      if (!mounted) return;
      TashilSnackBar.showError(
        context: context,
        message: '${loc.tr('authFailedError')}: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleAuth(AppLocalizations loc) async {
    setState(() => _isLoading = true);
    try {
      final creds = await _authService.signInWithGoogle();
      if (creds?.user != null) {
        await _handlePostAuthNavigation(creds!.user!, _selectedRole);
      }
    } catch (e) {
      if (!mounted) return;
      TashilSnackBar.showError(
        context: context,
        message: '${loc.tr('authFailedError')}: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleAuth(AppLocalizations loc) async {
    setState(() => _isLoading = true);
    try {
      final creds = await _authService.signInWithApple();
      if (creds?.user != null) {
        await _handlePostAuthNavigation(creds!.user!, _selectedRole);
      }
    } catch (e) {
      if (!mounted) return;
      TashilSnackBar.showError(
        context: context,
        message: '${loc.tr('authFailedError')}: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendOtp(AppLocalizations loc) async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      TashilSnackBar.showWarning(
        context: context,
        message: loc.tr('enterPhoneValidation'),
      );
      return;
    }

    final dialCode = CountryController.isUAE ? '+971' : '+20';
    final formattedPhone = rawPhone.startsWith('0')
        ? '$dialCode${rawPhone.substring(1)}'
        : '$dialCode$rawPhone';

    setState(() => _isLoading = true);

    try {
      await _authService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final creds = await FirebaseAuth.instance.signInWithCredential(credential);
          if (creds.user != null && mounted) {
            await _handlePostAuthNavigation(creds.user!, _selectedRole);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          TashilSnackBar.showError(
            context: context,
            message: '${loc.tr('smsVerificationFailed')}: ${e.message}',
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
          _startResendTimer();
          TashilSnackBar.showSuccess(
            context: context,
            message: loc.tr('otpCodeSentSuccess'),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp(AppLocalizations loc) async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      TashilSnackBar.showWarning(
        context: context,
        message: loc.tr('enterSixDigitOtpLabel'),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.verifyOtpAndSignIn(
        verificationId: _verificationId ?? 'demo_verif_id',
        smsCode: smsCode,
      );

      if (user != null && mounted) {
        await _handlePostAuthNavigation(user, _selectedRole);
      }
    } catch (e) {
      if (!mounted) return;
      TashilSnackBar.showError(
        context: context,
        message: '${loc.tr('otpVerifyFailed')}: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAsDemo(String email, String pass, String role, AppLocalizations loc) async {
    setState(() {
      _emailController.text = email;
      _passwordController.text = pass;
      _selectedRole = role;
      _selectedAuthMethod = AuthMethod.email;
      _isSignUpMode = false;
    });

    await _handleEmailAuth(loc);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.currentLocale,
      builder: (context, locale, child) {
        return ValueListenableBuilder<String>(
          valueListenable: CountryController.currentCountry,
          builder: (context, countryCode, _) {
            final loc = AppLocalizations.of(context);
            final isRtl = Directionality.of(context) == TextDirection.rtl;

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              child: Scaffold(
                backgroundColor: colorScheme.surface,
                // Top Header: Retains ONLY the Settings icon as requested by user
                appBar: AppBar(
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                      color: colorScheme.onSurface,
                    ),
                    tooltip: loc.tr('browseAsVisitor'),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  actions: [
                    // Single Unified Settings Icon Button (conforming to M3 standard)
                    TashilIconButton.tonal(
                      icon: Icons.tune_rounded,
                      size: 38,
                      iconSize: 20,
                      tooltip: loc.tr('settings'),
                      onPressed: () => AppSettingsDialog.show(context),
                    ),
                    const SizedBox(width: 14),
                  ],
                ),
                body: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 14 : 24),
                    child: FadeTransition(
                      opacity: _cardFadeAnim,
                      child: SlideTransition(
                        position: _cardSlideAnim,
                        child: Container(
                          width: isMobile ? double.infinity : 540,
                          padding: EdgeInsets.all(isMobile ? 20 : 32),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(colorScheme.brightness == Brightness.dark ? 70 : 25),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: colorScheme.outlineVariant.withAlpha(120),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Branding Header
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withAlpha(80),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.apartment_rounded,
                                    size: 30,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                loc.tr('appName'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loc.tr('unifiedAuthGatewaySubtitle'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 22),

                              // 2. Role Selector (Official TashilConnectedButtonGroup)
                              Text(
                                loc.tr('selectAccountRoleTitle'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildRoleConnectedGroup(loc, colorScheme),
                              const SizedBox(height: 18),

                              // 3. Auth Method Selector (Official TashilConnectedButtonGroup)
                              _buildAuthMethodConnectedGroup(loc, colorScheme),
                              const SizedBox(height: 20),

                              // 4. Dynamic Sub-Form with M3 Shared Axis Motion Transition
                              AnimatedSwitcher(
                                duration: TashilMotionDuration.medium2,
                                switchInCurve: TashilMotionEasing.emphasizedDecelerate,
                                switchOutCurve: TashilMotionEasing.emphasizedAccelerate,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.0, 0.05),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey(_selectedAuthMethod),
                                  child: _buildCurrentAuthForm(loc, colorScheme),
                                ),
                              ),

                              const SizedBox(height: 18),
                              TashilDivider.withLabel(
                                label: loc.tr('demoAccounts'),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              const SizedBox(height: 10),

                              // 5. Quick Demo Accounts Suite (Google Icons Only)
                              _buildDemoAccountsSuite(loc, colorScheme),

                              const SizedBox(height: 16),

                              // 6. Public Marketplace Visitor Link
                              Center(
                                child: TashilButton.text(
                                  onPressed: () => context.go('/'),
                                  icon: Icons.travel_explore_rounded,
                                  label: loc.tr('browseAsVisitor'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- CONNECTED BUTTON GROUPS ---

  Widget _buildRoleConnectedGroup(AppLocalizations loc, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;

        return TashilConnectedButtonGroup<String>(
          height: 44,
          isFullWidth: !isCompact,
          selectedValue: _selectedRole,
          onSelectionChanged: (newRole) {
            setState(() => _selectedRole = newRole);
          },
          segments: [
            TashilConnectedButtonSegment(
              value: 'Owner',
              label: loc.tr('roleOwner'),
              icon: Icons.person_rounded,
            ),
            TashilConnectedButtonSegment(
              value: 'AgencyAdmin',
              label: loc.tr('roleAgency'),
              icon: Icons.business_rounded,
            ),
            TashilConnectedButtonSegment(
              value: 'Tenant',
              label: loc.tr('roleTenant'),
              icon: Icons.home_rounded,
            ),
            TashilConnectedButtonSegment(
              value: 'SuperAdmin',
              label: loc.tr('roleSuperAdmin'),
              icon: Icons.shield_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuthMethodConnectedGroup(AppLocalizations loc, ColorScheme colorScheme) {
    return TashilConnectedButtonGroup<AuthMethod>(
      height: 44,
      isFullWidth: true,
      selectedValue: _selectedAuthMethod,
      onSelectionChanged: (method) {
        setState(() => _selectedAuthMethod = method);
      },
      segments: [
        const TashilConnectedButtonSegment(
          value: AuthMethod.google,
          label: 'Google',
          icon: Icons.g_mobiledata_rounded,
        ),
        const TashilConnectedButtonSegment(
          value: AuthMethod.apple,
          label: 'Apple',
          icon: Icons.apple_rounded,
        ),
        TashilConnectedButtonSegment(
          value: AuthMethod.email,
          label: loc.tr('emailWord'),
          icon: Icons.mail_outline_rounded,
        ),
        TashilConnectedButtonSegment(
          value: AuthMethod.phoneOtp,
          label: loc.tr('phoneOtpWord'),
          icon: Icons.smartphone_rounded,
        ),
      ],
    );
  }

  Widget _buildCurrentAuthForm(AppLocalizations loc, ColorScheme colorScheme) {
    switch (_selectedAuthMethod) {
      case AuthMethod.google:
        return _buildGoogleCard(loc, colorScheme);
      case AuthMethod.apple:
        return _buildAppleCard(loc, colorScheme);
      case AuthMethod.phoneOtp:
        return _buildPhoneOtpForm(loc, colorScheme);
      case AuthMethod.email:
        return _buildEmailPasswordForm(loc, colorScheme);
    }
  }

  // --- GOOGLE LOGIN CARD ---
  Widget _buildGoogleCard(AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        children: [
          Icon(Icons.g_mobiledata_rounded, size: 48, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            loc.tr('signInWithGoogleDesc'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: TashilButton(
              onPressed: _isLoading ? null : () => _handleGoogleAuth(loc),
              icon: Icons.account_circle_rounded,
              label: loc.tr('continueWithGoogleBtn'),
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  // --- APPLE LOGIN CARD ---
  Widget _buildAppleCard(AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        children: [
          Icon(Icons.apple_rounded, size: 48, color: colorScheme.onSurface),
          const SizedBox(height: 8),
          Text(
            loc.tr('signInWithAppleDesc'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: TashilButton(
              onPressed: _isLoading ? null : () => _handleAppleAuth(loc),
              icon: Icons.fingerprint_rounded,
              label: loc.tr('continueWithAppleBtn'),
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  // --- PHONE OTP FORM ---
  Widget _buildPhoneOtpForm(AppLocalizations loc, ColorScheme colorScheme) {
    final dialCode = CountryController.isUAE ? '+971' : '+20';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.tr('phoneOtpAuthTitle'),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Phone input with Dial Code Prefix (Strictly LTR across all locales: Code on Left, Number on Right)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Text(
                    dialCode,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      labelText: loc.tr('phoneNumberLabel'),
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (!_isOtpSent) ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TashilButton(
                onPressed: _isLoading ? null : () => _handleSendOtp(loc),
                icon: Icons.send_rounded,
                label: loc.tr('sendOtpSmsCodeBtn'),
                isLoading: _isLoading,
              ),
            ),
          ] else ...[
            // 6-Digit OTP Field (Strictly LTR across all locales)
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 6),
                decoration: InputDecoration(
                  labelText: loc.tr('enterSixDigitOtpLabel'),
                  prefixIcon: const Icon(Icons.pin_rounded, size: 18),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLowest,
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _resendCountdown > 0
                      ? '${loc.tr('resendOtpIn')} 00:${_resendCountdown.toString().padLeft(2, '0')}'
                      : loc.tr('didNotReceiveOtp'),
                  style: TextStyle(fontSize: 11.5, color: colorScheme.onSurfaceVariant),
                ),
                if (_resendCountdown == 0)
                  TextButton(
                    onPressed: () => _handleSendOtp(loc),
                    child: Text(
                      loc.tr('resendOtpBtn'),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: TashilButton(
                onPressed: _isLoading ? null : () => _handleVerifyOtp(loc),
                label: loc.tr('verifyAndEnterBtn'),
                isLoading: _isLoading,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- EMAIL & PASSWORD FORM ---
  Widget _buildEmailPasswordForm(AppLocalizations loc, ColorScheme colorScheme) {
    return Column(
      children: [
        if (_isSignUpMode) ...[
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: loc.tr('fullNameLabel'),
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: loc.tr('email'),
            prefixIcon: const Icon(Icons.email_outlined, size: 18),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: loc.tr('password'),
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerLow,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TashilButton(
            onPressed: _isLoading ? null : () => _handleEmailAuth(loc),
            icon: _isSignUpMode ? Icons.person_add_rounded : Icons.login_rounded,
            label: _isSignUpMode ? loc.tr('createAccountBtn') : loc.tr('signIn'),
            isLoading: _isLoading,
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
          child: Text(
            _isSignUpMode ? loc.tr('alreadyHaveAccountSignIn') : loc.tr('dontHaveAccountSignUp'),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // --- DEMO ACCOUNTS SUITE ---
  Widget _buildDemoAccountsSuite(AppLocalizations loc, ColorScheme colorScheme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildDemoBtn('owner@test.com', 'Owner', loc.tr('roleOwner'), Icons.person_rounded, loc),
        _buildDemoBtn('agency@test.com', 'AgencyAdmin', loc.tr('roleAgency'), Icons.business_rounded, loc),
        _buildDemoBtn('tenant@test.com', 'Tenant', loc.tr('roleTenant'), Icons.home_rounded, loc),
        _buildDemoBtn('admin@test.com', 'SuperAdmin', loc.tr('roleSuperAdmin'), Icons.shield_rounded, loc),
      ],
    );
  }

  Widget _buildDemoBtn(String email, String role, String label, IconData icon, AppLocalizations loc) {
    return TashilButton.outlined(
      onPressed: _isLoading ? null : () => _loginAsDemo(email, 'password123', role, loc),
      icon: icon,
      label: label,
      height: 38,
    );
  }
}
