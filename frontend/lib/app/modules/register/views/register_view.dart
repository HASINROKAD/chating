import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:frontend/app/modules/register/controllers/register_controller.dart';
import 'package:frontend/app/routes/app_routes.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  static const Color _primaryPurple = Color(0xFF8D39D9);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _primaryPurple,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: Get.back,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                    ),
                    label: const Text('Back'),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(34),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 52 / 1.6,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 44),
                        _buildLabeledInput(
                          label: 'Name',
                          controller: controller.nameController,
                        ),
                        const SizedBox(height: 22),
                        _buildLabeledInput(
                          label: 'Email ID',
                          controller: controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 22),
                        Obx(
                          () => _buildLabeledInput(
                            label: 'Password',
                            controller: controller.passwordController,
                            obscureText: controller.obscurePassword.value,
                            suffixIcon: IconButton(
                              onPressed: controller.toggleObscurePassword,
                              icon: Icon(
                                controller.obscurePassword.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF7C7C7C),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Obx(
                              () => Transform.scale(
                                scale: 1.05,
                                child: Checkbox(
                                  value: controller.acceptedTerms.value,
                                  activeColor: _primaryPurple,
                                  onChanged: (value) {
                                    controller.setAcceptedTerms(value ?? false);
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: const [
                                  Text(
                                    'I have read and agree to the ',
                                    style: TextStyle(
                                      color: Color(0xFF9B9B9B),
                                      fontSize: 23 / 1.6,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Terms & Conditions',
                                    style: TextStyle(
                                      color: _primaryPurple,
                                      fontSize: 23 / 1.6,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Obx(
                          () => SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () => controller.handleRegister(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryPurple,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Register Now',
                                      style: TextStyle(
                                        fontSize: 30 / 1.6,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 34),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Color(0xFF9B9B9B),
                                  fontSize: 28 / 1.6,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Get.offNamed(AppRoutes.login);
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: _primaryPurple,
                                    fontSize: 28 / 1.6,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height:
                              MediaQuery.of(context).viewPadding.bottom + 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabeledInput({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 34 / 1.6,
            color: Color(0xFF8E8E8E),
            fontWeight: FontWeight.w600,
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          cursorColor: _primaryPurple,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 12, bottom: 12),
            suffixIcon: suffixIcon,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCACACA), width: 2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: _primaryPurple, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
