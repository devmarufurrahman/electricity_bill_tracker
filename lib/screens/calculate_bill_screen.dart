import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bill_calculation_controller.dart';
import '../controllers/home_controller.dart';
import '../models/bill_calculation.dart';

class CalculateBillScreen extends StatelessWidget {
  CalculateBillScreen({super.key});

  final BillCalculationController _controller = Get.put(BillCalculationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculate Month-End Bill')),
      body: GetBuilder<BillCalculationController>(
        builder: (_) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInputSection(context),
                const SizedBox(height: 24),
                Obx(() {
                  final result = _controller.calculationResult.value;
                  if (result == null) return const SizedBox.shrink();
                  return _buildResultSection(context, result);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    final config = Get.find<HomeController>().meterConfig.value;
    if (config == null) return const Text('No configuration found.');

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Meter Readings', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            
            TextFormField(
              controller: _controller.currentMotherReadingCtrl,
              decoration: InputDecoration(
                labelText: 'Current Mother Reading',
                helperText: 'Previous: ${_controller.prevMotherReading}',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _controller.totalBillAmountCtrl,
              decoration: const InputDecoration(
                labelText: 'Total Monthly Bill (in BDT)',
                helperText: 'Leave empty to auto-calculate from total deposits',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            ...config.subMeters.map((sub) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextFormField(
                  controller: _controller.subReadingCtrls[sub.label],
                  decoration: InputDecoration(
                    labelText: 'Current Sub Reading (${sub.label})',
                    helperText: 'Previous: ${_controller.prevSubReadings[sub.label] ?? sub.baselineUnit}',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              );
            }).toList(),
            
            ElevatedButton(
              onPressed: _controller.calculateBill,
              child: const Text('Calculate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(BuildContext context, BillCalculation result) {
    return Card(
      color: Colors.blue.shade50,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Calculation Result - ${result.month}', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            
            Text('Total Mother Units: ${result.totalMotherUnits}'),
            Text('Per Unit Rate: ${result.unitRate.toStringAsFixed(2)} BDT'),
            Text('Total Deposit Pool: ${result.totalRecharge} BDT'),
            const SizedBox(height: 16),
            
            ...result.flats.map((flat) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueGrey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(flat.flatLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Units Used: ${flat.unitsUsed}'),
                    Text('Cost: ${flat.cost.toStringAsFixed(2)} BDT'),
                    Text('Recharged: ${flat.rechargedAmount.toStringAsFixed(2)} BDT'),
                    Text(
                      flat.settlementAmount >= 0 
                          ? 'Owes: ${flat.settlementAmount.toStringAsFixed(2)} BDT'
                          : 'Overpaid: ${flat.settlementAmount.abs().toStringAsFixed(2)} BDT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: flat.settlementAmount > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 24),
            Obx(() {
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _controller.isSaving.value ? null : _controller.saveAndGeneratePdf,
                icon: _controller.isSaving.value 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_controller.isSaving.value ? 'Saving & Uploading...' : 'Save & Generate PDF'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
