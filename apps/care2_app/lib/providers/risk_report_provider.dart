import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/constants.dart';

class RiskReportState {
  final bool isLoading;
  final String? errorMessage;
  final int overallScore;
  final String riskCategory;
  final double cardiacRisk;
  final double respiratoryRisk;
  final double metabolicRisk;
  final List<String> concerns;
  final List<String> recommendations;
  final List<Map<String, dynamic>> trajectory;
  final Map<String, dynamic>? dataSummary;
  final bool hasReport;

  RiskReportState({
    this.isLoading = false,
    this.errorMessage,
    this.overallScore = 0,
    this.riskCategory = 'healthy',
    this.cardiacRisk = 0.0,
    this.respiratoryRisk = 0.0,
    this.metabolicRisk = 0.0,
    this.concerns = const [],
    this.recommendations = const [],
    this.trajectory = const [],
    this.dataSummary,
    this.hasReport = false,
  });

  RiskReportState copyWith({
    bool? isLoading,
    String? errorMessage,
    int? overallScore,
    String? riskCategory,
    double? cardiacRisk,
    double? respiratoryRisk,
    double? metabolicRisk,
    List<String>? concerns,
    List<String>? recommendations,
    List<Map<String, dynamic>>? trajectory,
    Map<String, dynamic>? dataSummary,
    bool? hasReport,
  }) {
    return RiskReportState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      overallScore: overallScore ?? this.overallScore,
      riskCategory: riskCategory ?? this.riskCategory,
      cardiacRisk: cardiacRisk ?? this.cardiacRisk,
      respiratoryRisk: respiratoryRisk ?? this.respiratoryRisk,
      metabolicRisk: metabolicRisk ?? this.metabolicRisk,
      concerns: concerns ?? this.concerns,
      recommendations: recommendations ?? this.recommendations,
      trajectory: trajectory ?? this.trajectory,
      dataSummary: dataSummary ?? this.dataSummary,
      hasReport: hasReport ?? this.hasReport,
    );
  }
}

class RiskReportNotifier extends StateNotifier<RiskReportState> {
  RiskReportNotifier() : super(RiskReportState());

  Future<void> fetchReport(String uid) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Try to get existing report first
      try {
        final existing = await ApiClient.getLatestReport(uid);
        _applyReport(existing, null);
        return;
      } catch (_) {
        // No existing report — generate a demo one
      }

      final response = await ApiClient.generateDemoReport(uid);
      final report = response['report'] as Map<String, dynamic>?;
      final summary = response['data_summary'] as Map<String, dynamic>?;

      if (report != null) {
        _applyReport(report, summary);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Empty report received');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> regenerateReport(String uid) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await ApiClient.generateDemoReport(uid);
      final report = response['report'] as Map<String, dynamic>?;
      final summary = response['data_summary'] as Map<String, dynamic>?;

      if (report != null) {
        _applyReport(report, summary);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Empty report received');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _applyReport(Map<String, dynamic> report, Map<String, dynamic>? summary) {
    final concerns = (report['top_concerns'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    final recs = (report['recommendations'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];
    final traj = (report['healthspan_trajectory'] as List<dynamic>?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];

    state = state.copyWith(
      isLoading: false,
      hasReport: true,
      overallScore: (report['overall_risk_score'] as num?)?.toInt() ?? 0,
      riskCategory: report['risk_category'] as String? ?? 'healthy',
      cardiacRisk: (report['cardiac_risk'] as num?)?.toDouble() ?? 0.0,
      respiratoryRisk: (report['respiratory_risk'] as num?)?.toDouble() ?? 0.0,
      metabolicRisk: (report['metabolic_risk'] as num?)?.toDouble() ?? 0.0,
      concerns: concerns,
      recommendations: recs,
      trajectory: traj,
      dataSummary: summary,
    );
  }
}

final riskReportProvider =
    StateNotifierProvider<RiskReportNotifier, RiskReportState>((ref) {
  return RiskReportNotifier();
});
