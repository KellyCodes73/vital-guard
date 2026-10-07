class MonitoringConfig {
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final bool scheduledEnabled;
  final int alertTimeoutSeconds;

  const MonitoringConfig({
    required this.startTime,
    required this.endTime,
    required this.scheduledEnabled,
    required this.alertTimeoutSeconds,
  });

  factory MonitoringConfig.fromJson(Map<String, dynamic> json) => MonitoringConfig(
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        scheduledEnabled: json['scheduledEnabled'] as bool,
        alertTimeoutSeconds: (json['alertTimeoutSeconds'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'startTime': startTime,
        'endTime': endTime,
        'scheduledEnabled': scheduledEnabled,
        'alertTimeoutSeconds': alertTimeoutSeconds,
      };
}

class MonitoringSession {
  final int id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status; // ACTIVE | STOPPED
  final bool demoMode;

  const MonitoringSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.status,
    required this.demoMode,
  });

  factory MonitoringSession.fromJson(Map<String, dynamic> json) => MonitoringSession(
        id: (json['id'] as num).toInt(),
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] == null ? null : DateTime.parse(json['endedAt'] as String),
        status: json['status'] as String,
        demoMode: json['demoMode'] as bool,
      );
}
