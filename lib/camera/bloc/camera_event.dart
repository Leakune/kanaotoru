part of 'camera_bloc.dart';

@immutable
sealed class CameraEvent {}

final class CameraStarted extends CameraEvent {}

final class CameraScanLaunched extends CameraEvent {}
