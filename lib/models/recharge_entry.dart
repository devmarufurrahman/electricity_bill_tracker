import 'package:cloud_firestore/cloud_firestore.dart';

class RechargeEntry {
  final String? id;
  final DateTime date;
  final String flat; // "2/D" or "9/A"
  final double amount;
  final String? note;
  final String? monthTag;

  RechargeEntry({
    this.id,
    required this.date,
    required this.flat,
    required this.amount,
    this.note,
    this.monthTag,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'flat': flat,
      'amount': amount,
      'note': note,
      'monthTag': monthTag,
    };
  }

  factory RechargeEntry.fromMap(Map<String, dynamic> map, String id) {
    return RechargeEntry(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      flat: map['flat'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      note: map['note'],
      monthTag: map['monthTag'],
    );
  }
}
