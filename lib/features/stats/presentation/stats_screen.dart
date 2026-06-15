import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_assistant/core/theme/app_theme.dart';
import 'package:personal_assistant/features/stats/domain/stats_provider.dart';

// ======================== Line Chart Painter ========================

class CaptureTrendPainter extends CustomPainter {
  final Map<String, int> data;
  final Color lineColor;
  final Color dotColor;
  final Color textColor;

  CaptureTrendPainter({
    required this.data,
    required this.lineColor,
    required this.dotColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final entries = data.entries.toList();
    final maxVal = entries
        .fold<int>(0, (m, e) => e.value > m ? e.value : m)
        .toDouble();
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    final paddingLeft = 40.0;
    final paddingRight = 16.0;
    final paddingTop = 24.0;
    final paddingBottom = 24.0;
    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    final stepX = chartWidth / math.max(entries.length - 1, 1);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = textColor.withOpacity(0.15)
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 3; i++) {
      final y = paddingTop + chartHeight * (1 - i / 3);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
    }

    // Build points
    final points = <Offset>[];
    for (var i = 0; i < entries.length; i++) {
      final x = paddingLeft + i * stepX;
      final ratio = entries[i].value / effectiveMax;
      final y = paddingTop + chartHeight * (1 - ratio);
      points.add(Offset(x, y));
    }

    // Draw filled area
    if (points.length >= 2) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, paddingTop + chartHeight);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
      fillPath.close();
      canvas.drawPath(
        fillPath,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.2),
                  lineColor.withOpacity(0.0),
                ],
              ).createShader(
                Rect.fromLTRB(
                  0,
                  paddingTop,
                  size.width,
                  paddingTop + chartHeight,
                ),
              ),
      );
    }

    // Draw line
    if (points.length >= 2) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final prev = points[i - 1];
        final curr = points[i];
        final controlX = (prev.dx + curr.dx) / 2;
        path.cubicTo(controlX, prev.dy, controlX, curr.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw dots & value labels
    for (var i = 0; i < points.length; i++) {
      final p = points[i];

      // Dot
      canvas.drawCircle(p, 4.5, Paint()..color = dotColor);
      canvas.drawCircle(
        p,
        4.5,
        Paint()
          ..color = lineColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Value label
      final valueText = '${entries[i].value}';
      final tp = TextPainter(
        text: TextSpan(
          text: valueText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: lineColor,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height - 6));

      // Date label
      final date = DateTime.parse(entries[i].key);
      final label = DateFormat('M/d').format(date);
      final lp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 10, color: textColor),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      lp.layout();
      lp.paint(
        canvas,
        Offset(p.dx - lp.width / 2, paddingTop + chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CaptureTrendPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.lineColor != lineColor;
}

// ======================== Donut Chart Painter ========================

class DonutChartPainter extends CustomPainter {
  final Map<String, int> data;
  final List<Color> colors;
  final Color textColor;
  final Color centerTextColor;

  DonutChartPainter({
    required this.data,
    required this.colors,
    required this.textColor,
    required this.centerTextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.values.fold<int>(0, (s, v) => s + v);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final innerRadius = radius * 0.58;

    final entries = data.entries.toList();
    double startAngle = -math.pi / 2;

    for (var i = 0; i < entries.length; i++) {
      final sweepAngle = (entries[i].value / total) * 2 * math.pi;
      final color = colors[i % colors.length];

      // Arc
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final arcPath = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
        );

      // Inner cutout
      arcPath.addArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
      );

      canvas.drawPath(arcPath, arcPaint);

      // Percentage label
      final midAngle = startAngle + sweepAngle / 2;
      final labelRadius = radius * 0.82;
      final labelX = center.dx + labelRadius * math.cos(midAngle);
      final labelY = center.dy + labelRadius * math.sin(midAngle);
      final pct = (entries[i].value / total * 100).round();

      if (pct >= 5) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$pct%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.white,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(labelX - tp.width / 2, labelY - tp.height / 2));
      }

      startAngle += sweepAngle;
    }

    // Center total
    final totalTp = TextPainter(
      text: TextSpan(
        text: '$total',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: centerTextColor,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    totalTp.layout();
    totalTp.paint(
      canvas,
      Offset(center.dx - totalTp.width / 2, center.dy - totalTp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

// ======================== Bar Chart Painter ========================

class FocusBarChartPainter extends CustomPainter {
  final Map<String, int> data;
  final Color barColor;
  final Color textColor;

  FocusBarChartPainter({
    required this.data,
    required this.barColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final entries = data.entries.toList();
    final maxVal = entries
        .fold<int>(0, (m, e) => e.value > m ? e.value : m)
        .toDouble();
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    final paddingLeft = 36.0;
    final paddingRight = 8.0;
    final paddingTop = 24.0;
    final paddingBottom = 24.0;
    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    final barCount = entries.length;
    final barWidth = chartWidth / barCount * 0.6;
    final gap = chartWidth / barCount;

    // Grid lines
    final gridPaint = Paint()
      ..color = textColor.withOpacity(0.15)
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 3; i++) {
      final y = paddingTop + chartHeight * (1 - i / 3);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );
    }

    for (var i = 0; i < entries.length; i++) {
      final x = paddingLeft + i * gap + (gap - barWidth) / 2;
      final ratio = entries[i].value / effectiveMax;
      final barH = chartHeight * ratio;
      final y = paddingTop + chartHeight - barH;

      // Bar with rounded top
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barH),
        const Radius.circular(3),
      );
      canvas.drawRRect(barRect, Paint()..color = barColor);

      // Value label
      final valueText = '${entries[i].value}';
      final tp = TextPainter(
        text: TextSpan(
          text: valueText,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: barColor,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(x + barWidth / 2 - tp.width / 2, y - tp.height - 2),
      );

      // Date label
      final date = DateTime.parse(entries[i].key);
      final label = DateFormat('M/d').format(date);
      final lp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(fontSize: 10, color: textColor),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      lp.layout();
      lp.paint(
        canvas,
        Offset(x + barWidth / 2 - lp.width / 2, paddingTop + chartHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant FocusBarChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

// ======================== Stats Screen ========================

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final textColor = isDark
        ? CupertinoColors.secondaryLabel
        : CupertinoColors.systemGrey;
    final centerTextColor = isDark
        ? CupertinoColors.label
        : CupertinoColors.label;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('统计')),
      child: SafeArea(
        child: statsAsync.when(
          data: (stats) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCaptureTrendChart(stats.dailyCaptures, textColor),
              const SizedBox(height: 16),
              _buildFocusStats(
                stats.totalFocusSessions,
                stats.totalFocusMinutes,
              ),
              const SizedBox(height: 16),
              _buildFocusBarChart(stats.dailyFocusMinutes, textColor),
              const SizedBox(height: 16),
              if (stats.categoryDistribution.isNotEmpty) ...[
                _buildDonutChart(
                  stats.categoryDistribution,
                  textColor,
                  centerTextColor,
                ),
                const SizedBox(height: 16),
              ],
              _buildProjectOverview(stats.projects),
            ],
          ),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (_, __) => const Center(
            child: Text(
              '加载失败',
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureTrendChart(Map<String, int> data, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本周捕捉趋势',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: CaptureTrendPainter(
                data: data,
                lineColor: AppColors.primary,
                dotColor: AppColors.primary,
                textColor: textColor,
              ),
              size: const Size(double.infinity, 180),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusBarChart(Map<String, int> data, Color textColor) {
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '本周专注分钟',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                '合计 $total min',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: FocusBarChartPainter(
                data: data,
                barColor: CupertinoColors.systemOrange,
                textColor: textColor,
              ),
              size: const Size(double.infinity, 160),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(
    Map<String, int> dist,
    Color textColor,
    Color centerTextColor,
  ) {
    const tagColors = [
      AppColors.primary,
      CupertinoColors.systemOrange,
      Color(0xFF9B59B6),
      CupertinoColors.activeGreen,
      CupertinoColors.systemYellow,
      CupertinoColors.destructiveRed,
      Color(0xFF1ABC9C),
      CupertinoColors.systemGrey,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '标签分布',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CustomPaint(
                  painter: DonutChartPainter(
                    data: dist,
                    colors: tagColors,
                    textColor: textColor,
                    centerTextColor: centerTextColor,
                  ),
                  size: const Size(140, 140),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: dist.entries.toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final e = entry.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: tagColors[idx % tagColors.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${e.key} ${e.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusStats(int sessions, int minutes) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本周专注统计',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: CupertinoIcons.timer,
                  value: '$sessions',
                  label: '专注次数',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: CupertinoIcons.clock,
                  value: '$minutes',
                  label: '总时长（分钟）',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectOverview(List projects) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '项目进度总览',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (projects.isEmpty)
            const Text(
              '暂无项目',
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            )
          else
            ...projects.map((p) {
              final pct = (p.progress * 100).round();
              final isDone = p.status == 'completed';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: CupertinoColors.label,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          isDone ? '完成' : '$pct%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? CupertinoColors.activeGreen
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            Expanded(
                              flex: pct.clamp(0, 100).toInt(),
                              child: Container(
                                color: isDone
                                    ? CupertinoColors.activeGreen
                                    : AppColors.primary,
                              ),
                            ),
                            Expanded(
                              flex: (100 - pct).clamp(0, 100).toInt(),
                              child: Container(
                                color: CupertinoColors.systemGrey4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}
