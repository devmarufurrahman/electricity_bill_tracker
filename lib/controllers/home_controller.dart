import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/recharge_entry.dart';
import '../models/meter_config.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class HomeController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final AuthService _authService = Get.find<AuthService>();
  
  RxList<RechargeEntry> recharges = <RechargeEntry>[].obs;
  RxString currentMonthTag = ''.obs;
  Rx<MeterConfig?> meterConfig = Rx<MeterConfig?>(null);
  RxMap<String, double> lastReadingsMap = <String, double>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserConfig();
  }

  Future<void> _loadUserConfig() async {
    final uid = _authService.firebaseUser.value?.uid;
    if (uid == null) return;

    final config = await _firestoreService.getMeterConfig(uid);
    meterConfig.value = config;

    if (config != null) {
      final lastReport = await _firestoreService.getLastReadings(uid);
      if (lastReport != null && lastReport['month'] != null) {
        currentMonthTag.value = lastReport['month'];
      } else {
        try {
          final startDt = DateFormat('MMMM yyyy').parse(config.startMonthYear);
          currentMonthTag.value = DateFormat('yyyy-MM').format(startDt);
        } catch (e) {
          currentMonthTag.value = DateFormat('yyyy-MM').format(DateTime.now());
        }
      }
      recharges.bindStream(_firestoreService.streamRechargesForMonth(uid, currentMonthTag.value));
      _fetchLastReadings(uid, currentMonthTag.value, config);
    }
  }

  void changeMonth(String newMonthTag) {
    final uid = _authService.firebaseUser.value?.uid;
    if (uid == null) return;
    currentMonthTag.value = newMonthTag;
    recharges.bindStream(_firestoreService.streamRechargesForMonth(uid, currentMonthTag.value));
    if (meterConfig.value != null) {
      _fetchLastReadings(uid, currentMonthTag.value, meterConfig.value!);
    }
  }

  Future<void> _fetchLastReadings(String uid, String monthTag, MeterConfig config) async {
    final report = await _firestoreService.getReadingsBeforeOrEqual(uid, monthTag);
    Map<String, double> readings = {};
    if (report != null) {
      final motherReading = (report['currentMotherReading'] ?? 0.0).toDouble();
      readings['Mother'] = motherReading;
      readings[config.mainFlatLabel] = motherReading; // Use Mother reading for Main Flat
      
      final flatsData = report['flats'] as List<dynamic>? ?? [];
      for (var f in flatsData) {
        final flatLabel = f['flatLabel'] as String;
        if (flatLabel != config.mainFlatLabel) {
          readings[flatLabel] = (f['currentReading'] ?? 0.0).toDouble();
        }
      }
    } else {
      readings['Mother'] = config.baselineMotherUnit;
      readings[config.mainFlatLabel] = config.baselineMotherUnit;
      for (var sub in config.subMeters) {
        readings[sub.label] = sub.baselineUnit;
      }
    }
    lastReadingsMap.value = readings;
  }

  List<String> get availableFlats {
    final config = meterConfig.value;
    if (config == null) return [];
    return [
      config.mainFlatLabel,
      ...config.subMeters.map((e) => e.label)
    ];
  }

  double getTotalRechargeForFlat(String flatLabel) {
    return recharges
        .where((r) => r.flat == flatLabel)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalRecharge {
    return recharges.fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> addRecharge({
    required DateTime date,
    required String flat,
    required double amount,
    required String targetMonthTag,
    String? note,
  }) async {
    final uid = _authService.firebaseUser.value?.uid;
    if (uid == null) return;

    final entry = RechargeEntry(
      date: date,
      flat: flat,
      amount: amount,
      note: note,
    );
    await _firestoreService.addRecharge(uid, entry, targetMonthTag);
  }
}
