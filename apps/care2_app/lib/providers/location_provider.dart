import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';

class LocationDetails {
  final double latitude;
  final double longitude;
  final String city;
  final String country;

  LocationDetails({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
  });

  factory LocationDetails.unknown() {
    return LocationDetails(latitude: 0, longitude: 0, city: "Unknown", country: "Location");
  }
}

class LocationState {
  final bool isLoading;
  final String? errorMessage;
  final LocationDetails? details;

  LocationState({
    this.isLoading = false,
    this.errorMessage,
    this.details,
  });

  LocationState copyWith({
    bool? isLoading,
    String? errorMessage,
    LocationDetails? details,
  }) {
    return LocationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      details: details ?? this.details,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState()) {
    initLocation();
  }

  Future<void> initLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services are disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Permission denied.");
      }
      if (permission == LocationPermission.deniedForever) throw Exception("Permission permanently denied.");

      // 2. FAST PATH: Use last known position immediately (no GPS wait)
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        // Emit coords immediately WITHOUT waiting for reverse geocoding
        state = state.copyWith(
          isLoading: false,
          details: LocationDetails(
            latitude: lastPosition.latitude,
            longitude: lastPosition.longitude,
            city: "Locating...",
            country: "",
          ),
        );
        // Reverse geocode in background
        _reverseGeocodeAndUpdate(lastPosition);
      }

      // 3. Always attempt to get a fresh position to sync actual current location
      Position freshPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 30),
      );

      // Only update if it's materially different from lastPosition, or if we didn't have one
      if (lastPosition == null || 
          (freshPosition.latitude - lastPosition.latitude).abs() > 0.001 ||
          (freshPosition.longitude - lastPosition.longitude).abs() > 0.001) {
        
        state = state.copyWith(
          isLoading: false,
          details: LocationDetails(
            latitude: freshPosition.latitude,
            longitude: freshPosition.longitude,
            city: "Locating...",
            country: "",
          ),
        );
        _reverseGeocodeAndUpdate(freshPosition);
      }
    } catch (e) {
      // 4. Fallback 1: IP Geolocation (if GPS fails or is denied)
      if (state.details == null) {
        try {
          final dio = Dio();
          final response = await dio.get('http://ip-api.com/json').timeout(const Duration(seconds: 5));
          if (response.statusCode == 200) {
            final data = response.data;
            if (data['status'] == 'success') {
              state = state.copyWith(
                isLoading: false,
                details: LocationDetails(
                  latitude: data['lat'].toDouble(),
                  longitude: data['lon'].toDouble(),
                  city: data['city'] ?? "Network Location",
                  country: data['country'] ?? "",
                ),
                errorMessage: null, // Successfully got it via IP
              );
              return;
            }
          }
        } catch (ipError) {
          // Ignore IP error, proceed to Delhi fallback
        }
      }

      if (state.details == null) {
        // Fallback 2: use Delhi coords so the app doesn't stay stuck
        state = state.copyWith(
          isLoading: false,
          details: LocationDetails(
            latitude: 28.6139,
            longitude: 77.2090,
            city: "New Delhi",
            country: "India",
          ),
          errorMessage: "Using default location: ${e.toString()}",
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Reverse geocodes in the background and updates city/country.
  /// This doesn't block the main flow — environment data can fetch
  /// as soon as we have lat/lng.
  Future<void> _reverseGeocodeAndUpdate(Position pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude, pos.longitude,
      ).timeout(const Duration(seconds: 3));

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        state = state.copyWith(
          details: LocationDetails(
            latitude: pos.latitude,
            longitude: pos.longitude,
            city: p.locality ?? p.subAdministrativeArea ?? "Nearby",
            country: p.country ?? "India",
          ),
        );
      }
    } catch (_) {
      // Reverse geocoding failed — keep the coords, just show generic name
      if (mounted) {
        state = state.copyWith(
          details: LocationDetails(
            latitude: pos.latitude,
            longitude: pos.longitude,
            city: "Current Location",
            country: "",
          ),
        );
      }
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
