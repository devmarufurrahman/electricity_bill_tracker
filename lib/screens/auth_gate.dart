import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key});
  
  final AuthService _authService = Get.find<AuthService>();
  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (_authController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_authService.firebaseUser.value == null) {
          return _buildLoginScreen(context);
        }

        return const Center(child: CircularProgressIndicator());
      }),
    );
  }

  Widget _buildLoginScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.electrical_services, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text('Electricity Bill Tracker', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Manage multi-meter electricity bills easily', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () => _authController.signInWithGoogle(),
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
