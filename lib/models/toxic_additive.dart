class ToxicAdditive {
  final String name;
  final String risk;
  final String status;
  final String severity; // 'low', 'medium', 'high'
  final String? eNumber;
  final String? insNumber;

  ToxicAdditive({
    required this.name,
    required this.risk,
    required this.status,
    required this.severity,
    this.eNumber,
    this.insNumber,
  });

  factory ToxicAdditive.fromJson(Map<String, dynamic> json) {
    return ToxicAdditive(
      name: json['name'] ?? '',
      risk: json['risk'] ?? json['known risks'] ?? '',
      status: json['status'] ?? '',
      severity: json['severity'] ?? 'low',
      eNumber: json['E number'],
      insNumber: json['INS number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'risk': risk,
      'status': status,
      'severity': severity,
      if (eNumber != null) 'E number': eNumber,
      if (insNumber != null) 'INS number': insNumber,
    };
  }

  bool get isHighRisk => severity == 'high';
  bool get isMediumRisk => severity == 'medium';
  bool get isLowRisk => severity == 'low';
}
