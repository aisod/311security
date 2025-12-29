enum MissingReportType { missingPerson, lostItem, foundPerson }

enum MissingReportStatus { pending, approved, rejected }

class MissingReport {
  final String id;
  final String userId;
  final MissingReportType reportType;
  final String title;
  final String description;
  final String? personName;
  final int? age;
  final String? lastSeenLocation;
  final DateTime? lastSeenDate;
  final String? contactPhone;
  final String? contactEmail;
  final List<String>? photoUrls;
  final MissingReportStatus status;
  final String? adminNotes;
  final String? approvedBy;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MissingReport({
    required this.id,
    required this.userId,
    required this.reportType,
    required this.title,
    required this.description,
    this.personName,
    this.age,
    this.lastSeenLocation,
    this.lastSeenDate,
    this.contactPhone,
    this.contactEmail,
    this.photoUrls,
    this.status = MissingReportStatus.pending,
    this.adminNotes,
    this.approvedBy,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MissingReport.fromJson(Map<String, dynamic> json) {
    return MissingReport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reportType: MissingReportType.values.firstWhere(
        (type) => type.value == json['report_type'],
        orElse: () => MissingReportType.missingPerson,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      personName: json['person_name'] as String?,
      age: json['age'] as int?,
      lastSeenLocation: json['last_seen_location'] as String?,
      lastSeenDate: json['last_seen_date'] != null
          ? DateTime.parse(json['last_seen_date'] as String)
          : null,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      photoUrls: json['photo_urls'] != null
          ? List<String>.from(json['photo_urls'] as List<dynamic>)
          : null,
      status: MissingReportStatusExtension.fromString(
          json['status'] as String? ?? 'pending'),
      adminNotes: json['admin_notes'] as String?,
      approvedBy: json['approved_by'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'report_type': reportType.value,
      'title': title,
      'description': description,
      'person_name': personName,
      'age': age,
      'last_seen_location': lastSeenLocation,
      'last_seen_date': lastSeenDate?.toIso8601String(),
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'photo_urls': photoUrls,
      'status': status.value,
      'admin_notes': adminNotes,
      'approved_by': approvedBy,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

extension MissingReportTypeExtension on MissingReportType {
  String get value {
    switch (this) {
      case MissingReportType.missingPerson:
        return 'missing_person';
      case MissingReportType.lostItem:
        return 'lost_item';
      case MissingReportType.foundPerson:
        return 'found_person';
    }
  }

  String get displayLabel {
    switch (this) {
      case MissingReportType.missingPerson:
        return 'Missing Person';
      case MissingReportType.lostItem:
        return 'Lost Item';
      case MissingReportType.foundPerson:
        return 'Found';
    }
  }
}

extension MissingReportStatusExtension on MissingReportStatus {
  String get value {
    switch (this) {
      case MissingReportStatus.pending:
        return 'pending';
      case MissingReportStatus.approved:
        return 'approved';
      case MissingReportStatus.rejected:
        return 'rejected';
    }
  }

  static MissingReportStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return MissingReportStatus.approved;
      case 'rejected':
        return MissingReportStatus.rejected;
      case 'pending':
      default:
        return MissingReportStatus.pending;
    }
  }
}

