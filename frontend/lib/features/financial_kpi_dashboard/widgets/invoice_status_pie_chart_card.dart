import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/cards/tashil_cards.dart';
import 'package:tashil_real_estate/core/design_system/dividers/tashil_dividers.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/utils/currency_formatter.dart';
import 'package:tashil_real_estate/features/financial_kpi_dashboard/models/financial_kpi_model.dart';

class InvoiceStatusPieChartCard extends StatelessWidget {
  final InvoiceStatusDistribution distribution;
  final String currency;
  final String lang;
  final bool isMobile;

  const InvoiceStatusPieChartCard({
    super.key,
    required this.distribution,
    required this.currency,
    required this.lang,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalCount = distribution.paidCount + distribution.pendingCount + distribution.overdueCount;

    final paidColor = colorScheme.primary;
    final pendingColor = colorScheme.tertiary;
    final overdueColor = colorScheme.error;

    return TashilCard.outlined(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pie_chart_rounded, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.tr('invoiceStatusDistributionChartTitle'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loc.tr('totalInvoicesCount')}: $totalCount ${loc.tr('invoicesWord')}',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const TashilDivider.middleInset(height: 24),

          // Multi-Segment Ring & Breakdown
          Row(
            children: [
              // Visual Multi-Segment Donut Widget
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(110, 110),
                      painter: _DonutChartPainter(
                        paidRatio: distribution.paidPercentage / 100,
                        pendingRatio: distribution.pendingPercentage / 100,
                        overdueRatio: distribution.overduePercentage / 100,
                        paidColor: paidColor,
                        pendingColor: pendingColor,
                        overdueColor: overdueColor,
                        trackColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${distribution.paidPercentage.toInt()}%',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: paidColor),
                        ),
                        Text(
                          loc.tr('paidRateShort'),
                          style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Detailed Itemized Breakdown List
              Expanded(
                child: Column(
                  children: [
                    _buildBreakdownRow(
                      title: loc.tr('statusPaidElectronically'),
                      amount: distribution.paidAmount,
                      count: distribution.paidCount,
                      percentage: distribution.paidPercentage,
                      color: paidColor,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      title: loc.tr('statusPendingPayment'),
                      amount: distribution.pendingAmount,
                      count: distribution.pendingCount,
                      percentage: distribution.pendingPercentage,
                      color: pendingColor,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 8),
                    _buildBreakdownRow(
                      title: loc.tr('statusOverdue'),
                      amount: distribution.overdueAmount,
                      count: distribution.overdueCount,
                      percentage: distribution.overduePercentage,
                      color: overdueColor,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String title,
    required double amount,
    required int count,
    required double percentage,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Wrap(
            spacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: colorScheme.onSurface),
              ),
              Text(
                '($count)',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          Text(
            '${CurrencyFormatter.formatAmount(amount, langCode: lang)} $currency (${percentage.toStringAsFixed(0)}%)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double paidRatio;
  final double pendingRatio;
  final double overdueRatio;
  final Color paidColor;
  final Color pendingColor;
  final Color overdueColor;
  final Color trackColor;

  _DonutChartPainter({
    required this.paidRatio,
    required this.pendingRatio,
    required this.overdueRatio,
    required this.paidColor,
    required this.pendingColor,
    required this.overdueColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 14.0;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track
    paint.color = trackColor;
    canvas.drawArc(rect, 0, 2 * 3.14159, false, paint);

    double startAngle = -3.14159 / 2;

    // 1. Paid Segment
    if (paidRatio > 0) {
      paint.color = paidColor;
      final paidSweep = 2 * 3.14159 * paidRatio;
      canvas.drawArc(rect, startAngle, paidSweep, false, paint);
      startAngle += paidSweep;
    }

    // 2. Pending Segment
    if (pendingRatio > 0) {
      paint.color = pendingColor;
      final pendingSweep = 2 * 3.14159 * pendingRatio;
      canvas.drawArc(rect, startAngle, pendingSweep, false, paint);
      startAngle += pendingSweep;
    }

    // 3. Overdue Segment
    if (overdueRatio > 0) {
      paint.color = overdueColor;
      final overdueSweep = 2 * 3.14159 * overdueRatio;
      canvas.drawArc(rect, startAngle, overdueSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
