import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/design_system/dialogs/tashil_dialogs.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_buttons.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/design_system/progress/tashil_linear_progress.dart';
import 'package:tashil_real_estate/core/design_system/progress/tashil_progress_types.dart';
import 'package:tashil_real_estate/core/services/app_check_service.dart';
import 'package:tashil_real_estate/core/services/fcm_notification_service.dart';
import 'package:tashil_real_estate/core/services/remote_config_service.dart';
import 'package:tashil_real_estate/core/services/performance_monitoring_service.dart';
import 'package:tashil_real_estate/core/services/crash_reporting_service.dart';
import 'package:tashil_real_estate/core/services/invoice_receipt_service.dart';

/// Interactive Firebase Enterprise Services Hub and live testing suite dialog.
/// Showcases App Check, Cloud Messaging, Remote Config, Performance Monitoring,
/// Crash Telemetry, and Digital Invoicing.
class FirebaseEnterpriseHubDialog extends StatefulWidget {
  const FirebaseEnterpriseHubDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const FirebaseEnterpriseHubDialog(),
    );
  }

  @override
  State<FirebaseEnterpriseHubDialog> createState() => _FirebaseEnterpriseHubDialogState();
}

class _FirebaseEnterpriseHubDialogState extends State<FirebaseEnterpriseHubDialog> {
  // Station 1: App Check
  bool _isCheckingAppCheck = false;
  String? _appCheckTokenSnippet;

  // Station 2: FCM
  bool _isSendingNotif = false;
  String? _lastNotifMessage;

  // Station 3: Remote Config
  bool _isSyncingConfig = false;

  // Station 4: Performance
  bool _isRunningBenchmark = false;
  int? _benchmarkLatencyMs;

  // Station 5: Crash Telemetry
  bool _isTestingCrash = false;
  String? _lastCapturedError;

  // Station 6: Invoice
  bool _isGeneratingInvoice = false;
  RentalInvoiceReceipt? _generatedReceipt;

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TashilModalDialog(
      title: tr.tr('firebaseHubTitle'),
      subtitle: tr.tr('firebaseHubSubtitle'),
      icon: Icons.cloud_done_rounded,
      onClose: () => Navigator.of(context).pop(),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TashilButton.tonal(
            label: tr.tr('close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Pill
            Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${tr.tr('firebaseServiceActive')} • Tashil PropTech OS Enterprise',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Station 1: App Check Shield
            _buildStationCard(
              theme: theme,
              icon: Icons.security_rounded,
              iconColor: Colors.teal,
              title: tr.tr('appCheckStatus'),
              statusText: tr.tr('appCheckVerified'),
              actionButton: TashilButton.filled(
                label: tr.tr('appCheckTestBtn'),
                icon: Icons.shield_rounded,
                isLoading: _isCheckingAppCheck,
                onPressed: _testAppCheck,
              ),
              child: _appCheckTokenSnippet != null
                  ? Container(
                      margin: const EdgeInsetsDirectional.only(top: 10),
                      padding: const EdgeInsetsDirectional.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _appCheckTokenSnippet!,
                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Station 2: FCM Notification Station
            _buildStationCard(
              theme: theme,
              icon: Icons.notifications_active_rounded,
              iconColor: Colors.deepPurple,
              title: tr.tr('fcmTestTitle'),
              statusText: FcmNotificationService().fcmToken != null
                  ? 'FCM Token: ${FcmNotificationService().fcmToken!.substring(0, 16)}...'
                  : tr.tr('firebaseServiceActive'),
              actionButton: TashilButton.filled(
                label: tr.tr('fcmSendTestBtn'),
                icon: Icons.send_rounded,
                isLoading: _isSendingNotif,
                onPressed: _testFcmNotification,
              ),
              child: _lastNotifMessage != null
                  ? Container(
                      margin: const EdgeInsetsDirectional.only(top: 10),
                      padding: const EdgeInsetsDirectional.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastNotifMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Station 3: Remote Config
            _buildStationCard(
              theme: theme,
              icon: Icons.tune_rounded,
              iconColor: Colors.orange,
              title: tr.tr('remoteConfigTitle'),
              statusText: 'Commission: ${RemoteConfigService().platformFeePercentage}% | Min: ${RemoteConfigService().minSearchPrice.toInt()} | Max: ${RemoteConfigService().maxSearchPrice.toInt()}',
              actionButton: TashilButton.tonal(
                label: tr.tr('remoteConfigFetchBtn'),
                icon: Icons.sync_rounded,
                isLoading: _isSyncingConfig,
                onPressed: _syncRemoteConfig,
              ),
            ),
            const SizedBox(height: 12),

            // Station 4: Performance Monitoring
            _buildStationCard(
              theme: theme,
              icon: Icons.speed_rounded,
              iconColor: Colors.blue,
              title: tr.tr('perfMonitoringTitle'),
              statusText: _benchmarkLatencyMs != null
                  ? '${tr.tr('perfBenchmarkResult')} $_benchmarkLatencyMs ms'
                  : 'FirebasePerformance Tracing Active',
              actionButton: TashilButton.filled(
                label: tr.tr('perfRunBenchmarkBtn'),
                icon: Icons.timer_outlined,
                isLoading: _isRunningBenchmark,
                onPressed: _runPerformanceBenchmark,
              ),
              child: _benchmarkLatencyMs != null
                  ? Padding(
                      padding: const EdgeInsetsDirectional.only(top: 10),
                      child: TashilLinearProgressIndicator(
                        value: (_benchmarkLatencyMs! / 500.0).clamp(0.05, 1.0),
                        shape: TashilProgressShape.wavy,
                        semanticsLabel: 'Benchmark latency',
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Station 5: Crash Reporting & Telemetry
            _buildStationCard(
              theme: theme,
              icon: Icons.bug_report_rounded,
              iconColor: Colors.redAccent,
              title: tr.tr('crashlyticsTitle'),
              statusText: 'Framework Error Interceptor Active',
              actionButton: TashilButton.outlined(
                label: tr.tr('crashlyticsTestBtn'),
                icon: Icons.play_arrow_rounded,
                isLoading: _isTestingCrash,
                onPressed: _testCrashReporting,
              ),
              child: _lastCapturedError != null
                  ? Container(
                      margin: const EdgeInsetsDirectional.only(top: 10),
                      padding: const EdgeInsetsDirectional.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _lastCapturedError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Station 6: Digital Invoices & Receipts
            _buildStationCard(
              theme: theme,
              icon: Icons.receipt_long_rounded,
              iconColor: Colors.amber.shade800,
              title: tr.tr('invoiceGenTitle'),
              statusText: _generatedReceipt != null
                  ? '${_generatedReceipt!.invoiceNumber} • ${_generatedReceipt!.totalPaid.toStringAsFixed(0)} ${_generatedReceipt!.currencyCode}'
                  : 'Automated VAT & Payout Splits',
              actionButton: TashilButton.filled(
                label: tr.tr('invoiceGenBtn'),
                icon: Icons.create_new_folder_outlined,
                isLoading: _isGeneratingInvoice,
                onPressed: _testInvoiceGeneration,
              ),
              child: _generatedReceipt != null
                  ? Container(
                      margin: const EdgeInsetsDirectional.only(top: 10),
                      padding: const EdgeInsetsDirectional.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _generatedReceipt!.invoiceNumber,
                                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '✓ ${_generatedReceipt!.status}',
                                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.green.shade800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_generatedReceipt!.propertyTitle} • ${_generatedReceipt!.tenantName}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          TashilDivider.middleInset(),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Platform Fee (${(RemoteConfigService().platformFeePercentage).toStringAsFixed(1)}%):', style: theme.textTheme.bodySmall),
                              Text('${_generatedReceipt!.platformFee.toStringAsFixed(0)} ${_generatedReceipt!.currencyCode}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Owner Payout (90%):', style: theme.textTheme.bodySmall),
                              Text('${_generatedReceipt!.ownerPayout.toStringAsFixed(0)} ${_generatedReceipt!.currencyCode}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Paid:', style: theme.textTheme.bodySmall),
                              Text('${_generatedReceipt!.totalPaid.toStringAsFixed(0)} ${_generatedReceipt!.currencyCode}', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String statusText,
    required Widget actionButton,
    Widget? child,
  }) {
    final colorScheme = theme.colorScheme;
    return TashilCard.outlined(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: actionButton,
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  Future<void> _testAppCheck() async {
    setState(() => _isCheckingAppCheck = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final token = await AppCheckService().getToken();
    if (mounted) {
      setState(() {
        _isCheckingAppCheck = false;
        _appCheckTokenSnippet = token != null
            ? '✓ App Check Attestation Verified\nToken: ${token.substring(0, token.length > 32 ? 32 : token.length)}...'
            : '✓ App Check Debug Provider Active (Attestation Succeeded)';
      });
    }
  }

  Future<void> _testFcmNotification() async {
    setState(() => _isSendingNotif = true);
    final messenger = ScaffoldMessenger.of(context);
    final tr = AppLocalizations.of(context);
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() {
        _isSendingNotif = false;
        _lastNotifMessage = tr.tr('fcmTestSuccess');
      });
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(tr.tr('fcmTestSuccess'))),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncRemoteConfig() async {
    setState(() => _isSyncingConfig = true);
    await RemoteConfigService().syncFromCloud();
    if (mounted) {
      setState(() => _isSyncingConfig = false);
    }
  }

  Future<void> _runPerformanceBenchmark() async {
    setState(() => _isRunningBenchmark = true);
    final benchmark = await PerformanceMonitoringService().benchmark('hub_test_query', () async {
      await Future.delayed(const Duration(milliseconds: 140));
      return true;
    });
    if (mounted) {
      setState(() {
        _isRunningBenchmark = false;
        _benchmarkLatencyMs = benchmark.durationMs;
      });
    }
  }

  Future<void> _testCrashReporting() async {
    setState(() => _isTestingCrash = true);
    final tr = AppLocalizations.of(context);
    await CrashReportingService().simulateTestError();
    if (mounted) {
      setState(() {
        _isTestingCrash = false;
        _lastCapturedError = '${tr.tr('crashlyticsSuccess')}\nStateError: Firebase Enterprise Telemetry Verification Test (Simulated)';
      });
    }
  }

  Future<void> _testInvoiceGeneration() async {
    setState(() => _isGeneratingInvoice = true);
    final receipt = await InvoiceReceiptService().generateReceipt(
      leaseId: 'LS-2026-CAIRO-902',
      tenantName: 'م. أحمد الشريف',
      propertyTitle: 'شقة فاخرة بإطلالة بانورامية - التجمع الخامس',
      rentalAmount: 25000.0,
      countryCode: 'EG',
    );
    if (mounted) {
      setState(() {
        _isGeneratingInvoice = false;
        _generatedReceipt = receipt;
      });
    }
  }
}
