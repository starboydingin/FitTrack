import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_constants.dart';

class PermissionState {
  final PermissionStatus locationForeground;
  final PermissionStatus locationBackground;
  final PermissionStatus activityRecognition;

  const PermissionState({
    required this.locationForeground,
    required this.locationBackground,
    required this.activityRecognition,
  });

  PermissionState copyWith({
    PermissionStatus? locationForeground,
    PermissionStatus? locationBackground,
    PermissionStatus? activityRecognition,
  }) {
    return PermissionState(
      locationForeground:  locationForeground ?? this.locationForeground,
      locationBackground:  locationBackground ?? this.locationBackground,
      activityRecognition: activityRecognition ?? this.activityRecognition,
    );
  }

  bool get isMinimumGranted =>
      locationForeground.isGranted && activityRecognition.isGranted;

  bool get isAllGranted =>
      locationForeground.isGranted &&
      locationBackground.isGranted &&
      activityRecognition.isGranted;
}

class PermissionNotifier extends StateNotifier<PermissionState> {
  PermissionNotifier() : super(_dummyGrantedState) {
    checkAllPermissions();
  }

  static const PermissionState _dummyGrantedState = PermissionState(
    locationForeground:  PermissionStatus.granted,
    locationBackground:  PermissionStatus.granted,
    activityRecognition: PermissionStatus.granted,
  );

  Future<void> checkAllPermissions() async {
    // Jika dummy mode aktif, semua izin langsung dianggap diberikan.
    if (kUseDummyMode) {
      state = _dummyGrantedState;
      return;
    }

    final locFore = await Permission.location.status;
    final locBack = await Permission.locationAlways.status;
    final activity = await Permission.activityRecognition.status;

    state = PermissionState(
      locationForeground:  locFore,
      locationBackground:  locBack,
      activityRecognition: activity,
    );
  }

  Future<void> requestLocationForeground() async {
    if (kUseDummyMode) {
      state = state.copyWith(locationForeground: PermissionStatus.granted);
      return;
    }

    final status = await Permission.location.request();
    state = state.copyWith(locationForeground: status);
    // Refresh background status karena bergantung pada foreground
    final statusBack = await Permission.locationAlways.status;
    state = state.copyWith(locationBackground: statusBack);
  }

  Future<void> requestLocationBackground() async {
    if (kUseDummyMode) {
      state = state.copyWith(locationBackground: PermissionStatus.granted);
      return;
    }

    // Background location memerlukan foreground terlebih dahulu
    if (!state.locationForeground.isGranted) {
      await requestLocationForeground();
    }
    final status = await Permission.locationAlways.request();
    state = state.copyWith(locationBackground: status);
  }

  Future<void> requestActivityRecognition() async {
    if (kUseDummyMode) {
      state = state.copyWith(activityRecognition: PermissionStatus.granted);
      return;
    }

    final status = await Permission.activityRecognition.request();
    state = state.copyWith(activityRecognition: status);
  }

  Future<void> openAppSettingsPage() async {
    if (kUseDummyMode) {
      state = _dummyGrantedState;
      return;
    }

    await openAppSettings();
    await checkAllPermissions();
  }
}

final permissionProvider =
    StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
  return PermissionNotifier();
});
