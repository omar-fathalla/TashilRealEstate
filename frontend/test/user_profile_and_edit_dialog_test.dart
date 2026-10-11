import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/country_controller.dart';
import 'package:tashil_real_estate/core/services/user_profile_service.dart';
import 'package:tashil_real_estate/features/owner_portal/dialogs/edit_profile_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/owner_dashboard.dart';

void main() {
  group('UserProfileData & Service Tests', () {
    test('Calculates completeness percentage accurately across all official identity points (Email, Name, Phone, National ID, Address, Bank)', () {
      // 1. Only email: 1/6 = 17%
      const p1 = UserProfileData(
        uid: 'user_123',
        email: 'mohamed@gmail.com',
        fullName: '',
        phone: '',
      );
      expect(p1.completenessPercent, equals(17));
      expect(p1.hasPhone, isFalse);

      // 2. Email & name: 2/6 = 33%
      final p2 = p1.copyWith(fullName: 'Mohamed Fathallah');
      expect(p2.completenessPercent, equals(33));
      expect(p2.hasFullName, isTrue);

      // 3. Email, Name, and Phone: 3/6 = 50%
      final p3 = p2.copyWith(phone: '+20 100 123 4567');
      expect(p3.completenessPercent, equals(50));
      expect(p3.hasPhone, isTrue);

      // 4. Email, Name, Phone, National ID: 4/6 = 67%
      final p4 = p3.copyWith(nationalId: '29304150102432');
      expect(p4.completenessPercent, equals(67));
      expect(p4.hasNationalId, isTrue);

      // 5. Email, Name, Phone, National ID, Address: 5/6 = 83%
      final p5 = p4.copyWith(address: 'التجمع الخامس، القاهرة');
      expect(p5.completenessPercent, equals(83));
      expect(p5.hasAddress, isTrue);

      // 6. Fully completed profile (Email, Name, Phone, ID, Address, Bank): 6/6 = 100%
      final p6 = p5.copyWith(bankName: 'البنك الأهلي المصري (NBE)', bankAccountNumber: '1234567890');
      expect(p6.completeness, equals(1.0));
      expect(p6.completenessPercent, equals(100));
      expect(p6.hasBankInfo, isTrue);
    });

    test('UserProfileService updates state reactively and derives Name and Surname', () async {
      final service = UserProfileService();
      const mockProfile = UserProfileData(
        uid: 'test_owner_1',
        email: 'fathalla.dev@gmail.com',
        fullName: 'Mohamed Fathallah',
        phone: '+20 10 9876 5432',
        nationalId: '29304150102432',
        address: 'التجمع الخامس، القاهرة',
        bankName: 'البنك الأهلي المصري (NBE)',
        bankAccountNumber: '1234567890',
      );

      service.setMockProfile(mockProfile);

      expect(service.profileNotifier.value.email, equals('fathalla.dev@gmail.com'));
      expect(service.profileNotifier.value.fullName, equals('Mohamed Fathallah'));
      expect(service.profileNotifier.value.computedFirstName, equals('Mohamed'));
      expect(service.profileNotifier.value.computedSurname, equals('Fathallah'));
      expect(service.profileNotifier.value.phone, equals('+20 10 9876 5432'));
      expect(service.profileNotifier.value.nationalId, equals('29304150102432'));
      expect(service.profileNotifier.value.address, equals('التجمع الخامس، القاهرة'));
      expect(service.profileNotifier.value.bankName, equals('البنك الأهلي المصري (NBE)'));
      expect(service.profileNotifier.value.completenessPercent, equals(100));
    });
  });

  group('Owner Profile Sheet & Edit Dialog Widget Tests', () {
    Widget buildTestableWidget(Widget child) {
      return MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
          Locale('hi'),
        ],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      );
    }

    testWidgets('EditProfileDialog renders Google photo, Name, Surname, and M3 Save button', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      UserProfileService().setMockProfile(
        const UserProfileData(
          uid: 'uid_test',
          email: 'fathalla80800@gmail.com',
          fullName: 'Mohamed Fathallah',
          firstName: 'Mohamed',
          surname: 'Fathallah',
          phone: '+20 1012345678',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(const EditProfileDialog()));
      await tester.pumpAndSettle();

      // Verify Google Account email display
      expect(find.text('fathalla80800@gmail.com'), findsWidgets);

      // Verify Full Name, First Name & Surname prefilled
      expect(find.text('Mohamed Fathallah'), findsOneWidget);
      expect(find.text('Mohamed'), findsOneWidget);
      expect(find.text('Fathallah'), findsOneWidget);

      // Verify Google Account badge & Google Photo sync chip
      expect(find.text('مرتبط بحساب Google'), findsOneWidget);
      expect(find.text('مزامنة صورة حساب Google'), findsOneWidget);

      // Verify Save (حفظ) and Cancel (إلغاء) buttons exist
      expect(find.text('حفظ'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);
    });

    testWidgets('Owner Profile BottomSheet renders dynamic user data and LTR contact rows', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      UserProfileService().setMockProfile(
        const UserProfileData(
          uid: 'uid_test',
          email: 'mohamed.fathalla@gmail.com',
          fullName: 'Mohamed Fathallah',
          phone: '+20 10 9999 8888',
          nationalId: '29304150102432',
          address: 'التجمع الخامس، القاهرة',
          bankName: 'البنك الأهلي المصري (NBE)',
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          Builder(
            builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  final loc = AppLocalizations.of(ctx);
                  final colorScheme = Theme.of(ctx).colorScheme;
                  OwnerDashboard.showProfileDetailsModal(ctx, loc, colorScheme);
                },
                child: const Text('Open Modal'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Ensure dynamic email is rendered instead of ahmed.fouad@tashil.com
      expect(find.text('mohamed.fathalla@gmail.com'), findsOneWidget);
      expect(find.text('ahmed.fouad@tashil.com'), findsNothing);

      // Ensure dynamic phone is rendered
      expect(find.text('+20 10 9999 8888'), findsOneWidget);

      // Verify LTR directionality exists on contact section
      final ltrFinder = find.byWidgetPredicate(
        (widget) => widget is Directionality && widget.textDirection == TextDirection.ltr,
      );
      expect(ltrFinder, findsWidgets);

      // Verify Completeness Indicator renders
      expect(find.text('100%'), findsOneWidget);

      // Verify that the Edit Profile button is now an M3 Icon Button with edit icon
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

      // Verify Official Identity & Address Section renders
      expect(find.text('بيانات الهوية الرسمية والعنوان'), findsOneWidget);
      expect(find.textContaining('29304150102432'), findsOneWidget);
      expect(find.textContaining('التجمع الخامس، القاهرة'), findsOneWidget);

      // Verify Bank Payout Details Section renders
      expect(find.text('بيانات التحويل البنكي للمالك'), findsOneWidget);
      expect(find.textContaining('البنك الأهلي المصري (NBE)'), findsOneWidget);

      // Verify quick edit button at bottom exists
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    });

    testWidgets('EditProfileDialog triggers OTP verification flow and displays OTP input', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      UserProfileService().setMockProfile(
        const UserProfileData(
          uid: 'uid_test',
          email: 'fathalla80800@gmail.com',
          fullName: 'Mohamed Fathallah',
          phone: '',
          isPhoneVerified: false,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(const EditProfileDialog()));
      await tester.pumpAndSettle();

      // Enter phone number
      final phoneInput = find.byKey(const Key('edit_profile_phone_input'));
      await tester.enterText(phoneInput, '01099887766');
      await tester.pumpAndSettle();

      // Verify Send OTP button appears
      expect(find.text('إرسال الرمز'), findsOneWidget);

      // Tap Send OTP
      await tester.tap(find.text('إرسال الرمز'));
      await tester.pumpAndSettle();

      // Verify OTP verification row appears
      expect(find.text('تأكيد الرمز'), findsOneWidget);

      // Enter OTP code 123456
      final otpInput = find.byKey(const Key('otp_code_field'));
      await tester.enterText(otpInput, '123456');
      await tester.pumpAndSettle();

      // Tap confirm
      await tester.tap(find.text('تأكيد الرمز'));
      await tester.pumpAndSettle();

      // Verify phone is verified
      expect(find.text('موثق'), findsOneWidget);
    });

    testWidgets('EditProfileDialog renders National ID, Address, Bank fields and AI OCR Scan button', (tester) async {
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      UserProfileService().setMockProfile(
        const UserProfileData(
          uid: 'uid_test',
          email: 'mohamed.fathalla@gmail.com',
          fullName: 'Mohamed Fathallah',
          phone: '+20 1012345678',
          nationalId: '29304150102432',
          address: 'التجمع الخامس، القاهرة',
          bankName: 'البنك الأهلي المصري (NBE)',
          bankAccountNumber: '1234567890',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(const EditProfileDialog()));
      await tester.pumpAndSettle();

      // Verify AI OCR Scan button exists
      expect(find.text('مسح AI'), findsOneWidget);
      expect(find.text('مسح البطاقة بالذكاء الاصطناعي'), findsOneWidget);

      // Verify National ID & Address fields render prefilled values
      expect(find.text('29304150102432'), findsOneWidget);
      expect(find.text('التجمع الخامس، القاهرة'), findsOneWidget);

      // Verify Bank Payout fields render prefilled values
      expect(find.text('البنك الأهلي المصري (NBE)'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);

      // Verify Section headers exist
      expect(find.text('بيانات الهوية الرسمية والعنوان'), findsOneWidget);
      expect(find.text('بيانات التحويل البنكي للمالك'), findsOneWidget);

      // Verify TashilDropdownMenu is used for Bank Name
      expect(find.byType(TashilDropdownMenu<String?>), findsOneWidget);
    });

    testWidgets('EditProfileDialog bank dropdown adapts to UAE banks when in UAE mode', (tester) async {
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        CountryController.setCountry('EG');
      });

      CountryController.setCountry('AE');
      UserProfileService().setMockProfile(
        const UserProfileData(
          uid: 'uid_ae_test',
          email: 'abdullah@tashil.ae',
          fullName: 'Abdullah Al Nuaimi',
          phone: '+971 501234567',
          nationalId: '784-1990-1234567-1',
          address: 'Downtown Dubai',
          bankName: 'Emirates NBD',
          bankAccountNumber: 'AE250260001234567890123',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(const EditProfileDialog()));
      await tester.pumpAndSettle();

      // Verify UAE Emirates NBD is preselected
      expect(find.text('بنك الإمارات دبي الوطني (Emirates NBD)'), findsOneWidget);
      expect(find.text('AE250260001234567890123'), findsOneWidget);

      // Verify TashilDropdownMenu is rendered
      final dropdown = tester.widget<TashilDropdownMenu<String?>>(find.byType(TashilDropdownMenu<String?>));
      expect(dropdown.isSearchable, isTrue);
    });

    testWidgets('EditProfileDialog renders custom bank text field when custom bank name is entered', (tester) async {
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      UserProfileService().setMockProfile(
        const UserProfileData(
          uid: 'uid_custom_bank',
          email: 'investor@global.com',
          fullName: 'International Investor',
          phone: '+20 1099887766',
          bankName: 'Swiss International Private Bank',
          bankAccountNumber: 'CH9300000000001234567',
        ),
      );

      await tester.pumpWidget(buildTestableWidget(const EditProfileDialog()));
      await tester.pumpAndSettle();

      // The custom bank name is displayed in the custom text field
      expect(find.text('Swiss International Private Bank'), findsWidgets);
    });
  });
}
