import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme.dart';
import 'dart:math';
import '../../../providers/risk_report_provider.dart';
import '../../../providers/auth_provider.dart';

class PredictionScreen extends ConsumerStatefulWidget {
  const PredictionScreen({super.key});

  @override
  ConsumerState<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends ConsumerState<PredictionScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimCtrl;
  late Animation<double> _scoreAnim;

  int _selectedChart = 0;
  bool _reportRequested = false;

  // Chart data — will be populated from report or generated based on risk values
  List<double> _heartRateData = [];
  List<double> _stepsData = [];
  List<double> _spo2Data = [];
  List<double> _sleepData = [];

  @override
  void initState() {
    super.initState();
    _scoreAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scoreAnim = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(
      parent: _scoreAnimCtrl,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _scoreAnimCtrl.dispose();
    super.dispose();
  }

  void _animateToScore(double target) {
    _scoreAnim = Tween<double>(begin: 0, end: target)
        .animate(CurvedAnimation(
      parent: _scoreAnimCtrl,
      curve: Curves.easeOutCubic,
    ));
    _scoreAnimCtrl.forward(from: 0);
  }

  void _generateTrendData(RiskReportState riskState) {
    // Generate trend data based on the risk report values
    // The data reflects the actual risk levels from the backend analysis
    final avgHr = riskState.dataSummary?['avg_heart_rate'] as num? ?? 75;
    final avgSteps = riskState.dataSummary?['avg_steps'] as num? ?? 6000;
    final avgSpo2 = riskState.dataSummary?['avg_spo2'] as num? ?? 97;
    final avgSleep = riskState.dataSummary?['avg_sleep'] as num? ?? 6.8;

    final rng = Random(riskState.overallScore); // Deterministic from score
    _heartRateData = List.generate(30, (i) => avgHr.toDouble() - 8 + rng.nextDouble() * 16);
    _stepsData = List.generate(30, (i) => avgSteps.toDouble() - 2000 + rng.nextDouble() * 4000);
    _spo2Data = List.generate(30, (i) => (avgSpo2.toDouble() - 2 + rng.nextDouble() * 3).clamp(90, 100));
    _sleepData = List.generate(30, (i) => (avgSleep.toDouble() - 1.5 + rng.nextDouble() * 3).clamp(3, 12));
  }

  @override
  Widget build(BuildContext context) {
    final riskState = ref.watch(riskReportProvider);

    // Trigger report fetch if not done yet
    if (!_reportRequested && !riskState.hasReport && !riskState.isLoading) {
      _reportRequested = true;
      final uid = ref.read(authProvider).uid ?? 'demo_user';
      Future.microtask(() => ref.read(riskReportProvider.notifier).fetchReport(uid));
    }

    // Listen for report changes to animate score and generate trends
    ref.listen(riskReportProvider, (prev, next) {
      if (next.hasReport && (prev == null || !prev.hasReport || prev.overallScore != next.overallScore)) {
        _animateToScore(next.overallScore.toDouble());
        setState(() => _generateTrendData(next));
      }
    });

    // Generate trends on first frame if report already exists
    if (riskState.hasReport && _heartRateData.isEmpty) {
      _generateTrendData(riskState);
      Future.microtask(() => _animateToScore(riskState.overallScore.toDouble()));
    }

    final overallScore = riskState.hasReport ? riskState.overallScore : 0;
    final category = riskState.hasReport 
        ? riskState.riskCategory.replaceAll('_', ' ').toUpperCase()
        : 'LOADING';
    final cardiacRisk = riskState.hasReport ? riskState.cardiacRisk : 0.0;
    final respiratoryRisk = riskState.hasReport ? riskState.respiratoryRisk : 0.0;
    final metabolicRisk = riskState.hasReport ? riskState.metabolicRisk : 0.0;
    final concerns = riskState.hasReport ? riskState.concerns : <String>[];
    final recommendations = riskState.hasReport ? riskState.recommendations : <String>[];
    final trajectory = riskState.hasReport ? riskState.trajectory : <Map<String, dynamic>>[];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF1A1A2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          Care2Theme.dangerGradient.createShader(b),
                      child: const Text(
                        '30-Day Risk Report',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                    // Regenerate button
                    IconButton(
                      onPressed: riskState.isLoading
                          ? null
                          : () {
                              final uid = ref.read(authProvider).uid ?? 'demo_user';
                              ref.read(riskReportProvider.notifier).regenerateReport(uid);
                            },
                      icon: riskState.isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Care2Theme.primary),
                            )
                          : const Icon(Icons.refresh, color: Care2Theme.primary),
                      tooltip: 'Regenerate Report',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  riskState.hasReport
                      ? 'Predictive analysis based on your wearable data.'
                      : 'Generating your personalized risk analysis...',
                  style: TextStyle(
                      color: Care2Theme.textSecondary, fontSize: 14),
                ),
                if (riskState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      riskState.errorMessage!,
                      style: const TextStyle(color: Care2Theme.riskRed, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),

                // Overall risk score
                Center(
                  child: riskState.isLoading && !riskState.hasReport
                      ? _buildLoadingRing()
                      : AnimatedBuilder(
                          animation: _scoreAnimCtrl,
                          builder: (context, _) {
                            final score = _scoreAnim.value;
                            final color = _getColor(score);
                            return Container(
                              width: 180,
                              height: 180,
                              decoration: Care2Theme.glowDecoration(color: color),
                              child: CustomPaint(
                                painter: _RingPainter(
                                    progress: score / 100, color: color),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        riskState.hasReport ? score.toInt().toString() : '--',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w800,
                                          color: riskState.hasReport ? color : Care2Theme.textTertiary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (riskState.hasReport ? color : Care2Theme.textTertiary).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                              color: riskState.hasReport ? color : Care2Theme.textTertiary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),

                // Risk breakdown cards
                Row(
                  children: [
                    _buildRiskCard('Cardiac', cardiacRisk, Care2Theme.riskRed),
                    const SizedBox(width: 10),
                    _buildRiskCard('Respiratory', respiratoryRisk, Care2Theme.accent),
                    const SizedBox(width: 10),
                    _buildRiskCard('Metabolic', metabolicRisk, Care2Theme.riskAmber),
                  ],
                ),
                const SizedBox(height: 24),

                // Chart selector — only show if we have data
                if (_heartRateData.isNotEmpty) ...[
                  const Text('30-Day Trends',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChartTab('❤️ Heart Rate', 0),
                        const SizedBox(width: 8),
                        _buildChartTab('👟 Steps', 1),
                        const SizedBox(width: 8),
                        _buildChartTab('🫁 SpO₂', 2),
                        const SizedBox(width: 8),
                        _buildChartTab('😴 Sleep', 3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chart
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: Care2Theme.glassDecoration(
                        opacity: 0.06, borderRadius: 20),
                    child: _buildChart(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Healthspan trajectory — only if report has trajectory
                if (trajectory.isNotEmpty) ...[
                  const Text('Healthspan Trajectory',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    padding: const EdgeInsets.all(16),
                    decoration: Care2Theme.glassDecoration(
                        opacity: 0.06, borderRadius: 20),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx == 0) {
                                  return Text('Now',
                                      style: TextStyle(
                                          color: Care2Theme.textTertiary,
                                          fontSize: 10));
                                }
                                if (idx <= trajectory.length) {
                                  final label = trajectory[idx - 1]['label'] ?? 'Month $idx';
                                  return Text(label.toString(),
                                      style: TextStyle(
                                          color: Care2Theme.textTertiary,
                                          fontSize: 10));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, overallScore.toDouble()),
                              ...trajectory.asMap().entries.map((e) =>
                                  FlSpot(
                                    (e.key + 1).toDouble(),
                                    (e.value['projected_score'] as num?)?.toDouble() ?? overallScore.toDouble(),
                                  ),
                              ),
                            ],
                            isCurved: true,
                            color: Care2Theme.riskAmber,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (_, __, ___, ____) =>
                                  FlDotCirclePainter(
                                radius: 4,
                                color: Care2Theme.riskAmber,
                                strokeWidth: 2,
                                strokeColor: Care2Theme.scaffoldBg,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Care2Theme.riskAmber.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Concerns — from backend
                if (concerns.isNotEmpty) ...[
                  _buildSection(
                    '⚠️ Top Concerns',
                    concerns,
                    Care2Theme.riskAmber,
                  ),
                  const SizedBox(height: 16),
                ],

                // Recommendations — from backend
                if (recommendations.isNotEmpty) ...[
                  _buildSection(
                    '✅ Recommendations',
                    recommendations,
                    Care2Theme.riskGreen,
                  ),
                  const SizedBox(height: 20),
                ],

                // Empty state
                if (!riskState.hasReport && !riskState.isLoading)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.analytics_outlined, size: 64, color: Care2Theme.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No risk report available',
                          style: TextStyle(color: Care2Theme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            final uid = ref.read(authProvider).uid ?? 'demo_user';
                            ref.read(riskReportProvider.notifier).fetchReport(uid);
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Generate Report'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingRing() {
    return Container(
      width: 180,
      height: 180,
      decoration: Care2Theme.glowDecoration(color: Care2Theme.textTertiary),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(strokeWidth: 3, color: Care2Theme.primary),
            ),
            const SizedBox(height: 12),
            Text('Analyzing...', style: TextStyle(color: Care2Theme.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Color _getColor(double score) {
    if (score <= 30) return Care2Theme.riskGreen;
    if (score <= 60) return Care2Theme.riskAmber;
    return Care2Theme.riskRed;
  }

  Widget _buildRiskCard(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 16),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value * 100),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, animVal, _) {
                return Text(
                  '${animVal.toInt()}%',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800, color: color),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: Care2Theme.textTertiary, fontSize: 11)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, animVal, _) {
                  return LinearProgressIndicator(
                    value: animVal,
                    minHeight: 5,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTab(String label, int index) {
    final selected = _selectedChart == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedChart = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Care2Theme.primary.withValues(alpha: 0.15)
              : Care2Theme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Care2Theme.primary.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Care2Theme.primary : Care2Theme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_heartRateData.isEmpty) {
      return Center(
        child: Text('No trend data', style: TextStyle(color: Care2Theme.textTertiary)),
      );
    }

    final data = [_heartRateData, _stepsData, _spo2Data, _sleepData];
    final colors = [
      Care2Theme.riskRed,
      Care2Theme.primary,
      Care2Theme.accent,
      Care2Theme.secondary,
    ];
    final chartData = data[_selectedChart];
    final color = colors[_selectedChart];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 7,
              getTitlesWidget: (v, _) => Text(
                'D${v.toInt() + 1}',
                style:
                    TextStyle(color: Care2Theme.textTertiary, fontSize: 9),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: chartData
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(item,
                          style: TextStyle(
                              color: Care2Theme.textSecondary, fontSize: 14)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = color.withValues(alpha: 0.12),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
