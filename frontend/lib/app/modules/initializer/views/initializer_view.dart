import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:frontend/app/modules/initializer/controllers/initializer_controller.dart';

class InitializerView extends StatefulWidget {
  const InitializerView({super.key});

  @override
  State<InitializerView> createState() => _InitializerViewState();
}

class _InitializerViewState extends State<InitializerView> {
  late final InitializerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<InitializerController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.checkLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
