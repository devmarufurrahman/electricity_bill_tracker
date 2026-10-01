import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/meter_config.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../controllers/home_controller.dart';

class EditMeterProfileController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();
  final HomeController _homeController = Get.find<HomeController>();

  final mainTenantNameCtrl = TextEditingController();
  final mainTenantContactCtrl = TextEditingController();
  final mainTenantEmailCtrl = TextEditingController();

  final RxList<Map<String, TextEditingController>> subMeterCtrls = <Map<String, TextEditingController>>[].obs;

  RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final config = _homeController.meterConfig.value;
    if (config != null) {
      mainTenantNameCtrl.text = config.mainTenantName ?? '';
      mainTenantContactCtrl.text = config.mainTenantContact ?? '';
      mainTenantEmailCtrl.text = config.mainTenantEmail ?? '';

      for (var sub in config.subMeters) {
        subMeterCtrls.add({
          'label': TextEditingController(text: sub.label),
          'tenantName': TextEditingController(text: sub.tenantName ?? ''),
          'tenantContact': TextEditingController(text: sub.tenantContact ?? ''),
          'tenantEmail': TextEditingController(text: sub.tenantEmail ?? ''),
        });
      }
    }
  }

  Future<void> saveProfile() async {
    final uid = _authService.firebaseUser.value?.uid;
    final config = _homeController.meterConfig.value;
    if (uid == null || config == null) return;

    isSaving.value = true;
    try {
      // Reconstruct sub-meters with updated tenant info
      List<SubMeterConfig> updatedSubMeters = [];
      for (int i = 0; i < config.subMeters.length; i++) {
        final originalSub = config.subMeters[i];
        final ctrls = subMeterCtrls[i];
        
        updatedSubMeters.add(SubMeterConfig(
          label: ctrls['label']!.text, // Label might change slightly but should be careful
          baselineUnit: originalSub.baselineUnit,
          serialNumber: originalSub.serialNumber,
          tenantName: ctrls['tenantName']!.text.isEmpty ? null : ctrls['tenantName']!.text,
          tenantContact: ctrls['tenantContact']!.text.isEmpty ? null : ctrls['tenantContact']!.text,
          tenantEmail: ctrls['tenantEmail']!.text.isEmpty ? null : ctrls['tenantEmail']!.text,
        ));
      }

      final updatedConfig = MeterConfig(
        accountNumber: config.accountNumber,
        mainMeterNumber: config.mainMeterNumber,
        baselineMotherUnit: config.baselineMotherUnit,
        startMonthYear: config.startMonthYear,
        mainFlatLabel: config.mainFlatLabel,
        mainTenantName: mainTenantNameCtrl.text.isEmpty ? null : mainTenantNameCtrl.text,
        mainTenantContact: mainTenantContactCtrl.text.isEmpty ? null : mainTenantContactCtrl.text,
        mainTenantEmail: mainTenantEmailCtrl.text.isEmpty ? null : mainTenantEmailCtrl.text,
        subMeters: updatedSubMeters,
        driveFolderId: config.driveFolderId,
      );

      await _firestoreService.saveMeterConfig(uid, updatedConfig);
      
      // Update in memory
      _homeController.meterConfig.value = updatedConfig;
      
      Get.back();
      Get.snackbar('Success', 'Profile updated successfully!');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    mainTenantNameCtrl.dispose();
    mainTenantContactCtrl.dispose();
    mainTenantEmailCtrl.dispose();
    for (var ctrls in subMeterCtrls) {
      for (var c in ctrls.values) {
        c.dispose();
      }
    }
    super.onClose();
  }
}
