import '../../trusted_contact/domain/trusted_contact_models.dart';

class LocationInfo {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime capturedAt;
  final DateTime expiresAt;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
    required this.expiresAt,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) => LocationInfo(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        accuracyMeters: json['accuracyMeters'] == null ? null : (json['accuracyMeters'] as num).toDouble(),
        capturedAt: DateTime.parse(json['capturedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}

/// Alerta vista por el auxiliador.
class AlertInfo {
  final int id;
  final String status; // ACTIVE | ACKNOWLEDGED | CLOSED
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime eventDetectedAt;
  final PersonSummary? monitoredUser;
  final bool locationAvailable;
  final DateTime locationExpiresAt;
  final LocationInfo? location;

  const AlertInfo({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.acknowledgedAt,
    required this.eventDetectedAt,
    required this.monitoredUser,
    required this.locationAvailable,
    required this.locationExpiresAt,
    required this.location,
  });

  bool get isActive => status == 'ACTIVE';

  factory AlertInfo.fromJson(Map<String, dynamic> json) => AlertInfo(
        id: (json['id'] as num).toInt(),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        acknowledgedAt:
            json['acknowledgedAt'] == null ? null : DateTime.parse(json['acknowledgedAt'] as String),
        eventDetectedAt: DateTime.parse(json['eventDetectedAt'] as String),
        monitoredUser: json['monitoredUser'] == null
            ? null
            : PersonSummary.fromJson(Map<String, dynamic>.from(json['monitoredUser'] as Map)),
        locationAvailable: json['locationAvailable'] as bool,
        locationExpiresAt: DateTime.parse(json['locationExpiresAt'] as String),
        location: json['location'] == null
            ? null
            : LocationInfo.fromJson(Map<String, dynamic>.from(json['location'] as Map)),
      );
}
