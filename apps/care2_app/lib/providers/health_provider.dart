import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/google_fit_service.dart';

final googleFitServiceProvider = Provider<GoogleFitService>((ref) {
  return GoogleFitService();
});

class HealthDataState {
  final bool isLoading;
  final bool isConnected;
  final String? errorMessage;
  final HealthDataModel? data;

  HealthDataState({
    this.isLoading = false,
    this.isConnected = false,
    this.errorMessage,
    this.data,
  });

  HealthDataState copyWith({
    bool? isLoading,
    bool? isConnected,
    String? errorMessage,
    HealthDataModel? data,
  }) {
    return HealthDataState(
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage ?? this.errorMessage,
      data: data ?? this.data,
    );
  }
}

class HealthDataNotifier extends StateNotifier<HealthDataState> {
  final GoogleFitService _service;

  HealthDataNotifier(this._service) : super(HealthDataState());

  Future<void> connectAndFetch() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final account = await _service.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false, isConnected: false, errorMessage: "User canceled sign-in.");
        return;
      }
      
      final data = await _service.fetchTodayData();
      state = state.copyWith(isLoading: false, isConnected: true, data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, isConnected: false, errorMessage: e.toString());
    }
  }

  Future<void> disconnect() async {
    await _service.signOut();
    state = HealthDataState(isConnected: false);
  }
}

final healthDataProvider = StateNotifierProvider<HealthDataNotifier, HealthDataState>((ref) {
  final service = ref.watch(googleFitServiceProvider);
  return HealthDataNotifier(service);
});
