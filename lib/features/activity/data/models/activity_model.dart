import '../../domain/entities/activity_entity.dart';

class ActivityModel extends ActivityEntity {
  const ActivityModel({
    required super.localId,
    required super.activityDate,
    required super.startedAt,
    required super.endedAt,
    required super.steps,
    required super.distanceMeters,
    required super.activityType,
    super.latitude,
    super.longitude,
    required super.recordedAt,
    super.syncStatus,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
        // 'id' dari server response, 'localId'/'local_id' dari lokal
        localId: (json['localId'] ?? json['local_id'] ?? json['id']) as String,
        activityDate:
            (json['activityDate'] ?? json['activity_date']) as String,
        startedAt: DateTime.parse(
            (json['startedAt'] ?? json['started_at']) as String),
        endedAt: DateTime.parse(
            (json['endedAt'] ?? json['ended_at']) as String),
        steps: (json['steps'] as num).toInt(),
        distanceMeters:
            ((json['distanceMeters'] ?? json['distance_meters']) as num)
                .toInt(),
        activityType:
            (json['activityType'] ?? json['activity_type']) as String,
        latitude:  (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        recordedAt: DateTime.parse(
            (json['recordedAt'] ?? json['recorded_at']) as String),
        syncStatus: (json['syncStatus'] ?? json['sync_status'] ?? 'pending')
            as String,
      );

  Map<String, dynamic> toJson() => {
        'localId':        localId,
        'activityDate':   activityDate,
        'startedAt':      startedAt.toIso8601String(),
        'endedAt':        endedAt.toIso8601String(),
        'steps':          steps,
        'distanceMeters': distanceMeters,
        'activityType':   activityType,
        'latitude':       latitude,
        'longitude':      longitude,
        'recordedAt':     recordedAt.toIso8601String(),
      };

  factory ActivityModel.fromDbMap(Map<String, dynamic> map) => ActivityModel(
        localId:        map['local_id'] as String,
        activityDate:   map['activity_date'] as String,
        startedAt:      DateTime.parse(map['started_at'] as String),
        endedAt:        DateTime.parse(map['ended_at'] as String),
        steps:          (map['steps'] as num).toInt(),
        distanceMeters: (map['distance_meters'] as num).toInt(),
        activityType:   map['activity_type'] as String,
        latitude:       (map['latitude'] as num?)?.toDouble(),
        longitude:      (map['longitude'] as num?)?.toDouble(),
        recordedAt:     DateTime.parse(map['recorded_at'] as String),
        syncStatus:     map['sync_status'] as String,
      );

  Map<String, dynamic> toDbMap() => {
        'local_id':        localId,
        'activity_date':   activityDate,
        'started_at':      startedAt.toIso8601String(),
        'ended_at':        endedAt.toIso8601String(),
        'steps':          steps,
        'distance_meters': distanceMeters,
        'activity_type':   activityType,
        'latitude':       latitude,
        'longitude':      longitude,
        'recorded_at':     recordedAt.toIso8601String(),
        'sync_status':     syncStatus,
      };
}
