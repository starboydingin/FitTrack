// Stub untuk platform Web — menggantikan package:geolocator
// agar tidak crash saat di-import di lingkungan yang tidak mendukungnya.

class Position {
  final double latitude;
  final double longitude;
  final double accuracy;
  const Position({
    this.latitude = 0,
    this.longitude = 0,
    this.accuracy = 0,
  });
}

class LocationSettings {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  const LocationSettings({
    this.accuracy = LocationAccuracy.high,
    this.distanceFilter = 0,
  });
}

enum LocationAccuracy { lowest, low, medium, high, best, bestForNavigation }

class Geolocator {
  static Future<bool> isLocationServiceEnabled() async => false;

  static Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      const Stream.empty();

  static double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) =>
      0.0;
}
