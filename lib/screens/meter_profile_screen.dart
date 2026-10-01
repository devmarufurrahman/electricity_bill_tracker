import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../models/meter_config.dart';
import 'edit_meter_profile_screen.dart';

class MeterProfileScreen extends StatelessWidget {
  MeterProfileScreen({super.key});

  final HomeController _homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meter & Flat Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Tenant Profiles',
            onPressed: () => Get.to(() => EditMeterProfileScreen()),
          ),
        ],
      ),
      body: Obx(() {
        final config = _homeController.meterConfig.value;
        if (config == null) {
          return const Center(child: Text('No configuration found.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMotherMeterProfile(config),
            const SizedBox(height: 16),
            _buildMainFlatProfile(config),
            const SizedBox(height: 16),
            const Text(
              'Sub-Meter Profiles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...config.subMeters.map((sub) => _buildSubMeterProfile(sub)),
          ],
        );
      }),
    );
  }

  Widget _buildMotherMeterProfile(MeterConfig config) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.electrical_services, size: 28, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Mother Meter Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _buildInfoRow('Account Number', config.accountNumber),
            if (config.mainMeterNumber != null && config.mainMeterNumber!.isNotEmpty)
              _buildInfoRow('Meter Number', config.mainMeterNumber!),
            _buildInfoRow('Baseline Starting Unit', config.baselineMotherUnit.toString()),
            _buildInfoRow('Setup Started On', config.startMonthYear),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFlatProfile(MeterConfig config) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home, size: 28, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Main Flat Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _buildInfoRow('Flat Identifier', config.mainFlatLabel),
            _buildInfoRow('Tenant Name', config.mainTenantName ?? 'Not provided'),
            _buildInfoRow('Contact Number', config.mainTenantContact ?? 'Not provided'),
            _buildInfoRow('Linked Email', config.mainTenantEmail ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMeterProfile(SubMeterConfig sub) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.door_front_door, size: 24, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Flat: ${sub.label}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _buildInfoRow('Baseline Unit', sub.baselineUnit.toString()),
            if (sub.serialNumber != null && sub.serialNumber!.isNotEmpty)
              _buildInfoRow('Meter Serial', sub.serialNumber!),
            _buildInfoRow('Tenant Name', sub.tenantName ?? 'Not provided'),
            _buildInfoRow('Contact Number', sub.tenantContact ?? 'Not provided'),
            _buildInfoRow('Linked Email', sub.tenantEmail ?? 'Not provided'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
