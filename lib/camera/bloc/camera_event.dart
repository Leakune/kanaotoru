part of 'camera_bloc.dart';

@immutable
sealed class CameraEvent {}

class CameraStartup extends CameraEvent {}
