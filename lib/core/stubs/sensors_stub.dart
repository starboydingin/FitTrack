// Stub untuk platform Web — menggantikan package:sensors_plus

class UserAccelerometerEvent {
  final double x;
  final double y;
  final double z;
  const UserAccelerometerEvent(this.x, this.y, this.z);
}

Stream<UserAccelerometerEvent> userAccelerometerEventStream({
  Duration? samplingPeriod,
}) =>
    const Stream.empty();

// Alias lama yang mungkin masih direferensikan
Stream<UserAccelerometerEvent> get userAccelerometerEvents =>
    const Stream.empty();
