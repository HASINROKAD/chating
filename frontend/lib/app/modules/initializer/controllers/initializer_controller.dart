import 'package:get/get.dart';
import 'package:frontend/app/routes/app_routes.dart';
import 'package:frontend/services/auth_service.dart';

class InitializerController extends GetxController {
  var didInit = false;

  Future<void> checkLogin() async {
    if (didInit) return;
    didInit = true;

    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn == true) {
      Get.offAllNamed(AppRoutes.landing);
      return;
    }

    Get.offAllNamed(AppRoutes.landing);
  }
}
