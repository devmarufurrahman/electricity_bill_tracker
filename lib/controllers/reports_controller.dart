import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bill_calculation.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class ReportsController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();

  RxBool isLoading = true.obs;
  RxList<Map<String, dynamic>> reports = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final uid = _authService.firebaseUser.value?.uid;
    if (uid == null) return;

    isLoading.value = true;
    try {
      final snapshot = await _firestoreService.getAllReports(uid);
      final List<Map<String, dynamic>> loadedReports = snapshot.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort by month descending
      loadedReports.sort((a, b) => (b['month'] as String).compareTo(a['month'] as String));
      reports.value = loadedReports;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load reports: $e');
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
