import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/meter_config.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/google_drive_service.dart';
import '../screens/home_screen.dart';

class MeterSetupController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final GoogleDriveService _driveService = Get.find<GoogleDriveService>();
  
  final accountNumCtrl = TextEditingController();
  final mainMeterNumCtrl = TextEditingController();
  final baselineMotherCtrl = TextEditingController();
  final mainFlatLabelCtrl = TextEditingController(text: '2/D');
  final mainTenantNameCtrl = TextEditingController();
  final mainTenantContactCtrl = TextEditingController();
  final mainTenantEmailCtrl = TextEditingController();

  Rx<DateTime> startDate = DateTime.now().obs;
  RxList<Map<String, dynamic>> subMetersData = <Map<String, dynamic>>[].obs;
  
  RxBool isLoading = false.obs;

  Future<void> pickStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      startDate.value = DateTime(picked.year, picked.month, 1);
    }
  }

  void addSubMeter() {
    subMetersData.add({
      'label': TextEditingController(),
      'baselineUnit': TextEditingController(),
      'serialNumber': TextEditingController(),
      'tenantName': TextEditingController(),
      'tenantContact': TextEditingController(),
      'tenantEmail': TextEditingController(),
    });
  }

  void removeSubMeter(int index) {
    // Dispose controllers
    final data = subMetersData[index];
    (data['label'] as TextEditingController).dispose();
    (data['baselineUnit'] as TextEditingController).dispose();
    (data['serialNumber'] as TextEditingController).dispose();
    (data['tenantName'] as TextEditingController).dispose();
    (data['tenantContact'] as TextEditingController).dispose();
    (data['tenantEmail'] as TextEditingController).dispose();
    subMetersData.removeAt(index);
  }

  Future<void> saveConfig() async {
    final uid = _authService.firebaseUser.value?.uid;
    if (uid == null) return;

    if (accountNumCtrl.text.isEmpty || baselineMotherCtrl.text.isEmpty) {
      Get.snackbar('Error', 'Please fill required main fields');
      return;
    }

    isLoading.value = true;
    try {
      final folderName = 'electricity_bill_tracker';
      final folderId = await _driveService.getOrCreateFolder(folderName);
      
      List<SubMeterConfig> parsedSubMeters = subMetersData.map((data) {
        return SubMeterConfig(
          label: (data['label'] as TextEditingController).text,
          baselineUnit: double.tryParse((data['baselineUnit'] as TextEditingController).text) ?? 0.0,
          serialNumber: (data['serialNumber'] as TextEditingController).text,
          tenantName: (data['tenantName'] as TextEditingController).text,
          tenantContact: (data['tenantContact'] as TextEditingController).text,
          tenantEmail: (data['tenantEmail'] as TextEditingController).text,
        );
      }).toList();

      if (parsedSubMeters.any((sm) => sm.label.isEmpty)) {
        Get.snackbar('Error', 'All sub-meters must have a label');
        isLoading.value = false;
        return;
      }

      final config = MeterConfig(
        accountNumber: accountNumCtrl.text,
        mainMeterNumber: mainMeterNumCtrl.text.isNotEmpty ? mainMeterNumCtrl.text : null,
        baselineMotherUnit: double.tryParse(baselineMotherCtrl.text) ?? 0.0,
        startMonthYear: DateFormat('MMMM yyyy').format(startDate.value),
        mainFlatLabel: mainFlatLabelCtrl.text.isNotEmpty ? mainFlatLabelCtrl.text : 'Main',
        mainTenantName: mainTenantNameCtrl.text.isNotEmpty ? mainTenantNameCtrl.text : null,
        mainTenantContact: mainTenantContactCtrl.text.isNotEmpty ? mainTenantContactCtrl.text : null,
        mainTenantEmail: mainTenantEmailCtrl.text.isNotEmpty ? mainTenantEmailCtrl.text : _authService.firebaseUser.value?.email,
        subMeters: parsedSubMeters,
        driveFolderId: folderId,
      );

      await _firestoreService.saveMeterConfig(uid, config);
      Get.offAll(() => HomeScreen()); // Navigate to Home instead of triggering AuthController

    } catch (e) {
      Get.snackbar('Setup Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    accountNumCtrl.dispose();
    mainMeterNumCtrl.dispose();
    baselineMotherCtrl.dispose();
    mainFlatLabelCtrl.dispose();
    mainTenantNameCtrl.dispose();
    mainTenantContactCtrl.dispose();
    mainTenantEmailCtrl.dispose();
    for (var data in subMetersData) {
      (data['label'] as TextEditingController).dispose();
      (data['baselineUnit'] as TextEditingController).dispose();
      (data['serialNumber'] as TextEditingController).dispose();
      (data['tenantName'] as TextEditingController).dispose();
      (data['tenantContact'] as TextEditingController).dispose();
      (data['tenantEmail'] as TextEditingController).dispose();
    }
    super.onClose();
  }
}
