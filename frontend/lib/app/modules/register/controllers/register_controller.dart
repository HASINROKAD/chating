import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/routes/app_routes.dart';
import 'package:frontend/services/auth_service.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final obscurePassword = true.obs;
  final acceptedTerms = false.obs;
  final isLoading = false.obs;

  void toggleObscurePassword() {
    obscurePassword.value = !obscurePassword.value;
  }

  void setAcceptedTerms(bool value) {
    acceptedTerms.value = value;
  }

  Future<void> handleRegister(BuildContext context) async {
    final String name = nameController.text.trim();
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
      return;
    }

    if (!acceptedTerms.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms and conditions.')),
      );
      return;
    }

    isLoading.value = true;
    final bool success = await AuthService.registerUser(
      email,
      password,
      name: name,
    );
    isLoading.value = false;

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration successful.')));
      Get.offNamed(AppRoutes.login);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration failed. Please try again.')),
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
