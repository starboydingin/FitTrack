import 'package:equatable/equatable.dart';

class ActivityEntity extends Equatable {
  final String localId;
  final String activityDate; // YYYY-MM-DD
  final DateTime startedAt;
  final DateTime endedAt;
  final int steps;
  final int distanceMeters;
  final String activityType; // 'idle', 'walking', 'running'
  final double? latitude;
  final double? longitude;
  final DateTime recordedAt;
  final String syncStatus; // 'pending', 'syncing', 'synced', 'failed'

  const ActivityEntity({
    required this.localId,
    required this.activityDate,
    required this.startedAt,
    required this.endedAt,
    required this.steps,
    required this.distanceMeters,
    required this.activityType,
    this.latitude,
    this.longitude,
    required this.recordedAt,
    this.syncStatus = 'pending',
  });

  @override
  List<Object?> get props => [
        localId,
        activityDate,
        startedAt,
        endedAt,
        steps,
        distanceMeters,
        activityType,
        latitude,
        longitude,
        recordedAt,
        syncStatus,
      ];
}
