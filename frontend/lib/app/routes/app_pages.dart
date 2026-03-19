import 'package:get/get.dart';
import 'package:frontend/app/modules/direct_messages/bindings/direct_messages_binding.dart';
import 'package:frontend/app/modules/direct_messages/views/direct_messages_view.dart';
import 'package:frontend/app/modules/initializer/bindings/initializer_binding.dart';
import 'package:frontend/app/modules/initializer/views/initializer_view.dart';
import 'package:frontend/app/modules/landing/bindings/landing_binding.dart';
import 'package:frontend/app/modules/landing/views/landing_view.dart';
import 'package:frontend/app/modules/login/bindings/login_binding.dart';
import 'package:frontend/app/modules/login/views/login_view.dart';
import 'package:frontend/app/modules/register/bindings/register_binding.dart';
import 'package:frontend/app/modules/register/views/register_view.dart';
import 'package:frontend/app/routes/app_routes.dart';

class AppPages {
  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.initial,
      page: () => const InitializerView(),
      binding: InitializerBinding(),
    ),
    GetPage(
      name: AppRoutes.landing,
      page: () => const LandingView(),
      binding: LandingBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.directMessages,
      page: () => const DirectMessagesView(),
      binding: DirectMessagesBinding(),
    ),
  ];
}
