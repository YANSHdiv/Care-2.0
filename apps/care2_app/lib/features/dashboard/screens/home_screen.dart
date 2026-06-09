import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import 'dart:math';
import '../../../providers/health_provider.dart';
import '../../../providers/risk_report_provider.dart';
import '../../../providers/insights_provider.dart';
import '../../../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late Animation<double> _scoreAnim;

  bool _reportRequested = false;

  @override
  void initState() {
    super.initState();
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _scoreAnim = Tween<double>(begin: 0, end: 0)
        .animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  void _animateToScore(double targetScore) {
    _scoreAnim = Tween<double>(begin: 0, end: targetScore)
        .animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOutCubic,
    ));
    _scoreController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthDataProvider);
    final healthNotifier = ref.read(healthDataProvider.notifier);
    final riskState = ref.watch(riskReportProvider);
    final insights = ref.watch(insightsProvider);
    final authState = ref.watch(authProvider);

    // Trigger report fetch on first build
    if (!_reportRequested && !riskState.hasReport && !riskState.isLoading) {
      _reportRequested = true;
      final uid = authState.uid ?? 'demo_user';
      Future.microtask(() => ref.read(riskReportProvider.notifier).fetchReport(uid));
    }

    // Animate score when report arrives
    ref.listen(riskReportProvider, (prev, next) {
      if (next.hasReport && (prev == null || !prev.hasReport || prev.overallScore != next.overallScore)) {
        _animateToScore(next.overallScore.toDouble());
      }
    });

    // Determine displayed values
    final overallScore = riskState.hasReport ? riskState.overallScore : 0;
    final cardiacRisk = riskState.hasReport ? riskState.cardiacRisk : 0.0;
    final respiratoryRisk = riskState.hasReport ? riskState.respiratoryRisk : 0.0;
    final metabolicRisk = riskState.hasReport ? riskState.metabolicRisk : 0.0;

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
                // Header
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_getGreeting()}, ${authState.displayName ?? 'User'}!',
                          style: TextStyle(
                            color: Care2Theme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShaderMask(
                          shaderCallback: (b) =>
                              Care2Theme.primaryGradient.createShader(b),
                          child: const Text(
                            'Clinical Dashboard',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: Care2Theme.glassDecoration(
                          opacity: 0.08, borderRadius: 16),
                      child: const Icon(Icons.notifications_outlined,
                          color: Care2Theme.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => ref.read(authProvider.notifier).logout(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: Care2Theme.glassDecoration(
                            opacity: 0.08, borderRadius: 16),
                        child: const Icon(Icons.logout_rounded,
                            color: Care2Theme.riskRed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Health Score Ring
                Center(
                  child: riskState.isLoading
                      ? _buildLoadingScoreRing()
                      : AnimatedBuilder(
                          animation: _scoreController,
                          builder: (context, child) {
                            final score = _scoreAnim.value;
                            return Container(
                              width: 200,
                              height: 200,
                              decoration:
                                  Care2Theme.glowDecoration(color: _getScoreColor(score)),
                              child: CustomPaint(
                                painter: _RingPainter(
                                  progress: score / 100,
                                  color: _getScoreColor(score),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        riskState.hasReport ? score.toInt().toString() : '--',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w800,
                                          color: riskState.hasReport
                                              ? _getScoreColor(score)
                                              : Care2Theme.textTertiary,
                                        ),
                                      ),
                                      Text(
                                        'Health Score',
                                        style: TextStyle(
                                          color: Care2Theme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: riskState.hasReport
                                              ? _getScoreColor(score).withValues(alpha: 0.15)
                                              : Care2Theme.textTertiary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          riskState.hasReport ? _getScoreLabel(score) : 'LOADING',
                                          style: TextStyle(
                                            color: riskState.hasReport
                                                ? _getScoreColor(score)
                                                : Care2Theme.textTertiary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
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
                const SizedBox(height: 32),

                // Quick Metrics Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Device Vitals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    healthState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Care2Theme.primary),
                        )
                      : TextButton.icon(
                          onPressed: () => healthState.isConnected ? healthNotifier.disconnect() : healthNotifier.connectAndFetch(),
                          icon: Icon(healthState.isConnected ? Icons.cloud_done : Icons.cloud_sync, size: 16, color: Care2Theme.primary),
                          label: Text(healthState.isConnected ? "Synced to Fit" : "Sync Google Fit", style: const TextStyle(color: Care2Theme.primary)),
                        ),
                  ],
                ),
                if (healthState.errorMessage != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 8),
                     child: Text(healthState.errorMessage!, style: const TextStyle(color: Care2Theme.riskRed, fontSize: 12)),
                   ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildMetricCard(
                      icon: Icons.favorite,
                      label: 'Heart Rate',
                      value: healthState.isConnected
                          ? (healthState.data?.heartRate != 0 ? healthState.data!.heartRate.toString() : '--')
                          : '--',
                      unit: 'bpm',
                      color: Care2Theme.riskRed,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildMetricCard(
                      icon: Icons.air,
                      label: 'SpO₂',
                      value: healthState.isConnected
                          ? (healthState.data?.spo2 != 0 ? healthState.data!.spo2.toString() : '--')
                          : '--',
                      unit: '%',
                      color: Care2Theme.accent,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildMetricCard(
                      icon: Icons.directions_walk,
                      label: 'Steps',
                      value: healthState.isConnected
                          ? (healthState.data?.steps != 0 ? healthState.data!.steps.toString() : '--')
                          : '--',
                      unit: 'today',
                      color: Care2Theme.primary,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildMetricCard(
                      icon: Icons.bedtime,
                      label: 'Sleep',
                      value: healthState.isConnected
                          ? (healthState.data?.sleepDuration != 0 ? healthState.data!.sleepDuration.toStringAsFixed(1) : '--')
                          : '--',
                      unit: 'hrs',
                      color: Care2Theme.secondary,
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // Risk Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Risk Assessment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (riskState.isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Care2Theme.riskAmber),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRiskBar('Cardiac Risk', cardiacRisk, Care2Theme.riskRed),
                const SizedBox(height: 10),
                _buildRiskBar('Respiratory', respiratoryRisk, Care2Theme.primary),
                const SizedBox(height: 10),
                _buildRiskBar('Metabolic', metabolicRisk, Care2Theme.riskAmber),
                if (riskState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Could not load risk data: ${riskState.errorMessage}',
                      style: const TextStyle(color: Care2Theme.riskRed, fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildActionCard(
                      icon: Icons.camera_alt,
                      label: 'Scan Food',
                      gradient: Care2Theme.primaryGradient,
                      onTap: () => context.go('/nutrition'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildActionCard(
                      icon: Icons.air,
                      label: 'Check AQI',
                      gradient: Care2Theme.purpleGradient,
                      onTap: () => context.go('/environment'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildActionCard(
                      icon: Icons.analytics,
                      label: 'Risk Report',
                      gradient: Care2Theme.dangerGradient,
                      onTap: () => context.go('/predictions'),
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // Today's Insights — DYNAMIC
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: Care2Theme.glassDecoration(
                      opacity: 0.06, borderRadius: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Care2Theme.riskAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.lightbulb_outline,
                                color: Care2Theme.riskAmber, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Today's Insights",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...insights.map((text) => _buildInsight(text)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScoreRing() {
    return Container(
      width: 200,
      height: 200,
      decoration: Care2Theme.glowDecoration(color: Care2Theme.textTertiary),
      child: CustomPaint(
        painter: _RingPainter(progress: 0, color: Care2Theme.textTertiary),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Care2Theme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Analyzing...',
                style: TextStyle(
                  color: Care2Theme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Color _getScoreColor(double score) {
    if (score <= 30) return Care2Theme.riskGreen;
    if (score <= 60) return Care2Theme.riskAmber;
    return Care2Theme.riskRed;
  }

  String _getScoreLabel(double score) {
    if (score <= 30) return 'HEALTHY';
    if (score <= 60) return 'AT RISK';
    return 'CRITICAL';
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(color: Care2Theme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: value == '--' ? Care2Theme.textTertiary : color)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit,
                    style: TextStyle(
                        color: Care2Theme.textTertiary, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskBar(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Care2Theme.glassDecoration(opacity: 0.04, borderRadius: 16),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, animValue, _) {
                  return LinearProgressIndicator(
                    value: animValue,
                    minHeight: 10,
                    backgroundColor: Care2Theme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(color),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(value * 100).toInt()}%',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsight(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text,
          style: TextStyle(color: Care2Theme.textSecondary, fontSize: 14)),
    );
  }
}

// Custom ring painter for health score
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = color.withValues(alpha: 0.15),
    );

    // Progress arc
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
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
