import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../controllers/tenant_home_controller.dart';

class TenantHomeScreen extends StatelessWidget {
  final String managerUid;
  final String flatLabel;

  const TenantHomeScreen({
    super.key,
    required this.managerUid,
    required this.flatLabel,
  });

  @override
  Widget build(BuildContext context) {
    final TenantHomeController controller = Get.put(TenantHomeController(managerUid: managerUid, flatLabel: flatLabel));

    return Scaffold(
      appBar: AppBar(
        title: Text('Flat $flatLabel Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.onInit,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<AuthService>().signOut(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async => controller.onInit(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildBalanceCard(controller),
              const SizedBox(height: 24),
              const Text('Monthly Bills', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              _buildBillsList(controller),
              const SizedBox(height: 24),
              const Text('Deposit History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              _buildRechargesList(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBalanceCard(TenantHomeController controller) {
    final balance = controller.balance.value;
    final isAdvance = balance >= 0;
    final absBal = balance.abs().toStringAsFixed(2);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isAdvance ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              isAdvance ? 'Advance Balance' : 'Current Due',
              style: TextStyle(
                fontSize: 18,
                color: isAdvance ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$absBal BDT',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: isAdvance ? Colors.green.shade900 : Colors.red.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsList(TenantHomeController controller) {
    if (controller.myBills.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No bills found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.myBills.length,
      itemBuilder: (context, index) {
        final bill = controller.myBills[index];
        final cost = (bill['cost'] as double).toStringAsFixed(2);
        final units = (bill['unitsUsed'] as double).toStringAsFixed(1);
        final driveUrl = bill['driveUrl'] as String?;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.blue),
            title: Text('Month: ${bill['month']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Usage: $units Units | Bill: $cost BDT'),
            trailing: driveUrl != null && driveUrl.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    onPressed: () => controller.openReport(driveUrl),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildRechargesList(TenantHomeController controller) {
    if (controller.myRecharges.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No deposits found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.myRecharges.length,
      itemBuilder: (context, index) {
        final entry = controller.myRecharges[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.payments, color: Colors.green),
            title: Text('${entry.amount.toStringAsFixed(2)} BDT', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('Paid on: ${DateFormat('dd MMM yyyy').format(entry.date)}\nFor: ${entry.monthTag}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
