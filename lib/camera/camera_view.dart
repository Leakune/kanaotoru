import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kanaotoru/camera/bloc/camera_bloc.dart';

class CameraView extends StatelessWidget {
  final List<CameraDescription> _cameras;

  const CameraView(this._cameras, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CameraBloc(_cameras)..add(CameraStartup()),
      child: BlocBuilder<CameraBloc, CameraState>(
        builder: (context, state) {
          if (!context.read<CameraBloc>().controller.value.isInitialized) {
            return Container();
          }
          return MaterialApp(
            home: CameraPreview(context.read<CameraBloc>().controller),
          );
        },
      ),
    );
  }
}
