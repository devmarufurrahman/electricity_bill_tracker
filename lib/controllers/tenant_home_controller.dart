import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../models/bill_calculation.dart';
import '../models/recharge_entry.dart';
import 'package:url_launcher/url_launcher.dart';

class TenantHomeController extends GetxController {
  final String managerUid;
  final String flatLabel;

  TenantHomeController({required this.managerUid, required this.flatLabel});

  final FirestoreService _firestoreService = Get.find<FirestoreService>();

  RxBool isLoading = true.obs;
  RxDouble balance = 0.0.obs; // positive means advance, negative means due
  RxList<RechargeEntry> myRecharges = <RechargeEntry>[].obs;
  RxList<Map<String, dynamic>> myBills = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadTenantData();
  }

  Future<void> _loadTenantData() async {
    isLoading.value = true;
    try {
      // 1. Fetch all recharges for this flat
      final rechargesSnapshot = await _firestoreService.getAllRecharges(managerUid);
      List<RechargeEntry> recharges = [];
      double totalRecharged = 0.0;

      for (var doc in rechargesSnapshot) {
        final entry = RechargeEntry.fromMap(doc.data(), doc.id);
        if (entry.flat == flatLabel) {
          recharges.add(entry);
          totalRecharged += entry.amount;
        }
      }
      recharges.sort((a, b) => b.date.compareTo(a.date));
      myRecharges.value = recharges;

      // 2. Fetch all bills and find this flat's cost
      final reportsSnapshot = await _firestoreService.getAllReports(managerUid);
      List<Map<String, dynamic>> bills = [];
      double totalCost = 0.0;

      for (var doc in reportsSnapshot) {
        final data = doc.data();
        final calc = BillCalculation.fromMap(data);
        
        // Find this flat in the calculation
        try {
          final myFlatCalc = calc.flats.firstWhere((f) => f.flatLabel == flatLabel);
          totalCost += myFlatCalc.cost;
          
          bills.add({
            'month': calc.month,
            'cost': myFlatCalc.cost,
            'unitsUsed': myFlatCalc.unitsUsed,
            'unitRate': calc.unitRate,
            'driveUrl': data['driveUrl'],
          });
        } catch (e) {
          // Flat might not have existed in this old bill, ignore
        }
      }
      
      // Sort bills by month descending
      bills.sort((a, b) => (b['month'] as String).compareTo(a['month'] as String));
      myBills.value = bills;

      // 3. Calculate balance
      balance.value = totalRecharged - totalCost;

    } catch (e) {
      Get.snackbar('Error', 'Failed to load data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openReport(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not open the report link.');
    }
  }
}
