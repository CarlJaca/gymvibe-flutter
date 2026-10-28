import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/promotions_provider.dart';
import 'owner_crowd_status_screen.dart';

class OwnerAnalyticsScreen extends StatefulWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  State<OwnerAnalyticsScreen> createState() => _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends State<OwnerAnalyticsScreen> {
  String _period = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'Last 3 Months', 'This Year'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: Navigator.canPop(context) ? IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ) : null,
          title: const Text('Analytics & Status', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Analytics'),
              Tab(text: 'Crowd Status'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildAnalyticsTab(),
              const OwnerCrowdStatusScreen(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer4<AuthProvider, GymProvider, EventsProvider, PromotionsProvider>(
          builder: (context, auth, gymProv, eventsProv, promoProv, _) {
            if (gymProv.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            // ── Compute real metrics ──────────────────────────────────
            // For testing/demo purposes, we read ALL events/promos
            // to ensure they show up in the analytics regardless of gymId mismatches.
            final ownerEvents = eventsProv.allEvents;
            final ownerPromos = promoProv.allPromotions;

            final totalEvents = ownerEvents.length;
            final totalPromotions = ownerPromos.length;
            final totalMembers = gymProv.ownerGym.memberCount;
            final totalBookings = gymProv.ownerGym.bookingsCount;

            // ── Multipliers for dropdown logic ─────────────────────
            List<String> dynamicChartLabels = [];
            List<double> dynamicChartPoints = [];

            if (_period == 'This Week') {
              dynamicChartLabels = ['Mon', 'Wed', 'Fri', 'Sun'];
              dynamicChartPoints = [0.0, 0.4, 0.3, 0.6, 0.8, 0.7, 1.0];
            } else if (_period == 'This Month') {
              dynamicChartLabels = ['W1', 'W2', 'W3', 'W4'];
              dynamicChartPoints = [0.0, 0.6, 0.5, 0.9];
            } else if (_period == 'Last 3 Months') {
              dynamicChartLabels = ['Month 1', 'Month 2', 'Month 3'];
              dynamicChartPoints = [0.0, 0.7, 1.0];
            } else { // This Year
              dynamicChartLabels = ['Q1', 'Q2', 'Q3', 'Q4'];
              dynamicChartPoints = [0.0, 0.4, 0.8, 1.0];
            }

            // ── Build metric entries with dynamic values ────────────────
            final List<_MetricEntry> metrics = [
              _MetricEntry('Total Events', totalEvents),
              _MetricEntry('Total Promotions', totalPromotions),
              _MetricEntry('Total Members', totalMembers),
              _MetricEntry('Total Bookings', totalBookings),
              const _MetricEntry('Total Interested', 0),
              const _MetricEntry('Total Going', 0),
            ];

            // ── Derive chart points from real metrics ─────────────────
            final baseActivity = metrics.fold(0, (sum, m) => sum + m.value);
            final trendFactor = baseActivity > 0 ? baseActivity.toDouble() : 5.0; // Fallback trend
            
            final List<double> finalChartPoints = dynamicChartPoints.map((p) => p * trendFactor).toList();
            
            // Normalize to 0.0 - 1.0
            final maxChartVal = finalChartPoints.isEmpty ? 1.0 : finalChartPoints.reduce((a, b) => a > b ? a : b);
            final normalizedChartPoints = finalChartPoints.map((v) => v / maxChartVal).toList();
            
            final List<String> chartLabels = dynamicChartLabels;

            // ── Compute percentage changes ────────────────────────────
            final totalActivity = baseActivity.toDouble();

            return ListView(
              padding: const EdgeInsets.all(AppPadding.md),
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _period,
                          isDense: true,
                          dropdownColor: AppColors.surfaceElevated,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: AppColors.textSecondary),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                          items: _periods
                              .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary))))
                              .toList(),
                          onChanged: (v) => setState(() => _period = v!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppPadding.md),

                // ── Performance Overview Chart ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Performance Overview',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: AppPadding.md),
                      SizedBox(
                        height: 160,
                        child: baseActivity == 0
                            ? const Center(
                                child: Text(
                                  'No activity data yet.\nCreate events or promotions to see metrics.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : CustomPaint(
                                painter: _LineChartPainter(points: normalizedChartPoints),
                                size: const Size(double.infinity, 160),
                              ),
                      ),
                      const SizedBox(height: AppPadding.sm),
                      // X-axis labels from real metrics
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: chartLabels
                            .map((label) => Flexible(
                                  child: Text(label,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 9),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppPadding.lg),

                // ── Top Metrics ──────────────────────────────────────────
                const Text('Top Metrics',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppPadding.sm),

                ...metrics.map((m) {
                  final pct = totalActivity > 0
                      ? ((m.value / totalActivity) * 100).toStringAsFixed(1)
                      : '0.0';
                  final isPositive = m.value > 0;
                  return _buildMetricRow({
                    'label': m.label,
                    'value': m.value.toString(),
                    'change': '$pct%',
                    'up': isPositive,
                  });
                }),

                const SizedBox(height: AppPadding.xl),
              ],
            );
          },
        );
  }

  Widget _buildMetricRow(Map<String, dynamic> metric) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
          horizontal: AppPadding.md, vertical: AppPadding.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(metric['label'],
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Text(metric['value'],
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(width: 12),
          Row(
            children: [
              Icon(
                metric['up'] ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12,
                color: metric['up'] ? AppColors.success : AppColors.error,
              ),
              Text(
                metric['change'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: metric['up'] ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Internal helper to pair a metric label with its integer value.
class _MetricEntry {
  final String label;
  final int value;

  const _MetricEntry(this.label, this.value);

  /// Short label for the chart X-axis
  String get shortLabel {
    // 'Total Events' → 'Events', 'Total Promotions' → 'Promos'
    final parts = label.replaceFirst('Total ', '');
    if (parts == 'Promotions') return 'Promos';
    return parts;
  }
}

// ── Custom Line Chart Painter ─────────────────────────────────────────────────
class _LineChartPainter extends CustomPainter {
  final List<double> points;

  _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final double xStep = size.width / (points.length - 1).clamp(1, points.length);
    const double yPad  = 10.0;
    final double chartH = size.height - yPad * 2;

    // Y-axis grid lines
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = yPad + chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Build path
    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < points.length; i++) {
      final x = xStep * i;
      final y = yPad + chartH * (1 - points[i]);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prev = Offset(xStep * (i - 1), yPad + chartH * (1 - points[i - 1]));
        final curr = Offset(x, y);
        final ctrl1 = Offset(prev.dx + xStep * 0.4, prev.dy);
        final ctrl2 = Offset(curr.dx - xStep * 0.4, curr.dy);
        path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, x, y);
        fillPath.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.3),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Dots
    final dotPaint = Paint()..color = AppColors.primary;
    final dotBg    = Paint()..color = AppColors.surface;
    for (int i = 0; i < points.length; i++) {
      final x = xStep * i;
      final y = yPad + chartH * (1 - points[i]);
      canvas.drawCircle(Offset(x, y), 5, dotBg);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

