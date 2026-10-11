import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tashil_real_estate/core/design_system/buttons/tashil_button_group.dart';
import 'package:tashil_real_estate/core/localization/app_localizations.dart';
import 'package:tashil_real_estate/core/localization/locale_controller.dart';
import 'package:tashil_real_estate/core/services/ai_translation_service.dart';
import 'package:tashil_real_estate/features/market_index/models/market_index_model.dart';
import 'package:tashil_real_estate/features/market_index/services/ai_market_index_service.dart';

class MarketHistoricalChart extends StatefulWidget {
  final List<MarketHistoricalPoint> initialPoints;
  final String countryCode;
  final String lang;
  final bool isMobile;

  const MarketHistoricalChart({
    super.key,
    required this.initialPoints,
    required this.countryCode,
    required this.lang,
    required this.isMobile,
  });

  @override
  State<MarketHistoricalChart> createState() => _MarketHistoricalChartState();
}

class _MarketHistoricalChartState extends State<MarketHistoricalChart> {
  String _selectedTimeframe = '6M'; // '6M', '12M', 'BULLISH', 'SEASONAL'
  String _chartType = 'spline'; // 'spline' or 'bars'
  int? _hoveredIndex;

  List<MarketHistoricalPoint> get _currentPoints {
    return AiMarketIndexService.getHistoricalTrendFor(
      countryCode: widget.countryCode,
      timeframe: _selectedTimeframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final points = _currentPoints;
    final isRTL = LocaleController.isRTL;

    if (points.isEmpty) return const SizedBox.shrink();

    // Key stats
    final maxPt = points.reduce((a, b) => a.indexPoints > b.indexPoints ? a : b);
    final minPt = points.reduce((a, b) => a.indexPoints < b.indexPoints ? a : b);
    final currentPt = points.last;
    final firstPt = points.first;
    final netGrowth = firstPt.indexPoints > 0
        ? (((currentPt.indexPoints - firstPt.indexPoints) / firstPt.indexPoints) * 100)
        : 0.0;

    // Determine active highlighted point
    final activeIndex = _hoveredIndex != null && _hoveredIndex! < points.length
        ? _hoveredIndex!
        : points.length - 1;
    final activePt = points[activeIndex];
    final activeMonthName = AiTranslationService.getLocalizedText(activePt.localizedMonth, widget.lang);

    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Top Header with Title, Badge, and Chart Switcher
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.show_chart_rounded, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.tr('historicalTrajectoryTitle'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: widget.isMobile ? 13 : 15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          loc.tr('historicalTrajectorySubtitle'),
                          style: TextStyle(
                            fontSize: widget.isMobile ? 10 : 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Chart View Mode Switcher
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science_rounded, size: 13, color: colorScheme.onSecondaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          loc.tr('testDataBadge'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TashilConnectedButtonGroup<String>(
                    height: 34,
                    selectedValue: _chartType,
                    onSelectionChanged: (val) {
                      setState(() => _chartType = val);
                    },
                    segments: [
                      TashilConnectedButtonSegment(
                        value: 'spline',
                        icon: Icons.timeline_rounded,
                        label: loc.tr('chartSpline'),
                      ),
                      TashilConnectedButtonSegment(
                        value: 'bars',
                        icon: Icons.bar_chart_rounded,
                        label: loc.tr('chartBars'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section 2: Timeframe & Scenario Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  loc.tr('selectTimeframeOrScenario'),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('6M', loc.tr('timeframe6Months'), Icons.calendar_today_rounded, colorScheme),
                const SizedBox(width: 6),
                _buildFilterChip('12M', loc.tr('timeframe12Months'), Icons.date_range_rounded, colorScheme),
                const SizedBox(width: 6),
                _buildFilterChip('BULLISH', loc.tr('testScenarioBullish'), Icons.trending_up_rounded, colorScheme),
                const SizedBox(width: 6),
                _buildFilterChip('SEASONAL', loc.tr('testScenarioSeasonal'), Icons.waves_rounded, colorScheme),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Summary Stat KPI Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildKpiPill(
                label: loc.tr('currentLevel'),
                value: '${currentPt.indexPoints} ${loc.tr('points')}',
                badge: '+${currentPt.momGrowth ?? 3.5}%',
                icon: Icons.insights_rounded,
                color: colorScheme.primary,
                colorScheme: colorScheme,
              ),
              _buildKpiPill(
                label: loc.tr('netGrowth'),
                value: '${netGrowth >= 0 ? '+' : ''}${netGrowth.toStringAsFixed(1)}%',
                icon: Icons.auto_graph_rounded,
                color: netGrowth >= 0 ? Colors.green.shade700 : colorScheme.error,
                colorScheme: colorScheme,
              ),
              _buildKpiPill(
                label: loc.tr('highestPoint'),
                value: '${maxPt.indexPoints} (${AiTranslationService.getLocalizedText(maxPt.localizedMonth, widget.lang)})',
                icon: Icons.north_east_rounded,
                color: colorScheme.secondary,
                colorScheme: colorScheme,
              ),
              _buildKpiPill(
                label: loc.tr('lowestPoint'),
                value: '${minPt.indexPoints} (${AiTranslationService.getLocalizedText(minPt.localizedMonth, widget.lang)})',
                icon: Icons.south_west_rounded,
                color: colorScheme.tertiary,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 4: Dynamic Interactive Inspector Tooltip Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '$activeMonthName ${activePt.year ?? ''}:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: colorScheme.onSurface),
                    ),
                    Text(
                      '${activePt.indexPoints} ${loc.tr('points')}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary),
                    ),
                  ],
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${activePt.momGrowth != null && activePt.momGrowth! > 0 ? '+' : ''}${activePt.momGrowth ?? 0.0}% MoM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Text(
                      '${activePt.demandPercentage.toInt()}% ${loc.tr('demandScore')}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 5: Chart Visualization Canvas (Spline Area or Bar Chart)
          SizedBox(
            height: widget.isMobile ? 220 : 250,
            width: double.infinity,
            child: _chartType == 'spline'
                ? _buildSplineChart(points, colorScheme, isRTL)
                : _buildBarChart(points, colorScheme, isRTL),
          ),
          const SizedBox(height: 12),

          // Section 6: Bottom Navigation / Instructions & Timeline Hint
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text(
                loc.tr('tapToInspect'),
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AiTranslationService.getLocalizedText(firstPt.localizedMonth, widget.lang)} ${firstPt.year ?? ''}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                  ),
                  Icon(
                    isRTL ? Icons.arrow_left_rounded : Icons.arrow_right_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  Text(
                    '${AiTranslationService.getLocalizedText(currentPt.localizedMonth, widget.lang)} ${currentPt.year ?? ''}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, ColorScheme colorScheme) {
    final isSelected = _selectedTimeframe == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTimeframe = value;
          _hoveredIndex = null;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiPill({
    required String label,
    required String value,
    String? badge,
    required IconData icon,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 2,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                '$label: ',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSplineChart(List<MarketHistoricalPoint> points, ColorScheme colorScheme, bool isRTL) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (event) {
            final localX = event.localPosition.dx;
            final count = points.length;
            final step = constraints.maxWidth / count;
            final idx = (localX / step).floor().clamp(0, count - 1);
            final pointIndex = isRTL ? (count - 1 - idx) : idx;
            if (_hoveredIndex != pointIndex) {
              setState(() => _hoveredIndex = pointIndex);
            }
          },
          onExit: (_) {
            setState(() => _hoveredIndex = null);
          },
          child: GestureDetector(
            onTapDown: (details) {
              final localX = details.localPosition.dx;
              final count = points.length;
              final step = constraints.maxWidth / count;
              final idx = (localX / step).floor().clamp(0, count - 1);
              final pointIndex = isRTL ? (count - 1 - idx) : idx;
              setState(() => _hoveredIndex = pointIndex);
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _SplineChartPainter(
                points: points,
                colorScheme: colorScheme,
                isRTL: isRTL,
                lang: widget.lang,
                activeIndex: _hoveredIndex ?? points.length - 1,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBarChart(List<MarketHistoricalPoint> points, ColorScheme colorScheme, bool isRTL) {
    final maxPts = points.map((e) => e.indexPoints).fold<int>(0, max);
    final minPts = points.map((e) => e.indexPoints).fold<int>(999999, min);
    // Baseline slightly below minimum point to highlight real fluctuation
    final baseline = max(minPts - 80, 0);

    // Order points visually according to RTL / LTR
    final visualPoints = isRTL ? points.reversed.toList() : points;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: visualPoints.map((pt) {
        final originalIndex = points.indexOf(pt);
        final isSelected = (_hoveredIndex ?? points.length - 1) == originalIndex;
        final monthName = AiTranslationService.getLocalizedText(pt.localizedMonth, widget.lang);
        final heightRatio = ((pt.indexPoints - baseline) / (maxPts - baseline + 40)).clamp(0.15, 1.0);
        final barHeight = heightRatio * (widget.isMobile ? 130 : 155);

        return Expanded(
          child: InkWell(
            onTap: () {
              setState(() => _hoveredIndex = originalIndex);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Point Value Pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${pt.indexPoints}',
                      style: TextStyle(
                        fontSize: widget.isMobile ? 8 : 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Fixed-width Proportional Bar
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: widget.isMobile ? (points.length > 8 ? 12.0 : 18.0) : (points.length > 8 ? 18.0 : 28.0),
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSelected
                              ? [
                                  colorScheme.primary,
                                  Color.alphaBlend(colorScheme.primary.withValues(alpha: 0.8), Colors.black),
                                ]
                              : [
                                  colorScheme.primary.withValues(alpha: 0.7),
                                  colorScheme.primary.withValues(alpha: 0.4),
                                ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Month Label
                  Text(
                    monthName,
                    style: TextStyle(
                      fontSize: widget.isMobile ? 9 : 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SplineChartPainter extends CustomPainter {
  final List<MarketHistoricalPoint> points;
  final ColorScheme colorScheme;
  final bool isRTL;
  final String lang;
  final int activeIndex;

  _SplineChartPainter({
    required this.points,
    required this.colorScheme,
    required this.isRTL,
    required this.lang,
    required this.activeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final count = points.length;
    final maxPts = points.map((e) => e.indexPoints).fold<int>(0, max);
    final minPts = points.map((e) => e.indexPoints).fold<int>(999999, min);

    // Add safe headroom and footroom for curve aesthetics
    final safeMin = max(minPts - 100, 0);
    final safeMax = maxPts + 100;
    final range = max(safeMax - safeMin, 200);

    const bottomPadding = 30.0;
    const topPadding = 20.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final chartWidth = size.width;

    // Draw reference dashed grid lines
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    const gridSteps = 3;
    for (int i = 0; i <= gridSteps; i++) {
      final y = topPadding + (chartHeight / gridSteps) * i;
      final val = (safeMax - (range / gridSteps) * i).toInt();

      _drawDashedLine(canvas, Offset(0, y), Offset(chartWidth, y), gridPaint);

      // Value label
      final textSpan = TextSpan(
        text: '$val',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelX = isRTL ? chartWidth - textPainter.width - 4 : 4.0;
      textPainter.paint(canvas, Offset(labelX, y - 12));
    }

    // Compute pixel coordinates for each point
    final coordinates = <Offset>[];
    final stepX = count > 1 ? chartWidth / (count - 1) : chartWidth;

    for (int i = 0; i < count; i++) {
      final pt = points[i];
      // In RTL, the chronological order starts from right to left
      final x = isRTL ? (chartWidth - (i * stepX)) : (i * stepX);
      final normalizedY = (pt.indexPoints - safeMin) / range;
      final y = topPadding + chartHeight * (1.0 - normalizedY);
      coordinates.add(Offset(x, y));
    }

    // Sort coordinates by x for proper path drawing
    final sortedByX = List<Offset>.from(coordinates)
      ..sort((a, b) => a.dx.compareTo(b.dx));

    // Build smooth cubic bezier spline path
    final splinePath = Path();
    splinePath.moveTo(sortedByX.first.dx, sortedByX.first.dy);

    for (int i = 0; i < sortedByX.length - 1; i++) {
      final p0 = i > 0 ? sortedByX[i - 1] : sortedByX[i];
      final p1 = sortedByX[i];
      final p2 = sortedByX[i + 1];
      final p3 = i < sortedByX.length - 2 ? sortedByX[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;

      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;

      splinePath.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    // Area Fill Gradient Path
    final fillPath = Path.from(splinePath);
    fillPath.lineTo(sortedByX.last.dx, size.height - bottomPadding);
    fillPath.lineTo(sortedByX.first.dx, size.height - bottomPadding);
    fillPath.close();

    final fillGradient = LinearGradient(
      colors: [
        colorScheme.primary.withValues(alpha: 0.35),
        colorScheme.primary.withValues(alpha: 0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(0, topPadding, chartWidth, chartHeight),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke Spline Line
    final linePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(splinePath, linePaint);

    // Draw Data Point Circles and Month Labels
    for (int i = 0; i < count; i++) {
      final pt = points[i];
      final offset = coordinates[i];
      final isCurrentActive = i == activeIndex;
      final monthName = AiTranslationService.getLocalizedText(pt.localizedMonth, lang);

      if (isCurrentActive) {
        // Vertical guideline for active point
        final guidePaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.4)
          ..strokeWidth = 1.5;
        _drawDashedLine(
          canvas,
          Offset(offset.dx, topPadding),
          Offset(offset.dx, size.height - bottomPadding),
          guidePaint,
        );

        // Glowing halo aura
        final auraPaint = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, 12, auraPaint);
      }

      // Outer point circle
      final pointOuterPaint = Paint()
        ..color = isCurrentActive ? colorScheme.primary : colorScheme.surface
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, isCurrentActive ? 6.5 : 4.5, pointOuterPaint);

      // Point border ring
      final pointBorderPaint = Paint()
        ..color = colorScheme.primary
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(offset, isCurrentActive ? 6.5 : 4.5, pointBorderPaint);

      // Inner white core
      final pointCorePaint = Paint()
        ..color = isCurrentActive ? colorScheme.onPrimary : colorScheme.primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, isCurrentActive ? 2.5 : 2.0, pointCorePaint);

      // Month Label along X Axis
      final monthSpan = TextSpan(
        text: monthName,
        style: TextStyle(
          color: isCurrentActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: isCurrentActive ? FontWeight.bold : FontWeight.w500,
        ),
      );
      final monthPainter = TextPainter(
        text: monthSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      monthPainter.paint(
        canvas,
        Offset(offset.dx - (monthPainter.width / 2), size.height - bottomPadding + 8),
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final unitVector = Offset(dx / distance, dy / distance);

    double currentDistance = 0.0;
    while (currentDistance < distance) {
      final start = p1 + unitVector * currentDistance;
      final endDistance = min(currentDistance + dashWidth, distance);
      final end = p1 + unitVector * endDistance;
      canvas.drawLine(start, end, paint);
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _SplineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.isRTL != isRTL;
  }
}
