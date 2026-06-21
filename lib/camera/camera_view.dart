import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kanaotoru/camera/bloc/camera_bloc.dart';
import 'package:flutter/widget_previews.dart';

class CameraView extends StatelessWidget {
  final List<CameraDescription> _cameras;
  static const colorButton = Color.fromARGB(255, 102, 17, 141);

  const CameraView(this._cameras, {super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CameraBloc(_cameras)..add(CameraStarted()),
      child: BlocBuilder<CameraBloc, CameraState>(
        builder: (context, state) {
          if (!context.read<CameraBloc>().controller.value.isInitialized) {
            return Container();
          }
          return cameraViewWidget(context);
        },
      ),
    );
  }

  static Widget cameraViewWidget(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CameraPreview(context.read<CameraBloc>().controller),
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 0, 0, 0),
                child: Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(0),
                            enableFeedback: false,
                          ).merge(
                            ButtonStyle(
                              overlayColor:
                                  WidgetStateProperty.resolveWith<Color?>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.hovered)) {
                                      return colorButton.withValues(
                                        alpha: 0.04,
                                      );
                                    }
                                    if (states.contains(WidgetState.focused) ||
                                        states.contains(WidgetState.pressed)) {
                                      return colorButton.withValues(
                                        alpha: 0.62,
                                      );
                                    }
                                    return null; // Defer to the widget's default.
                                  }),
                            ),
                          ),
                      onPressed: () {},
                      // context.read<CameraBloc>().add(CameraScanLaunched()),
                      child: Icon(
                        Icons.camera_alt,
                        size: IconTheme.of(context).size,
                        color: colorButton,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'CameraViewWidget')
Widget cameraViewPreview() {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: Text('Camera preview (placeholder)')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.camera_alt),
      ),
    ),
  );
}
