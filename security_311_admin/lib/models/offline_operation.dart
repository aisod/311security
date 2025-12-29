import 'package:hive/hive.dart';

part 'offline_operation.g.dart';

/// Offline operation types
@HiveType(typeId: 0)
enum OfflineOperationType {
  @HiveField(0)
  createCrimeReport,
  @HiveField(1)
  updateCrimeReport,
  @HiveField(2)
  createEmergencyAlert,
  @HiveField(3)
  updateProfile,
  @HiveField(4)
  markNotificationRead,
  @HiveField(5)
  createEmergencyContact,
  @HiveField(6)
  updateEmergencyContact,
  @HiveField(7)
  deleteEmergencyContact,
}

/// Offline operation model for Hive storage
@HiveType(typeId: 1)
class OfflineOperation {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final OfflineOperationType type;

  @HiveField(2)
  final Map<String, dynamic> data;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final int retryCount;

  @HiveField(5)
  final String? userId;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.userId,
  });

  factory OfflineOperation.create({
    required OfflineOperationType type,
    required Map<String, dynamic> data,
    String? userId,
  }) {
    return OfflineOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
      userId: userId,
    );
  }

  OfflineOperation copyWith({
    int? retryCount,
  }) {
    return OfflineOperation(
      id: id,
      type: type,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount ?? this.retryCount,
      userId: userId,
    );
  }
}




