import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../models/bill_calculation.dart';
import 'pdf_viewer_screen.dart';

class ReportsScreen extends StatelessWidget {
  ReportsScreen({super.key});

  final ReportsController _controller = Get.put(ReportsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Bill Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller.onInit,
          )
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.reports.isEmpty) {
          return const Center(child: Text('No reports generated yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.reports.length,
          itemBuilder: (context, index) {
            final reportData = _controller.reports[index];
            final calculation = BillCalculation.fromMap(reportData);
            final driveUrl = reportData['driveUrl'] as String?;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ExpansionTile(
                leading: const Icon(Icons.receipt_long, color: Colors.blue),
                title: Text('Bill Report: ${calculation.month}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Total Units: ${calculation.totalMotherUnits} | Rate: ${calculation.unitRate.toStringAsFixed(2)}'),
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...calculation.flats.map((flat) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(flat.flatLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('${flat.cost.toStringAsFixed(2)} BDT'),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800, 
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Get.to(() => PdfViewerScreen(calculation: calculation)),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('View PDF Invoice'),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
