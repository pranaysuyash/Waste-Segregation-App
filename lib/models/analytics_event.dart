class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  
  const AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
} 