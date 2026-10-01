import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/edit_meter_profile_controller.dart';
import '../models/meter_config.dart';
import '../controllers/home_controller.dart';

class EditMeterProfileScreen extends StatelessWidget {
  EditMeterProfileScreen({super.key});

  final EditMeterProfileController _controller = Get.put(EditMeterProfileController());
  final HomeController _homeController = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tenant Profiles'),
      ),
      body: Obx(() {
        if (_controller.isSaving.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final config = _homeController.meterConfig.value;
        if (config == null) return const Center(child: Text('No configuration'));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMainFlatEditSection(config),
            const SizedBox(height: 24),
            const Text(
              'Sub-Meter Tenants',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...List.generate(config.subMeters.length, (index) {
              return _buildSubMeterEditSection(index);
            }),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: _controller.saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Save Profiles', style: TextStyle(fontSize: 18)),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMainFlatEditSection(MeterConfig config) {
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
                const Icon(Icons.home, color: Colors.green),
                const SizedBox(width: 8),
                Text('Main Flat (${config.mainFlatLabel})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller.mainTenantNameCtrl,
              decoration: const InputDecoration(labelText: 'Tenant Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.mainTenantContactCtrl,
              decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller.mainTenantEmailCtrl,
              decoration: const InputDecoration(labelText: 'Linked Gmail', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMeterEditSection(int index) {
    final ctrls = _controller.subMeterCtrls[index];
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.door_front_door, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: ctrls['label'],
                    decoration: const InputDecoration(labelText: 'Flat Label', isDense: true),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: ctrls['tenantName'],
              decoration: const InputDecoration(labelText: 'Tenant Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctrls['tenantContact'],
              decoration: const InputDecoration(labelText: 'Contact Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctrls['tenantEmail'],
              decoration: const InputDecoration(labelText: 'Linked Gmail', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }
}
