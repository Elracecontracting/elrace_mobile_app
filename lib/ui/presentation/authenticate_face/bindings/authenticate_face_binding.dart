import 'package:get/get.dart';
import '../view_model/authenticate_face_view_model.dart';

class AuthenticateFaceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthenticateFaceViewController>(
      () => AuthenticateFaceViewController(),
    );
  }
}
