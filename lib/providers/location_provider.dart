import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationProvider extends ChangeNotifier {
  LatLng? _currentLocation;
  bool _isLoading = false;
  String? _errorMessage;
  final Distance _distanceCalc = const Distance();

  LatLng? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LocationProvider() {
    // Optionally fetch location immediately, but we'll wait for the user to press the button
    // or trigger it on app start if desired.
  }

  Future<void> fetchCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permissions are denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permissions are permanently denied, we cannot request permissions.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Permissions are granted, get the position.
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
    } catch (e) {
      _errorMessage = 'Failed to get location: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculates the distance in kilometers between the user's current location and a given gym location.
  /// If the user's location is unknown, returns null.
  double? calculateDistance(double gymLatitude, double gymLongitude) {
    if (_currentLocation == null) return null;
    
    // Fallback if gym doesn't have a valid location
    if (gymLatitude == 0.0 && gymLongitude == 0.0) return null;

    final double meters = _distanceCalc.as(
      LengthUnit.Meter,
      _currentLocation!,
      LatLng(gymLatitude, gymLongitude),
    );

    return meters / 1000.0; // Return as Kilometers
  }
}
