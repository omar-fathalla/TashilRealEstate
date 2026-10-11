import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          primary: const Color(0xFF0F172A),
        ),
      ),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('M3 Dialogs Suite Tests', () {
    testWidgets('TashilAlertDialog renders with 28dp radius, Level 3 elevation, icon and actions', (tester) async {
      bool actionFired = false;

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                TashilAlertDialog.show(
                  context: context,
                  iconData: Icons.notifications_active_outlined,
                  title: 'إشعار هام',
                  contentText: 'محتوى تجريبي للتنبيه الإرشادي لماتريال 3.',
                  actions: [
                    TashilButton(
                      label: 'موافق',
                      onPressed: () {
                        actionFired = true;
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
              child: const Text('افتح النافذة'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('افتح النافذة'));
      await tester.pumpAndSettle();

      // Verify presence of M3 title, content, icon, and button
      expect(find.text('إشعار هام'), findsOneWidget);
      expect(find.text('محتوى تجريبي للتنبيه الإرشادي لماتريال 3.'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      expect(find.text('موافق'), findsOneWidget);

      // Verify 28dp corner radius on dialog
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final shape = dialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(BorderRadius.circular(28.0)));
      expect(dialog.elevation, equals(3.0));

      // Tap action
      await tester.tap(find.text('موافق'));
      await tester.pumpAndSettle();
      expect(actionFired, isTrue);
      expect(find.text('إشعار هام'), findsNothing);
    });

    testWidgets('TashilModalDialog renders structured header, close button, and footer', (tester) async {
      bool closed = false;

      await tester.pumpWidget(
        wrapWithTheme(
          TashilModalDialog(
            title: 'تعديل بيانات الإعلان',
            subtitle: 'تقسيم ذكي بين الحقول الإجبارية والاختيارية',
            icon: Icons.edit_note_rounded,
            onClose: () => closed = true,
            footer: const Text('شريط الأزرار السفلي'),
            child: const Text('محتوى النموذج'),
          ),
        ),
      );

      // Verify header, title, subtitle, content, footer
      expect(find.text('تعديل بيانات الإعلان'), findsOneWidget);
      expect(find.text('تقسيم ذكي بين الحقول الإجبارية والاختيارية'), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
      expect(find.text('محتوى النموذج'), findsOneWidget);
      expect(find.text('شريط الأزرار السفلي'), findsOneWidget);

      // Verify 28dp corner radius
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      final shape = dialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(BorderRadius.circular(28.0)));

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);
    });

    testWidgets('TashilSelectionDialog currency picker selects option and closes', (tester) async {
      String? selectedCurrency;

      await tester.pumpWidget(
        wrapWithTheme(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedCurrency = await TashilSelectionDialog.showCurrencyPicker(
                  context: context,
                  currentCurrency: 'EGP',
                );
              },
              child: const Text('اختر العملة'),
            ),
          ),
        ),
      );

      // Open currency picker dialog
      await tester.tap(find.text('اختر العملة'));
      await tester.pumpAndSettle();

      // Verify currency options with flags and labels
      expect(find.text('اختيار العملة النقدية'), findsOneWidget);
      expect(find.text('ج.م (جنيه مصري)'), findsOneWidget);
      expect(find.text('د.إ (درهم إماراتي)'), findsOneWidget);
      expect(find.text('\$ (دولار أمريكي)'), findsOneWidget);

      // Select AED
      await tester.tap(find.text('د.إ (درهم إماراتي)'));
      await tester.pumpAndSettle();

      expect(selectedCurrency, equals('AED'));
      expect(find.text('اختيار العملة النقدية'), findsNothing);
    });
  });
}
