import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/omnya_colors.dart';
import '../../../core/theme/omnya_typography.dart';
import '../../../core/widgets/liquid_glass_container.dart';
import '../../../data/repositories/protocol_repository.dart';
import '../../../domain/outcome_correlator.dart';
import '../../core/omnya_header.dart';
import 'social_story_export_modal.dart';

class ProgressView extends StatefulWidget {
  const ProgressView({super.key});

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  double _sliderPosition = 0.5; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ProtocolRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final correlation = OutcomeCorrelator.generateProgressCorrelation(
      compounds: repo.compounds,
      totalDosesLogged: repo.doseLogs.length,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                OmnyaHeader(
                  title: 'Progress',
                  subtitle: 'Outcomes & reads',
                  trailing: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF282523) : OmnyaColors.cream,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF3E3935) : OmnyaColors.taupe.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        showDialog(
                          context: context,
                          builder: (_) => SocialStoryExportModal(isPro: repo.isPro),
                        );
                      },
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedShare01,
                        color: OmnyaColors.plum,
                        size: 20,
                      ),
                      tooltip: 'Export progress story',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 1. Before/After Photo Slider (Spec Page 2: Jun 2 vs Sep 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Jun 2', style: OmnyaTypography.tag(color: OmnyaColors.taupeDark)),
                          Text('Sep 1', style: OmnyaTypography.tag(color: OmnyaColors.taupeDark)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            const height = 240.0;

                            return GestureDetector(
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  _sliderPosition =
                                      (details.localPosition.dx / width).clamp(0.05, 0.95);
                                });
                              },
                              child: Stack(
                                children: [
                                  // "After" Layer (Right side - Sep 1, glow tone)
                                  SizedBox(
                                    width: width,
                                    height: height,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          'https://picsum.photos/seed/glow_week12_skin/800/500',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color: isDark ? const Color(0xFF382A24) : OmnyaColors.sandMuted,
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.black.withValues(alpha: 0.1),
                                                Colors.black.withValues(alpha: 0.7),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 14,
                                          right: 16,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const HugeIcon(
                                                icon: HugeIcons.strokeRoundedSparkles,
                                                color: OmnyaColors.cream,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Week 12 · Radiant tone',
                                                style: OmnyaTypography.bodyMedium(color: OmnyaColors.cream),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // "Before" Layer (Left side - Jun 2)
                                  ClipRect(
                                    clipper: _SliderClipper(_sliderPosition),
                                    child: SizedBox(
                                      width: width,
                                      height: height,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            'https://picsum.photos/seed/baseline_day1_skin/800/500',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              color: isDark ? const Color(0xFF262321) : OmnyaColors.sand,
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.1),
                                                  Colors.black.withValues(alpha: 0.7),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 14,
                                            left: 16,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const HugeIcon(
                                                  icon: HugeIcons.strokeRoundedUserCircle,
                                                  color: OmnyaColors.cream,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Day 1 · Baseline',
                                                  style: OmnyaTypography.bodyMedium(color: OmnyaColors.cream),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Draggable Divider Handle
                                  Positioned(
                                    left: width * _sliderPosition - 1.5,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 3,
                                      color: OmnyaColors.cream,
                                    ),
                                  ),
                                  Positioned(
                                    left: width * _sliderPosition - 18,
                                    top: height / 2 - 18,
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: OmnyaColors.cream,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: HugeIcon(
                                          icon: HugeIcons.strokeRoundedChevronsLeftRight,
                                          color: OmnyaColors.charcoal,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Weight with Cycle Band (Spec Page 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LiquidGlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Weight, with cycle band',
                                style: OmnyaTypography.label(
                                  color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: OmnyaColors.plumSoft.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Luteal phase',
                                style: OmnyaTypography.tag(color: OmnyaColors.plumSoft),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Water weight auto-flagged · safe to ignore',
                          style: OmnyaTypography.bodySmall(color: OmnyaColors.taupeDark),
                        ),
                        const SizedBox(height: 18),
                        
                        // Line Chart
                        SizedBox(
                          height: 140,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 6,
                              minY: 135,
                              maxY: 148,
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) => OmnyaColors.plumDeep,
                                  tooltipBorderRadius: BorderRadius.circular(12),
                                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  tooltipBorder: const BorderSide(color: Color(0x40FFFFFF), width: 1),
                                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                    return touchedSpots.map((barSpot) {
                                      final isLuteal = barSpot.x >= 3.5 && barSpot.x <= 5.5;
                                      return LineTooltipItem(
                                        '${barSpot.y.toStringAsFixed(1)} lb\n',
                                        const TextStyle(
                                          color: Color(0xFFFDFBF7),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          fontFamily: 'InstrumentSans',
                                        ),
                                        children: [
                                          TextSpan(
                                            text: isLuteal ? 'Luteal (water retention)' : 'Adherent',
                                            style: TextStyle(
                                              color: isLuteal ? const Color(0xFFE2C9DD) : const Color(0xFFD4AF37),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              // Luteal Phase Band Highlight
                              rangeAnnotations: RangeAnnotations(
                                verticalRangeAnnotations: [
                                  VerticalRangeAnnotation(
                                    x1: 3.5,
                                    x2: 5.5,
                                    color: OmnyaColors.plumSoft.withValues(alpha: 0.08),
                                  ),
                                ],
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: const [
                                    FlSpot(0, 145.5),
                                    FlSpot(1, 144.2),
                                    FlSpot(2, 143.0),
                                    FlSpot(3, 141.8),
                                    FlSpot(4, 143.8), // Temporary water weight blip in luteal
                                    FlSpot(5, 142.0),
                                    FlSpot(6, 140.2),
                                  ],
                                  isCurved: true,
                                  curveSmoothness: 0.35,
                                  color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                                  barWidth: 2.5,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: OmnyaColors.plum.withValues(alpha: 0.05),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF282523) : OmnyaColors.sandMuted.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF38332E) : OmnyaColors.taupe.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Days 15–28 fluid retention (+1.5 to 3 lbs) is temporary hormone fluctuation, not tissue mass.',
                            style: OmnyaTypography.bodySmall(
                              color: isDark ? OmnyaColors.taupe : OmnyaColors.charcoalMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Plain English Correlation (Spec Page 2: +14% skin brightness, 3 weeks)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LiquidGlassContainer(
                    borderRadius: 28,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          correlation.headline,
                          style: OmnyaTypography.tag(color: OmnyaColors.taupeDark),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              correlation.metricDelta ?? '+14%',
                              style: OmnyaTypography.statNumber(
                                color: isDark ? OmnyaColors.plumSoft : OmnyaColors.plum,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                correlation.body,
                                style: OmnyaTypography.bodyLarge(
                                  color: isDark ? OmnyaColors.cream : OmnyaColors.charcoal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderClipper extends CustomClipper<Rect> {
  final double position;
  _SliderClipper(this.position);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * position, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) => oldClipper.position != position;
}
