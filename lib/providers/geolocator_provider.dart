import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/main.dart';
import 'package:weather_app/services/geolocator_service.dart';
import 'package:weather_app/storage/shared_storage.dart';

class GeolocatorProvider extends ChangeNotifier {
  final GeolocatorService _geolocatorService;
  final SharedStorage _storage;

  String _country = '';
  String _city = '';
  bool isInitialized = false;

  String get country => _country;
  String get city => _city;

  GeolocatorProvider(this._geolocatorService, this._storage) {
    _init();
  }

  Future<void> _init() async {
    try {
      if (_storage.getCountry().isEmpty) {
        await _detectLocation();
      } else {
        _country = _storage.getCountry();
        final cities = _storage.getCities();
        _city = cities.isNotEmpty ? cities.first : 'Unknown';
      }
    } catch (e) {
      print('Error during geolocation init: $e');
      _country = 'Unknown';
      _city = 'Unknown';
    }

    isInitialized = true;
    notifyListeners();
  }

  Future<void> _detectLocation() async {
    try {
      final position = await _geolocatorService.determinePosition(
        navigatorKey.currentContext!,
        onPositionReady: (pos) => _handlePosition(pos),
      );

      if (position != null) {
        await _handlePosition(position);
      }
    } catch (e) {
      print('Failed to detect location: $e');
    }
  }

  Future<void> _handlePosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _country = place.country ?? 'India';
        _city = place.locality ?? 'Delhi';

        _storage.saveCountry(_country);
        _storage.saveCountryCode(place.isoCountryCode ?? '');
        _storage.saveCities([_city]);

        notifyListeners(); // triggers UI/weather update
      }
    } catch (e) {
      print('Error decoding coordinates: $e');
    }
  }

  String getUserCountryCode() => _storage.getCountryCode();
}
