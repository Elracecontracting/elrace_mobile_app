import 'package:get/get.dart';
import '../view_model/register_face_view_model.dart';

class RegisterFaceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterFaceViewController>(
      () => RegisterFaceViewController(),
    );
  }
}
