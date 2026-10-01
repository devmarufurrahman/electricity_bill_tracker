import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ledger_controller.dart';

class LedgerScreen extends StatelessWidget {
  LedgerScreen({super.key});

  final LedgerController _controller = Get.put(LedgerController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overall Balances & Dues'),
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

        if (_controller.flatBalances.isEmpty) {
          return const Center(child: Text('No ledger data found.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.flatBalances.length,
          itemBuilder: (context, index) {
            final flat = _controller.flatBalances.keys.elementAt(index);
            final balance = _controller.flatBalances[flat] ?? 0.0;
            
            final isDue = balance < 0;
            final isAdvance = balance > 0;
            final isSettled = balance == 0;

            Color statusColor = Colors.grey;
            String statusText = 'Settled';

            if (isDue) {
              statusColor = Colors.red;
              statusText = 'Due (Bokeya)';
            } else if (isAdvance) {
              statusColor = Colors.green;
              statusText = 'Advance (Pabe)';
            }

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Text(flat, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                title: Text('$flat Ledger', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w500)),
                trailing: Text(
                  '${balance.abs().toStringAsFixed(2)} BDT', 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  )
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
