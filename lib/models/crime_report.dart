/// Crime report model
class CrimeReport {
  final String id;
  final String userId;
  final String crimeType;
  final String title;
  final String description;
  final String region;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? locationDescription;
  final DateTime incidentDate;
  final String severity;
  final String status; // 'pending', 'investigating', 'resolved', 'closed'
  final List<String>? evidenceUrls;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedOfficer;
  final String? resolutionNotes;
  final String? reporterName;
  final String? reporterPhone;
  final String? reporterEmail;
  final String? assignedOfficerName;

  CrimeReport({
    required this.id,
    required this.userId,
    required this.crimeType,
    required this.title,
    required this.description,
    required this.region,
    required this.city,
    this.latitude,
    this.longitude,
    this.locationDescription,
    required this.incidentDate,
    required this.severity,
    this.status = 'pending',
    this.evidenceUrls,
    this.isAnonymous = false,
    required this.createdAt,
    required this.updatedAt,
    this.assignedOfficer,
    this.resolutionNotes,
    this.reporterName,
    this.reporterPhone,
    this.reporterEmail,
    this.assignedOfficerName,
  });

  /// Create CrimeReport from JSON data
  factory CrimeReport.fromJson(Map<String, dynamic> json) {
    return CrimeReport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      crimeType: json['crime_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      region: json['region'] as String,
      city: json['city'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      locationDescription: json['location_description'] as String?,
      incidentDate: DateTime.parse(json['incident_date'] as String),
      severity: json['severity'] as String,
      status: json['status'] as String? ?? 'pending',
      evidenceUrls: json['evidence_urls'] != null
          ? List<String>.from(json['evidence_urls'] as List)
          : null,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      assignedOfficer: json['assigned_officer'] as String?,
      resolutionNotes: json['resolution_notes'] as String?,
      reporterName: json['reporter_name'] as String? ??
          (json['reporter']?['full_name'] as String?),
      reporterPhone: json['reporter_phone'] as String? ??
          (json['reporter']?['phone_number'] as String?),
      reporterEmail: json['reporter_email'] as String? ??
          (json['reporter']?['email'] as String?),
      assignedOfficerName: json['assigned_officer_name'] as String? ??
          (json['assigned']?['full_name'] as String?),
    );
  }

  /// Convert CrimeReport to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'crime_type': crimeType,
      'title': title,
      'description': description,
      'region': region,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'location_description': locationDescription,
      'incident_date': incidentDate.toIso8601String(),
      'severity': severity,
      'status': status,
      'evidence_urls': evidenceUrls,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'assigned_officer': assignedOfficer,
      'resolution_notes': resolutionNotes,
      'reporter_name': reporterName,
      'reporter_phone': reporterPhone,
      'reporter_email': reporterEmail,
      'assigned_officer_name': assignedOfficerName,
    };
  }

  /// Create a copy with updated fields
  CrimeReport copyWith({
    String? status,
    String? assignedOfficer,
    String? resolutionNotes,
    String? assignedOfficerName,
  }) {
    return CrimeReport(
      id: id,
      userId: userId,
      crimeType: crimeType,
      title: title,
      description: description,
      region: region,
      city: city,
      latitude: latitude,
      longitude: longitude,
      locationDescription: locationDescription,
      incidentDate: incidentDate,
      severity: severity,
      status: status ?? this.status,
      evidenceUrls: evidenceUrls,
      isAnonymous: isAnonymous,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      assignedOfficer: assignedOfficer ?? this.assignedOfficer,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      reporterName: reporterName,
      reporterPhone: reporterPhone,
      reporterEmail: reporterEmail,
      assignedOfficerName: assignedOfficerName ?? this.assignedOfficerName,
    );
  }
}

/// Crime report status enum
enum CrimeReportStatus {
  pending,
  investigating,
  resolved,
  closed,
}

extension CrimeReportStatusExtension on CrimeReportStatus {
  String get value {
    switch (this) {
      case CrimeReportStatus.pending:
        return 'pending';
      case CrimeReportStatus.investigating:
        return 'investigating';
      case CrimeReportStatus.resolved:
        return 'resolved';
      case CrimeReportStatus.closed:
        return 'closed';
    }
  }

  static CrimeReportStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return CrimeReportStatus.pending;
      case 'investigating':
        return CrimeReportStatus.investigating;
      case 'resolved':
        return CrimeReportStatus.resolved;
      case 'closed':
        return CrimeReportStatus.closed;
      default:
        return CrimeReportStatus.pending;
    }
  }
}
