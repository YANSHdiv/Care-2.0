import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_provider.dart';
import 'environment_provider.dart';
import 'risk_report_provider.dart';

/// Generates dynamic "Today's Insights" from real user data.
/// Watches health vitals, environment, and risk report providers.
final insightsProvider = Provider<List<String>>((ref) {
  final healthState = ref.watch(healthDataProvider);
  final envState = ref.watch(environmentProvider);
  final riskState = ref.watch(riskReportProvider);

  final insights = <String>[];

  // ── Health Data Insights ──
  if (healthState.isConnected && healthState.data != null) {
    final data = healthState.data!;

    // Steps insight
    if (data.steps < 3000) {
      insights.add('🏃 Very low step count (${data.steps}) — try to move more today');
    } else if (data.steps < 5000) {
      insights.add('🏃 Step count is ${data.steps} — aim for 8000+ today');
    } else if (data.steps < 8000) {
      insights.add('🏃 ${data.steps} steps so far — push for 8000+ to hit your goal');
    } else {
      insights.add('🏃 Great job! ${data.steps} steps today — keep it up!');
    }

    // Sleep insight
    if (data.sleepDuration < 6) {
      insights.add('😴 Only ${data.sleepDuration.toStringAsFixed(1)} hrs of sleep — this is below recommended');
    } else if (data.sleepDuration < 7) {
      insights.add('😴 Sleep was ${data.sleepDuration.toStringAsFixed(1)} hrs — try for 7+ tonight');
    } else {
      insights.add('😴 Good sleep at ${data.sleepDuration.toStringAsFixed(1)} hrs — well rested!');
    }

    // Heart rate insight
    if (data.heartRate > 100) {
      insights.add('❤️ Elevated heart rate (${data.heartRate} bpm) — take it easy today');
    } else if (data.heartRate > 0 && data.heartRate < 50) {
      insights.add('❤️ Unusually low heart rate (${data.heartRate} bpm) — monitor closely');
    }

    // SpO2 insight
    if (data.spo2 > 0 && data.spo2 < 95) {
      insights.add('🫁 SpO₂ is low at ${data.spo2}% — consider checking with a doctor');
    } else if (data.spo2 > 0 && data.spo2 < 96) {
      insights.add('🫁 SpO₂ is borderline at ${data.spo2}% — keep monitoring');
    }
  } else {
    // Not connected
    insights.add('📱 Connect Google Fit to get personalized health insights');
  }

  // ── Environment Insights ──
  if (envState.environmentData != null) {
    final env = envState.environmentData!;
    final aqi = env['aqi'] as int? ?? 1;
    final aqiLabel = env['aqi_label'] as String? ?? 'Good';
    final tempC = env['temperature_c'] as num?;

    if (aqi >= 300) {
      insights.add('🌡️ AQI is $aqiLabel ($aqi) — Hazardous, avoid outdoor exercise today');
    } else if (aqi >= 200) {
      insights.add('🌡️ AQI is $aqiLabel ($aqi) — indoor exercise recommended');
    } else if (aqi >= 100) {
      insights.add('🌤️ AQI is $aqiLabel ($aqi) — outdoor activity is fine with caution');
    }

    if (tempC != null && tempC > 40) {
      insights.add('🔥 Temperature is ${tempC.toStringAsFixed(0)}°C — stay hydrated and avoid peak sun');
    } else if (tempC != null && tempC < 5) {
      insights.add('🧊 Temperature is ${tempC.toStringAsFixed(0)}°C — dress warmly for outdoor activity');
    }
  }

  // ── Risk Report Insights ──
  if (riskState.hasReport) {
    if (riskState.cardiacRisk > 0.4) {
      insights.add('❤️ Your cardiac risk is elevated — consider a heart health check-up');
    }
    if (riskState.metabolicRisk > 0.5) {
      insights.add('⚖️ High metabolic risk detected — focus on balanced nutrition');
    }
    if (riskState.respiratoryRisk > 0.3) {
      insights.add('🫁 Respiratory risk is above normal — monitor breathing patterns');
    }
  }

  // If we somehow have no insights (no data at all), provide defaults
  if (insights.isEmpty) {
    insights.add('💡 Complete your profile and connect a wearable for personalized insights');
  }

  // Cap at 4 insights for the dashboard
  return insights.take(4).toList();
});
