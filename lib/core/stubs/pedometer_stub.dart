// Stub untuk platform Web — menggantikan package:pedometer

class StepCount {
  final int steps;
  final DateTime timeStamp;
  StepCount(this.steps, this.timeStamp);
}

class Pedometer {
  static Stream<StepCount> get stepCountStream => const Stream.empty();
}
