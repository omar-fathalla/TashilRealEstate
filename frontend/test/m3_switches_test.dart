import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/design_system/switches/tashil_switches.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithTheme(Widget child, {Locale locale = const Locale('ar')}) {
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

  group('Official Google Material Design 3 (M3) Switches Suite Tests', () {
    testWidgets('TashilSwitch renders with official M3 dimensions and toggles with animated checkmark', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return TashilSwitch(
                value: isSelected,
                showIcon: true,
                onChanged: (val) => setState(() => isSelected = val),
              );
            },
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      // Verify switch exists
      expect(find.byType(TashilSwitch), findsOneWidget);

      // Verify unselected state: no checkmark icon visible initially
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // Verify track size: 52 x 32 dp
      final trackSize = tester.getSize(find.byType(SizedBox).first);
      expect(trackSize.width, equals(52.0));
      expect(trackSize.height, equals(32.0));

      // Tap to toggle ON
      await tester.tap(find.byType(TashilSwitch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(isSelected, isTrue);
      // Now checkmark icon is rendered
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Tap to toggle OFF
      await tester.tap(find.byType(TashilSwitch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(isSelected, isFalse);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('TashilSwitch handles RTL directionality correctly for Arabic', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return TashilSwitch(
                value: isSelected,
                onChanged: (val) => setState(() => isSelected = val),
              );
            },
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TashilSwitch), findsOneWidget);

      // Tap in RTL mode
      await tester.tap(find.byType(TashilSwitch));
      await tester.pumpAndSettle();

      expect(isSelected, isTrue);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('TashilSwitchListTile toggles when tapping anywhere on row', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return TashilSwitchListTile(
                title: const Text('خصومات السداد المقدم'),
                subtitle: const Text('تفاصيل إضافية'),
                secondary: const Icon(Icons.discount_rounded),
                value: isSelected,
                onChanged: (val) => setState(() => isSelected = val),
              );
            },
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('خصومات السداد المقدم'), findsOneWidget);
      expect(find.text('تفاصيل إضافية'), findsOneWidget);
      expect(find.byIcon(Icons.discount_rounded), findsOneWidget);
      expect(find.byType(TashilSwitch), findsOneWidget);

      // Tap on title text to toggle
      await tester.tap(find.text('خصومات السداد المقدم'));
      await tester.pumpAndSettle();

      expect(isSelected, isTrue);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('M3SwitchesShowcaseDialog renders and operates cleanly', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithTheme(
          const M3SwitchesShowcaseDialog(),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(M3SwitchesShowcaseDialog), findsOneWidget);
      expect(find.text('مفاتيح التبديل الرسمية (M3 Switch)'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('Bluetooth'), findsOneWidget);
      expect(find.byType(TashilSwitch), findsWidgets);
      expect(find.byType(TashilSwitchListTile), findsNWidgets(2));
    });
  });
}

