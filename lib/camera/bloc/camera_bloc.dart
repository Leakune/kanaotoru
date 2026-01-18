import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:meta/meta.dart';

part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  late CameraController controller;
  final List<CameraDescription> _cameras;

  CameraBloc(this._cameras) : super(CameraInitial()) {
    controller = CameraController(_cameras[0], ResolutionPreset.max);
    on<CameraStartup>((event, emit) async {
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
  }
  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
