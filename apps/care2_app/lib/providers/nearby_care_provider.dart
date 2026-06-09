import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import 'location_provider.dart';

class NearbyState {
  final bool isLoading;
  final String? errorMessage;
  final List<Map<String, dynamic>> facilities;

  NearbyState({
    this.isLoading = false,
    this.errorMessage,
    this.facilities = const [],
  });

  NearbyState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Map<String, dynamic>>? facilities,
  }) {
    return NearbyState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      facilities: facilities ?? this.facilities,
    );
  }
}

class NearbyNotifier extends StateNotifier<NearbyState> {
  final Ref ref;

  NearbyNotifier(this.ref) : super(NearbyState()) {
    // Watch location changes and refetch
    ref.listen(locationProvider, (previous, next) {
      if (next.details != null) {
        fetchNearby(next.details!);
      }
    });

    // Initial fetch if location is already available
    final loc = ref.read(locationProvider).details;
    if (loc != null) fetchNearby(loc);
  }

  Future<void> fetchNearby(LocationDetails loc) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final backendResponse = await ApiClient.findNearbyCare(
        lat: loc.latitude, 
        lon: loc.longitude,
        radiusKm: 10.0,
      );

      final List<dynamic> rawFacilities = backendResponse['facilities'] ?? [];
      final List<Map<String, dynamic>> facilities = rawFacilities.cast<Map<String, dynamic>>();

      state = state.copyWith(
        isLoading: false,
        facilities: facilities,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final nearbyCareProvider = StateNotifierProvider<NearbyNotifier, NearbyState>((ref) {
  return NearbyNotifier(ref);
});
