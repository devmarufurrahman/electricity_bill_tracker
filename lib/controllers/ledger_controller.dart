import 'package:get/get.dart';
import '../models/recharge_entry.dart';
import '../models/bill_calculation.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class LedgerController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();

  RxBool isLoading = true.obs;
  RxMap<String, double> flatBalances = <String, double>{}.obs; // >0 means advance, <0 means due

  @override
  void onInit() {
    super.onInit();
    _calculateLedger();
  }

  Future<void> _calculateLedger() async {
    final uid = _authService.firebaseUser.value?.uid;
    if (uid == null) return;

    isLoading.value = true;
    try {
      // 1. Fetch ALL recharges for this user
      final rechargesSnapshot = await _firestoreService.getAllRecharges(uid);
      
      // 2. Fetch ALL reports for this user
      final reportsSnapshot = await _firestoreService.getAllReports(uid);

      Map<String, double> balances = {};

      // Add all recharges
      for (var doc in rechargesSnapshot) {
        final entry = RechargeEntry.fromMap(doc.data(), doc.id);
        balances[entry.flat] = (balances[entry.flat] ?? 0.0) + entry.amount;
      }

      // Subtract all billed costs
      for (var doc in reportsSnapshot) {
        final report = BillCalculation.fromMap(doc.data());
        for (var flat in report.flats) {
          balances[flat.flatLabel] = (balances[flat.flatLabel] ?? 0.0) - flat.cost;
        }
      }

      flatBalances.value = balances;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load ledger: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
