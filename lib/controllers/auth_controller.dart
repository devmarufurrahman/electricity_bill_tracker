import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/home_screen.dart';
import '../screens/meter_setup_wizard_screen.dart';
import '../screens/auth_gate.dart';
import '../screens/tenant_home_screen.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  
  RxBool isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    ever(_authService.firebaseUser, _handleAuthChanged);
    _handleAuthChanged(_authService.firebaseUser.value);
  }

  Future<void> _handleAuthChanged(User? user) async {
    if (user == null) {
      Get.offAll(() => AuthGate());
      return;
    }
    
    isLoading.value = true;
    try {
      final config = await _firestoreService.getMeterConfig(user.uid);
      if (config != null) {
        Get.offAll(() => HomeScreen());
      } else {
        // Check if user is a tenant
        if (user.email != null) {
          final tenantLink = await _firestoreService.getTenantLink(user.email!);
          if (tenantLink != null) {
            Get.offAll(() => TenantHomeScreen(
              managerUid: tenantLink['managerUid'],
              flatLabel: tenantLink['flatLabel'],
            ));
            return;
          }
        }
        Get.offAll(() => MeterSetupWizardScreen());
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    await _authService.signInWithGoogle();
    isLoading.value = false;
  }

  Future<void> signOut() async {
    isLoading.value = true;
    await _authService.signOut();
    isLoading.value = false;
  }
}
