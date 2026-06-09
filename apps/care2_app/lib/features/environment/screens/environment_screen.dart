import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import 'dart:math';
import '../../../providers/environment_provider.dart';
import '../../../providers/location_provider.dart';

class EnvironmentScreen extends ConsumerStatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  ConsumerState<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends ConsumerState<EnvironmentScreen> {
  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return Care2Theme.riskGreen;
    if (aqi <= 100) return const Color(0xFF69F0AE);
    if (aqi <= 200) return Care2Theme.riskAmber;
    if (aqi <= 300) return const Color(0xFFFF9100);
    return Care2Theme.riskRed;
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final envState = ref.watch(environmentProvider);

    if (locationState.isLoading || envState.isLoading || envState.environmentData == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1117), Color(0xFF1A1A2E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Care2Theme.primary),
                const SizedBox(height: 24),
                Text(
                  locationState.details?.city ?? "Detecting Location...",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Syncing Live OpenWeatherMap APIs...",
                  style: TextStyle(color: Care2Theme.textTertiary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (envState.errorMessage != null && envState.environmentData == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D1117), Color(0xFF1A1A2E)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, color: Care2Theme.riskRed, size: 48),
                   const SizedBox(height: 16),
                   Text("Error: ${envState.errorMessage}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: () => ref.read(locationProvider.notifier).initLocation(),
                     child: const Text("Retry"),
                   )
                ],
              ),
            ),
          ),
        ),
      );
    }

    final env = envState.environmentData!;
    final rec = envState.recommendationData!;

    final int _aqi = env['aqi'] ?? 1;
    final String _aqiLabel = env['aqi_label'] ?? 'Good';
    final double _temperature = (env['temperature_c'] as num).toDouble();
    final int _humidity = (env['humidity'] as num).toInt();
    final String _weather = env['weather_main'] ?? 'Clear';
    final double _pm25 = (env['pm25'] as num?)?.toDouble() ?? 0.0;
    
    final List<dynamic> _activities = rec['activities'] ?? [];
    final aqiColor = _getAqiColor(_aqi);
    final locationName = locationState.details != null 
        ? "${locationState.details!.city}, ${locationState.details!.country}" 
        : "Detecting...";

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => Care2Theme.primaryGradient.createShader(b),
                      child: const Text(
                        'Environment Sync',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Care2Theme.textSecondary),
                      onPressed: () => ref.read(locationProvider.notifier).initLocation(),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Care2Theme.textTertiary, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationName,
                        style: const TextStyle(color: Care2Theme.textTertiary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // AQI Gauge
                Center(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1800),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: (_aqi / 500.0).clamp(0.0, 1.0)),
                    builder: (context, value, child) {
                      return Container(
                        width: 200, height: 200,
                        decoration: Care2Theme.glowDecoration(color: aqiColor),
                        child: CustomPaint(
                          painter: _AqiGaugePainter(progress: value, color: aqiColor),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$_aqi', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: aqiColor)),
                                const Text('AQI', style: TextStyle(color: Care2Theme.textSecondary, fontSize: 14)),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: aqiColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(_aqiLabel.toUpperCase(),
                                      style: TextStyle(color: aqiColor, fontSize: 11, fontWeight: FontWeight.w700)),
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

                Row(
                  children: [
                    Expanded(child: _buildEnvCard(Icons.thermostat, 'Temp', "${_temperature.toStringAsFixed(1)}°C", Care2Theme.riskRed)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildEnvCard(Icons.water_drop, 'Humidity', "$_humidity%", Care2Theme.accent)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildEnvCard(Icons.cloud, 'Weather', _weather, Care2Theme.secondary)),
                  ],
                ),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.blur_circular, color: Care2Theme.riskAmber, size: 22),
                      const SizedBox(width: 12),
                      const Text('PM2.5', style: TextStyle(color: Care2Theme.textSecondary, fontSize: 14)),
                      const Spacer(),
                      Text("$_pm25 µg/m³", style: const TextStyle(color: Care2Theme.riskAmber, fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (rec['mode'] == 'indoor' && (rec['reason'] as String).isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Care2Theme.riskRed.withValues(alpha: 0.15), Care2Theme.riskAmber.withValues(alpha: 0.1)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Care2Theme.riskRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Care2Theme.riskAmber, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Indoor Exercise Recommended', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(rec['reason'], style: const TextStyle(color: Care2Theme.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const Text('Recommended Activities', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ..._activities.map((a) => _buildActivityCard(a)),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnvCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Care2Theme.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final intensityColor = activity['intensity'] == 'high' ? Care2Theme.riskRed : activity['intensity'] == 'medium' ? Care2Theme.riskAmber : Care2Theme.riskGreen;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Care2Theme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.directions_run, color: Care2Theme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(activity['description'] ?? '', style: const TextStyle(color: Care2Theme.textTertiary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 12, color: Care2Theme.textTertiary),
                    const SizedBox(width: 4),
                    Text('${activity["duration_min"] ?? 0} min', style: const TextStyle(color: Care2Theme.textSecondary, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.local_fire_department, size: 12, color: Care2Theme.riskRed),
                    const SizedBox(width: 4),
                    Text('${activity["calories_burn_estimate"] ?? 0} kcal', style: const TextStyle(color: Care2Theme.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AqiGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  _AqiGaugePainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = 12..color = color.withValues(alpha: 0.12));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round..color = color);
  }
  @override
  bool shouldRepaint(covariant _AqiGaugePainter old) => old.progress != progress || old.color != color;
}
