import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/bill_calculation.dart';
import '../models/recharge_entry.dart';
import '../models/meter_config.dart';
import 'package:intl/intl.dart';

class FirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MeterConfig?> getMeterConfig(String uid) async {
    try {
      final doc = await _firestore.doc('users/$uid/settings/meter_config').get();
      if (doc.exists && doc.data() != null) {
        return MeterConfig.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      developer.log('Error getting meter config: $e', name: 'FirestoreService');
      return null;
    }
  }

  Future<void> saveMeterConfig(String uid, MeterConfig config) async {
    final batch = _firestore.batch();
    
    batch.set(_firestore.doc('users/$uid/settings/meter_config'), config.toMap());
    
    // Also save basic user profile marker
    batch.set(_firestore.doc('users/$uid'), {
      'updatedAt': FieldValue.serverTimestamp(),
      'driveFolderId': config.driveFolderId,
    }, SetOptions(merge: true));

    // Save tenant links
    for (var sm in config.subMeters) {
      if (sm.tenantEmail != null && sm.tenantEmail!.isNotEmpty) {
        final email = sm.tenantEmail!.toLowerCase().trim();
        batch.set(_firestore.collection('tenant_links').doc(email), {
          'managerUid': uid,
          'flatLabel': sm.label,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  Future<Map<String, dynamic>?> getTenantLink(String email) async {
    try {
      final doc = await _firestore.collection('tenant_links').doc(email.toLowerCase().trim()).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      developer.log('Error getting tenant link: $e', name: 'FirestoreService');
      return null;
    }
  }

  Stream<List<RechargeEntry>> streamRechargesForMonth(String uid, String monthTag) {
    return _firestore
        .collection('users/$uid/recharges')
        .where('monthTag', isEqualTo: monthTag)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => RechargeEntry.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<void> addRecharge(String uid, RechargeEntry entry, String targetMonthTag) async {
    final data = entry.toMap();
    data['monthTag'] = targetMonthTag;

    await _firestore.collection('users/$uid/recharges').add(data);
  }

  Future<Map<String, dynamic>?> getLastReadings(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users/$uid/reports')
          .orderBy('month', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      developer.log('Error getting last readings: $e', name: 'FirestoreService');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getReadingsBeforeOrEqual(String uid, String monthTag) async {
    try {
      final snapshot = await _firestore
          .collection('users/$uid/reports')
          .where('month', isLessThanOrEqualTo: monthTag)
          .orderBy('month', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      developer.log('Error getting readings before or equal: $e', name: 'FirestoreService');
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllRecharges(String uid) async {
    final snapshot = await _firestore.collection('users/$uid/recharges').get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getAllReports(String uid) async {
    final snapshot = await _firestore.collection('users/$uid/reports').get();
    return snapshot.docs;
  }

  Future<void> saveMonthlyReport({
    required String uid,
    required BillCalculation calculation,
    required String driveUrl,
  }) async {
    final data = calculation.toMap();
    data['driveUrl'] = driveUrl;
    data['createdAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('users/$uid/reports')
        .doc(calculation.month)
        .set(data, SetOptions(merge: true));
  }
}
