import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/bill_calculation.dart';
import '../services/firestore_service.dart';
import '../services/google_drive_service.dart';
import '../services/pdf_invoice_service.dart';
import '../services/billing_calculator.dart';
import '../controllers/home_controller.dart';
import '../services/auth_service.dart';

class BillCalculationController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final GoogleDriveService _driveService = Get.find<GoogleDriveService>();
  final PdfInvoiceService _pdfService = Get.find<PdfInvoiceService>();
  final HomeController _homeController = Get.find<HomeController>();
  final AuthService _authService = Get.find<AuthService>();

  final currentMotherReadingCtrl = TextEditingController();
  final totalBillAmountCtrl = TextEditingController();
  final Map<String, TextEditingController> subReadingCtrls = {};

  Rx<DateTime> selectedMonth = DateTime.now().obs;
  Rx<BillCalculation?> calculationResult = Rx<BillCalculation?>(null);
  RxBool isCalculating = false.obs;
  RxBool isSaving = false.obs;

  double prevMotherReading = 0.0;
  Map<String, double> prevSubReadings = {};

  @override
  void onInit() {
    super.onInit();
    final config = _homeController.meterConfig.value;
    if (config != null) {
      for (var sub in config.subMeters) {
        subReadingCtrls[sub.label] = TextEditingController();
      }
    }
    try {
      final currentParsed = DateFormat('yyyy-MM').parse(_homeController.currentMonthTag.value);
      selectedMonth.value = currentParsed;
    } catch (e) {
      selectedMonth.value = DateTime.now();
    }
    _loadPreviousReadings();
  }

  Future<void> _loadPreviousReadings() async {
    final uid = _authService.firebaseUser.value?.uid;
    if (uid == null) return;
    
    final lastReadings = await _firestoreService.getLastReadings(uid);
    if (lastReadings != null) {
      prevMotherReading = (lastReadings['currentMotherReading'] ?? 0.0).toDouble();
      
      final flatsData = lastReadings['flats'] as List<dynamic>? ?? [];
      for (var f in flatsData) {
        final flatLabel = f['flatLabel'] as String;
        final currentReading = (f['currentReading'] ?? 0.0).toDouble();
        prevSubReadings[flatLabel] = currentReading;
      }
    } else {
      final config = _homeController.meterConfig.value;
      if (config != null) {
        prevMotherReading = config.baselineMotherUnit;
        for (var sub in config.subMeters) {
          prevSubReadings[sub.label] = sub.baselineUnit;
        }
      }
    }
    update();
  }

  void calculateBill() {
    final config = _homeController.meterConfig.value;
    if (config == null) {
      Get.snackbar('Error', 'Meter config not found.');
      return;
    }

    if (currentMotherReadingCtrl.text.isEmpty) {
      Get.snackbar('Error', 'Enter current mother reading');
      return;
    }

    final currentMother = double.tryParse(currentMotherReadingCtrl.text) ?? 0.0;
    if (currentMother < prevMotherReading) {
      Get.snackbar('Error', 'Current mother reading cannot be less than previous');
      return;
    }

    Map<String, double> currentSubMap = {};
    for (var sub in config.subMeters) {
      final ctrl = subReadingCtrls[sub.label];
      final currentSub = double.tryParse(ctrl?.text ?? '') ?? prevSubReadings[sub.label] ?? sub.baselineUnit;
      currentSubMap[sub.label] = currentSub;
    }

    Map<String, double> rechargesMap = {};
    double totalDeposits = 0.0;
    for (var flat in _homeController.availableFlats) {
      final amt = _homeController.getTotalRechargeForFlat(flat);
      rechargesMap[flat] = amt;
      totalDeposits += amt;
    }

    final totalBillAmount = double.tryParse(totalBillAmountCtrl.text) ?? totalDeposits;

    final result = BillingCalculator.calculate(
      config: config,
      month: DateFormat('yyyy-MM').format(selectedMonth.value),
      prevMotherReading: prevMotherReading,
      currentMotherReading: currentMother,
      prevSubReadings: prevSubReadings,
      currentSubReadings: currentSubMap,
      rechargesByFlat: rechargesMap,
      totalBillAmount: totalBillAmount,
    );

    calculationResult.value = result;
  }

  Future<void> saveAndGeneratePdf() async {
    if (calculationResult.value == null) return;
    
    final uid = _authService.firebaseUser.value?.uid;
    final config = _homeController.meterConfig.value;
    
    if (uid == null || config == null) return;
    if (config.driveFolderId == null) {
      Get.snackbar('Error', 'No Google Drive folder linked for backups.');
      return;
    }

    isSaving.value = true;

    try {
      final pdfBytes = await _pdfService.generateInvoice(calculationResult.value!);
      
      final fileName = 'Electricity_Bill_${calculationResult.value!.month}.pdf';
      final fileUrl = await _driveService.uploadPdfFile(
        pdfBytes: pdfBytes,
        fileName: fileName,
        folderId: config.driveFolderId!,
      );

      if (fileUrl != null) {
        await _firestoreService.saveMonthlyReport(
          uid: uid,
          calculation: calculationResult.value!,
          driveUrl: fileUrl,
        );
        Get.back();
        Get.snackbar('Success', 'Bill calculated and saved to Google Drive!');
      } else {
        Get.snackbar('Error', 'Failed to upload PDF to Drive.');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    currentMotherReadingCtrl.dispose();
    for (var ctrl in subReadingCtrls.values) {
      ctrl.dispose();
    }
    super.onClose();
  }
}
