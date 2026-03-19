import 'package:get/get.dart';
import 'package:frontend/app/modules/initializer/controllers/initializer_controller.dart';

class InitializerBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<InitializerController>(InitializerController());
  }
}
