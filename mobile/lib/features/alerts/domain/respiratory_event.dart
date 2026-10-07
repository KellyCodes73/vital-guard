class EventSources {
  static const String experimental = 'EXPERIMENTAL';
  static const String demo = 'DEMO';
}

class EventStatuses {
  static const String detected = 'DETECTED';
  static const String resolved = 'ATENDIDO_POR_USUARIO';
  static const String notified = 'NOTIFICADO_A_AUXILIADOR';
  static const String noHelper = 'SIN_AUXILIADOR';
  static const String closed = 'CERRADO';
}

class RespiratoryEvent {
  final int id;
  final int sessionId;
  final DateTime detectedAt;
  final double confidence;
  final String source;
  final String status;
  final DateTime? resolvedAt;
  final DateTime? escalatedAt;
  final int? alertId;

  const RespiratoryEvent({
    required this.id,
    required this.sessionId,
    required this.detectedAt,
    required this.confidence,
    required this.source,
    required this.status,
    required this.resolvedAt,
    required this.escalatedAt,
    required this.alertId,
  });

  bool get isDemo => source == EventSources.demo;

  String get statusLabel {
    switch (status) {
      case EventStatuses.detected:
        return 'Pendiente de respuesta';
      case EventStatuses.resolved:
        return 'Atendido por ti';
      case EventStatuses.notified:
        return 'Notificado a tu persona de confianza';
      case EventStatuses.noHelper:
        return 'Sin respuesta · no había persona de confianza';
      case EventStatuses.closed:
        return 'Cerrado · tu persona de confianza confirmó la recepción';
      default:
        return status;
    }
  }

  factory RespiratoryEvent.fromJson(Map<String, dynamic> json) => RespiratoryEvent(
        id: (json['id'] as num).toInt(),
        sessionId: (json['sessionId'] as num).toInt(),
        detectedAt: DateTime.parse(json['detectedAt'] as String),
        confidence: (json['confidence'] as num).toDouble(),
        source: json['source'] as String,
        status: json['status'] as String,
        resolvedAt: json['resolvedAt'] == null ? null : DateTime.parse(json['resolvedAt'] as String),
        escalatedAt: json['escalatedAt'] == null ? null : DateTime.parse(json['escalatedAt'] as String),
        alertId: json['alertId'] == null ? null : (json['alertId'] as num).toInt(),
      );
}
