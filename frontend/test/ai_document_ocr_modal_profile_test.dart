import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/menus/tashil_menus.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/features/document_ocr/models/document_ocr_result_model.dart';
import 'package:tashil_real_estate/features/document_ocr/services/ai_document_ocr_service.dart';
import 'package:tashil_real_estate/features/document_ocr/widgets/ai_document_ocr_modal.dart';

import 'package:tashil_real_estate/core/localization/locale_controller.dart';

Widget buildTestableWidget(Widget child, {Locale locale = const Locale('ar')}) {
  LocaleController.setLocale(locale);
  return MaterialApp(
    locale: locale,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiDocumentOcrModal Profile Streamlining & M3 Interactive Tests', () {
    testWidgets('Profile Mode renders TashilDropdownMenu with exactly 2 ID options and no contract chips', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const AiDocumentOcrModal(
            countryCode: 'EG',
            targetParty: 'profile',
            initialDocType: DocumentOcrType.egyptianNationalId,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      // 1. Label "نوع وثيقة الهوية" is present
      expect(find.text('نوع وثيقة الهوية'), findsOneWidget);

      // 2. TashilDropdownMenu is rendered
      expect(find.byType(TashilDropdownMenu<String>), findsOneWidget);

      // 3. Dropdown shows Egyptian National ID by default for EG
      expect(find.text('مصر: بطاقة الرقم القومي'), findsOneWidget);

      // 4. Contract templates (like paper lease or title deeds) should NOT be displayed as selection chips in profile mode
      expect(find.text('مسودة عقد إيجار ورقي سابق'), findsNothing);
      expect(find.text('عقد ملكية وتخصيص هيئة المجتمعات العمرانية'), findsNothing);
    });

    testWidgets('Profile Mode renders TashilConnectedButtonGroup for photo upload and live camera capture', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const AiDocumentOcrModal(
            countryCode: 'EG',
            targetParty: 'profile',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      // 1. Connected Button Group is present and full width
      final groupFinder = find.byType(TashilConnectedButtonGroup<String>);
      expect(groupFinder, findsOneWidget);
      final groupWidget = tester.widget<TashilConnectedButtonGroup<String>>(groupFinder);
      expect(groupWidget.isFullWidth, isTrue);

      // 2. Camera is the first segment (right in RTL), Upload is the second segment (left in RTL)
      expect(groupWidget.segments[0].value, equals('camera'));
      expect(groupWidget.segments[1].value, equals('upload'));

      // 3. Contains concise labels "التقاط بالكاميرا" and "رفع صورة"
      expect(find.text('التقاط بالكاميرا'), findsOneWidget);
      expect(find.text('رفع صورة'), findsOneWidget);

      // 4. Contains upload and camera icons
      expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
      expect(find.byIcon(Icons.upload_file_rounded), findsOneWidget);
    });

    testWidgets('Profile Mode shortens bottom action button to "تطبيق البيانات" with modern task_alt_rounded checkmark', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const AiDocumentOcrModal(
            countryCode: 'EG',
            targetParty: 'profile',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      // 1. Shortened action button "تطبيق البيانات" is displayed
      expect(find.text('تطبيق البيانات'), findsOneWidget);

      // 2. Action button features the modern Google M3 task_alt_rounded open checkmark icon
      expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);

      // 3. Long contract-specific button is NOT displayed
      expect(find.text('تفريغ وتطبيق البيانات في العقد فوراً'), findsNothing);

      // 4. "إلغاء" cancel button is preserved
      expect(find.text('إلغاء'), findsOneWidget);

      // 5. Close button adheres to M3 shaded close button variant
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('Contract Mode retains contract-specific "تفريغ وتطبيق البيانات في العقد فوراً" and template chips', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const AiDocumentOcrModal(
            countryCode: 'EG',
            targetParty: 'contract',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      // In contract mode, the full action text is rendered
      expect(find.text('تفريغ وتطبيق البيانات في العقد فوراً'), findsOneWidget);
      expect(find.text('اختر أو ارفع نموذج المستند للفحص'), findsOneWidget);
    });

    testWidgets('Trilingual support: English rendering verifies pure text without hardcoding', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const AiDocumentOcrModal(
            countryCode: 'EG',
            targetParty: 'profile',
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      // English labels
      expect(find.text('Identity Document Type'), findsOneWidget);
      expect(find.text('Egypt: National ID'), findsOneWidget);
      expect(find.text('Upload Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Apply Data'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Image rotation controls rotate the preview and display degrees indicator', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const AiDocumentOcrModal(
            countryCode: 'EG',
            targetParty: 'profile',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      // Rotation and Zoom buttons are present
      expect(find.byIcon(Icons.rotate_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in_rounded), findsOneWidget);

      // Initially rotation turns is 0
      final initialRotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(initialRotatedBox.quarterTurns, equals(0));

      // Tap rotate right (90°)
      await tester.tap(find.byIcon(Icons.rotate_right_rounded));
      await tester.pump();

      // Degree indicator "90°" appears and RotatedBox has quarterTurns = 1
      expect(find.text('90°'), findsOneWidget);
      final rotatedBoxAfterRight = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(rotatedBoxAfterRight.quarterTurns, equals(1));

      // Tap reset button ("90°")
      await tester.tap(find.text('90°'));
      await tester.pump();

      // Returns to 0°
      expect(find.text('90°'), findsNothing);
      final resetRotatedBox = tester.widget<RotatedBox>(find.byType(RotatedBox));
      expect(resetRotatedBox.quarterTurns, equals(0));
    });

    testWidgets('Interactive zoom button opens zoom dialog with InteractiveViewer', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const AiDocumentOcrModal(
            countryCode: 'EG',
            targetParty: 'profile',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));

      // Tap Zoom button
      await tester.tap(find.byIcon(Icons.zoom_in_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // InteractiveViewer is rendered
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('تكبير وفحص'), findsOneWidget);

      // Dismiss dialog via close button
      final closeFinder = find.descendant(
        of: find.byType(Dialog),
        matching: find.byIcon(Icons.close_rounded),
      );
      await tester.tap(closeFinder.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Dialog is dismissed
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    test('AiDocumentOcrService deterministic extraction extracts authentic Egyptian ID data accurately', () async {
      final service = AiDocumentOcrService();
      final result = await service.processDocumentOcr(
        docType: DocumentOcrType.egyptianNationalId,
        countryCode: 'EG',
        sampleId: 'eg_national_id_lessor',
        customImageUrl: 'data:image/png;base64,custom_uploaded_id',
      );

      // Verify authentic Egyptian ID card data matches user's uploaded physical card
      expect(result.fullNameAr, equals('محمد احمد حسن فتح الله حسن'));
      expect(result.fullNameEn, equals('Mohamed Ahmed Hassan Fathallah Hassan'));
      expect(result.idNumber, equals('28709040200112'));
      expect(result.governorateOrEmirate, equals('الإسكندرية'));
      expect(result.address, contains('الجمرك'));
      expect(result.gender, equals('ذكر'));
      expect(result.dateOfBirth, equals('1987-09-04'));
      expect(result.securityStatus, equals('AUTHENTIC_VERIFIED'));
    });
  });
}
