import '../models/meter_config.dart';
import '../models/bill_calculation.dart';

class BillingCalculator {
  /// Calculates the dynamic monthly bill for N sub-meters and the main flat.
  static BillCalculation calculate({
    required MeterConfig config,
    required String month,
    required double prevMotherReading,
    required double currentMotherReading,
    required Map<String, double> prevSubReadings,
    required Map<String, double> currentSubReadings,
    required Map<String, double> rechargesByFlat, // total deposits per flat this month
    required double totalBillAmount,
  }) {
    final totalMotherUnits = currentMotherReading - prevMotherReading;

    double sumOfSubUnits = 0.0;
    List<FlatCalculation> flats = [];

    // 1. Calculate each Sub-meter units
    for (var sub in config.subMeters) {
      final prev = prevSubReadings[sub.label] ?? sub.baselineUnit;
      final current = currentSubReadings[sub.label] ?? prev;
      final units = current - prev;
      sumOfSubUnits += units;
      
      flats.add(FlatCalculation(
        flatLabel: sub.label,
        previousReading: prev,
        currentReading: current,
        unitsUsed: units,
        cost: 0.0, // Calculated later
        rechargedAmount: rechargesByFlat[sub.label] ?? 0.0,
        settlementAmount: 0.0,
      ));
    }

    // 2. Main Flat units
    final mainFlatUnits = totalMotherUnits - sumOfSubUnits;
    
    // 3. Unit rate based on actual total bill amount (cost)
    final unitRate = totalMotherUnits > 0 ? (totalBillAmount / totalMotherUnits) : 0.0;

    // 4. Update Costs & Settlements for Sub-meters
    for (int i = 0; i < flats.length; i++) {
      final cost = flats[i].unitsUsed * unitRate;
      final balance = cost - flats[i].rechargedAmount; // Positive means owes to main, Negative means overpaid
      
      flats[i] = FlatCalculation(
        flatLabel: flats[i].flatLabel,
        previousReading: flats[i].previousReading,
        currentReading: flats[i].currentReading,
        unitsUsed: flats[i].unitsUsed,
        cost: cost,
        rechargedAmount: flats[i].rechargedAmount,
        settlementAmount: balance,
      );
    }

    // 5. Add Main Flat to the List
    final mainCost = mainFlatUnits * unitRate;
    final mainRecharge = rechargesByFlat[config.mainFlatLabel] ?? 0.0;
    
    // Main flat settlement: what it actually owes vs what it paid.
    final mainBalance = mainCost - mainRecharge;

    flats.insert(0, FlatCalculation(
      flatLabel: config.mainFlatLabel,
      previousReading: 0.0, // Main flat doesn't have a direct previous reading typically
      currentReading: 0.0,
      unitsUsed: mainFlatUnits,
      cost: mainCost,
      rechargedAmount: mainRecharge,
      settlementAmount: mainBalance,
    ));

    return BillCalculation(
      month: month,
      previousMotherReading: prevMotherReading,
      currentMotherReading: currentMotherReading,
      totalMotherUnits: totalMotherUnits,
      totalRecharge: totalBillAmount,
      unitRate: unitRate,
      flats: flats,
    );
  }
}
