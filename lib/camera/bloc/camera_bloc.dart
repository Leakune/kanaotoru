import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:meta/meta.dart';

part 'camera_event.dart';
part 'camera_state.dart';

final _orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  late CameraController controller;
  final List<CameraDescription> _cameras;

  CameraBloc(this._cameras) : super(CameraInitial()) {
    controller = CameraController(
      _cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup
                .nv21 // for Android
          : ImageFormatGroup.bgra8888, // for iOS
    );
    on<CameraStarted>((event, emit) async {
      await controller.initialize().catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              // Handle access errors here.
              break;
            case 'AudioAccessDenied':
              // Handle audio access errors here.
              break;
            default:
              // Handle other errors here.
              break;
          }
        }
      });

      emit(CameraOngoing());
    });
    on<CameraScanLaunched>((event, emit) async {
      void processRecognizedText(RecognizedText recognizedText) {
        String text = recognizedText.text;
        print("text: $text");
        for (TextBlock block in recognizedText.blocks) {
          print("block: ${block.text}");

          final Rect rect = block.boundingBox;
          final cornerPoints = block.cornerPoints;
          final List<String> languages = block.recognizedLanguages;
          print("rect: $rect");
          print("cornerPoints: $cornerPoints");
          print("languages: $languages");

          for (TextLine line in block.lines) {
            print("line: ${line.text}");
            // Same getters as TextBlock
            for (TextElement element in line.elements) {
              print("element: ${element.text}");
              // Same getters as TextBlock
            }
          }
        }
      }

      final InputImage? inputImageToBeProcessed =
          await _captureInputImageFromStream();
      if (inputImageToBeProcessed == null) {
        print('No valid camera frame was available for text recognition.');
        return;
      }

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.japanese,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImageToBeProcessed,
      );
      processRecognizedText(recognizedText);
      textRecognizer.close();
    });
  }
  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }

  Future<InputImage?> _captureInputImageFromStream() async {
    final completer = Completer<InputImage?>();

    await controller.startImageStream((CameraImage image) {
      if (completer.isCompleted) return;

      final InputImage? inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      completer.complete(inputImage);
      controller.stopImageStream();
    });

    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        controller.stopImageStream();
        return null;
      },
    );
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas

    final camera = _cameras[controller.cameraId];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888))
      return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }
}
