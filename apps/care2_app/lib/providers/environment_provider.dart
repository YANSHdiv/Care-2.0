import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'location_provider.dart';

class EnvironmentState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? environmentData;
  final Map<String, dynamic>? recommendationData;

  EnvironmentState({
    this.isLoading = false,
    this.errorMessage,
    this.environmentData,
    this.recommendationData,
  });

  EnvironmentState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? environmentData,
    Map<String, dynamic>? recommendationData,
  }) {
    return EnvironmentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      environmentData: environmentData ?? this.environmentData,
      recommendationData: recommendationData ?? this.recommendationData,
    );
  }
}

class EnvironmentNotifier extends StateNotifier<EnvironmentState> {
  final Ref ref;

  EnvironmentNotifier(this.ref) : super(EnvironmentState()) {
    // Watch location changes and refetch
    ref.listen(locationProvider, (previous, next) {
      if (next.details != null) {
        fetchEnvironment(next.details!);
      }
    });

    // Initial fetch if location is already available
    final loc = ref.read(locationProvider).details;
    if (loc != null) fetchEnvironment(loc);
  }

  Future<void> fetchEnvironment(LocationDetails loc) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final backendResponse = await ApiClient.getExerciseRecommendation(
        lat: loc.latitude, 
        lon: loc.longitude,
        conditions: [], // Placeholder
      );

      state = state.copyWith(
        isLoading: false,
        environmentData: backendResponse['environment'],
        recommendationData: backendResponse['recommendation'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final environmentProvider = StateNotifierProvider<EnvironmentNotifier, EnvironmentState>((ref) {
  return EnvironmentNotifier(ref);
});
