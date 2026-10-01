class FlatCalculation {
  final String flatLabel;
  final double previousReading; // 0 for main flat
  final double currentReading;  // 0 for main flat
  final double unitsUsed;
  final double cost;
  final double rechargedAmount;
  final double settlementAmount;

  FlatCalculation({
    required this.flatLabel,
    required this.previousReading,
    required this.currentReading,
    required this.unitsUsed,
    required this.cost,
    required this.rechargedAmount,
    required this.settlementAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'flatLabel': flatLabel,
      'previousReading': previousReading,
      'currentReading': currentReading,
      'unitsUsed': unitsUsed,
      'cost': cost,
      'rechargedAmount': rechargedAmount,
      'settlementAmount': settlementAmount,
    };
  }

  factory FlatCalculation.fromMap(Map<String, dynamic> map) {
    return FlatCalculation(
      flatLabel: map['flatLabel'] ?? '',
      previousReading: (map['previousReading'] ?? 0.0).toDouble(),
      currentReading: (map['currentReading'] ?? 0.0).toDouble(),
      unitsUsed: (map['unitsUsed'] ?? 0.0).toDouble(),
      cost: (map['cost'] ?? 0.0).toDouble(),
      rechargedAmount: (map['rechargedAmount'] ?? 0.0).toDouble(),
      settlementAmount: (map['settlementAmount'] ?? 0.0).toDouble(),
    );
  }
}

class BillCalculation {
  final String month;
  final double previousMotherReading;
  final double currentMotherReading;
  final double totalMotherUnits;
  
  final double totalRecharge;
  final double unitRate;

  final List<FlatCalculation> flats;

  BillCalculation({
    required this.month,
    required this.previousMotherReading,
    required this.currentMotherReading,
    required this.totalMotherUnits,
    required this.totalRecharge,
    required this.unitRate,
    required this.flats,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'previousMotherReading': previousMotherReading,
      'currentMotherReading': currentMotherReading,
      'totalMotherUnits': totalMotherUnits,
      'totalRecharge': totalRecharge,
      'unitRate': unitRate,
      'flats': flats.map((x) => x.toMap()).toList(),
    };
  }

  factory BillCalculation.fromMap(Map<String, dynamic> map) {
    return BillCalculation(
      month: map['month'] ?? '',
      previousMotherReading: (map['previousMotherReading'] ?? 0.0).toDouble(),
      currentMotherReading: (map['currentMotherReading'] ?? 0.0).toDouble(),
      totalMotherUnits: (map['totalMotherUnits'] ?? 0.0).toDouble(),
      totalRecharge: (map['totalRecharge'] ?? 0.0).toDouble(),
      unitRate: (map['unitRate'] ?? 0.0).toDouble(),
      flats: List<FlatCalculation>.from(
        (map['flats'] ?? []).map((x) => FlatCalculation.fromMap(Map<String, dynamic>.from(x))),
      ),
    );
  }
}
