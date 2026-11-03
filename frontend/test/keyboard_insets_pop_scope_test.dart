import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/theme/app_theme.dart';
import 'package:tashil_real_estate/features/lease_builder/widgets/lease_builder_wizard_dialog.dart';
import 'package:tashil_real_estate/features/owner_portal/dialogs/edit_profile_dialog.dart';
import 'package:tashil_real_estate/core/design_system/motion/tashil_motion.dart';
import 'package:tashil_real_estate/features/super_admin/super_admin_login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(Widget home) {
    LocaleController.setLocale(const Locale('ar'));
    return MaterialApp(
      locale: const Locale('ar'),
      theme: AppTheme.getTheme(
          brightness: Brightness.light, locale: const Locale('ar')),
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('hi')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }

  testWidgets(
      'lease builder asks before discarding a dirty draft and keeps the footer above the keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(app(const LeaseBuilderWizardDialog()));
    await tester.pump();

    expect(
        find.byWidgetPredicate((widget) => widget is PopScope), findsWidgets);
    final footer =
        tester.getRect(find.text(AppLocalizations.trStatic('nextStep')));
    expect(footer.bottom, lessThan(844));

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();

    final lifted =
        tester.getRect(find.text(AppLocalizations.trStatic('nextStep')));
    expect(lifted.bottom, lessThanOrEqualTo(844 - 300));

    await tester.enterText(find.byType(TextField).first, 'مستأجر جديد');
    await tester.pump();
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();

    final close = find.byWidgetPredicate(
      (widget) =>
          widget is TashilIconButton &&
          widget.variant == TashilIconButtonVariant.close,
    );
    await tester.tap(close);
    await tester.pumpAndSettle();

    expect(find.text(AppLocalizations.trStatic('unsavedChangesTitle')),
        findsOneWidget);
    expect(find.text(AppLocalizations.trStatic('keepEditing')), findsOneWidget);
  });

  testWidgets('edit profile confirms unsaved changes before closing',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(app(const EditProfileDialog()));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'أحمد');
    await tester.pump();

    await tester.tap(find.text(AppLocalizations.trStatic('cancel')));
    await tester.pumpAndSettle();

    expect(find.text(AppLocalizations.trStatic('unsavedChangesTitle')),
        findsOneWidget);
    expect(
        find.text(AppLocalizations.trStatic('discardChanges')), findsOneWidget);
  });

  testWidgets(
      'admin login keeps fields reachable and blocks back while the form is up',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(app(const SuperAdminLoginScreen()));
    await tester.pump();

    expect(
        find.byWidgetPredicate((widget) => widget is PopScope), findsWidgets);
    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.length, greaterThanOrEqualTo(3));
    expect(fields[0].textInputAction, TextInputAction.next);
    expect(fields[1].textInputAction, TextInputAction.next);
    expect(fields[2].keyboardType, TextInputType.number);
    expect(fields[2].textInputAction, TextInputAction.done);
    expect(fields[2].scrollPadding, const EdgeInsets.only(bottom: 120));
    expect(fields[2].autofillHints, contains(AutofillHints.oneTimeCode));

    final signIn = find.text(AppLocalizations.trStatic('superAdminSignInBtn'));
    await tester.ensureVisible(signIn);
    await tester.pump();
    expect(tester.getRect(signIn).bottom, lessThanOrEqualTo(844));

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();
    await tester.ensureVisible(signIn);
    await tester.pump();
    expect(tester.getRect(signIn).bottom, lessThanOrEqualTo(844 - 300));
  });

  testWidgets('a long form applies the keyboard inset once', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding.zero;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(app(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () {
            TashilTransitions.showAdaptiveSheet<void>(
              context: context,
              longForm: true,
              builder: (ctx) => const Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(key: Key('form-body'), width: 48, height: 48),
              ),
            );
          },
          child: const Text('open-form'),
        ),
      ),
    )));
    await tester.pump();
    await tester.tap(find.text('open-form'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();

    final bottom = tester.getRect(find.byKey(const Key('form-body'))).bottom;
    expect(bottom, greaterThan(400));
    expect(bottom, lessThanOrEqualTo(844 - 280));
  });
}
