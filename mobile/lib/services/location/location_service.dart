import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

class LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  const LocationResult(this.latitude, this.longitude, this.accuracy);
}

/// Acceso al GPS. Solo se usa durante una alerta (la ubicación nunca se comparte de forma permanente).
class LocationService {
  bool _granted(LocationPermission p) =>
      p == LocationPermission.whileInUse || p == LocationPermission.always;

  Future<bool> hasPermission() async => _granted(await Geolocator.checkPermission());

  Future<bool> requestPermission() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return _granted(p);
  }

  Future<LocationResult> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('La ubicación del dispositivo está desactivada.');
    }
    if (!await hasPermission()) {
      throw const LocationException('No hay permiso de ubicación.');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return LocationResult(pos.latitude, pos.longitude, pos.accuracy);
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
