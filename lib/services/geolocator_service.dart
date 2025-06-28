import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

typedef OnPositionReady = void Function(Position position);

class GeolocatorService with WidgetsBindingObserver {
  late BuildContext _context;
  bool _openedSettings = false;
  OnPositionReady? _onPositionReady;

  void init(BuildContext context) {
    _context = context;
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  Future<Position?> determinePosition(
    BuildContext context, {
    OnPositionReady? onPositionReady,
  }) async {
    init(context);
    _onPositionReady = onPositionReady;

    try {
      final position = await _getLocationFlow();
      _onPositionReady?.call(position);
      return position;
    } catch (e) {
      return null;
    }
  }

  Future<Position> _getLocationFlow() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _openedSettings = true;
      _showLocationDialog(_context);
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _openedSettings = true;
        _showPermissionDeniedDialog(_context);
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _openedSettings = true;
      _showPermissionDeniedDialog(_context);
      throw Exception('Location permission permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_openedSettings && state == AppLifecycleState.resumed) {
      _openedSettings = false;
      _handleReturnFromSettings();
    }
  }

  Future<void> _handleReturnFromSettings() async {
    try {
      final position = await _getLocationFlow();
      _onPositionReady?.call(position);
    } catch (_) {
      // Already handled via UI dialogs
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Location Required',
              style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'This app needs location permission to show accurate weather data.\n\nPlease allow permission to continue.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _openedSettings = true;
              await Geolocator.openAppSettings();
            },
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => exit(0),
            style: TextButton.styleFrom(backgroundColor: Colors.grey[300]),
            child: const Text('Exit', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Location access',
              style: TextStyle(
                color: Colors.blue[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Turn on location services and allow your device to determine location using wireless networks.',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _openedSettings = true;
              await Geolocator.openLocationSettings();
            },
            style: TextButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text(
              'Settings',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () => exit(0),
            style: TextButton.styleFrom(backgroundColor: Colors.grey[300]),
            child: const Text('Exit', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
