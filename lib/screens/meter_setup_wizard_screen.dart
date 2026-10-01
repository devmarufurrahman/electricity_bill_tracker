import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/meter_setup_controller.dart';
import '../services/auth_service.dart';

class MeterSetupWizardScreen extends StatelessWidget {
  MeterSetupWizardScreen({super.key});

  final MeterSetupController _controller = Get.put(MeterSetupController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First-time Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<AuthService>().signOut(),
          )
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving configuration & creating Google Drive folder...'),
              ],
            ),
          );
        }
        return Form(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildMainMeterSection(context),
              const SizedBox(height: 24),
              _buildSubMetersSection(context),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _controller.saveConfig,
                icon: const Icon(Icons.check_circle),
                label: const Text('Complete Setup', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMainMeterSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Main Electricity Account', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Starting Month:', style: TextStyle(fontSize: 16)),
                Obx(() => TextButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _controller.startDate.value.month == DateTime.now().month && _controller.startDate.value.year == DateTime.now().year 
                            ? 'Current Month' 
                            : '${_controller.startDate.value.month}/${_controller.startDate.value.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () => _controller.pickStartDate(context),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _controller.accountNumCtrl,
              decoration: const InputDecoration(labelText: 'Consumer / Account Number *', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller.mainMeterNumCtrl,
              decoration: const InputDecoration(labelText: 'Main (Mother) Meter Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller.baselineMotherCtrl,
              decoration: const InputDecoration(labelText: 'Baseline Starting Unit *', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller.mainFlatLabelCtrl,
              decoration: const InputDecoration(labelText: 'Main Flat Identifier (e.g. 2/D)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller.mainTenantNameCtrl,
              decoration: const InputDecoration(labelText: 'Main Flat Tenant Name (Optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller.mainTenantContactCtrl,
              decoration: const InputDecoration(labelText: 'Main Flat Contact (Optional)', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller.mainTenantEmailCtrl,
              decoration: const InputDecoration(
                  labelText: 'Main Flat Gmail (Optional)', 
                  border: OutlineInputBorder(),
                  hintText: 'Leave empty to use your own logged-in Gmail',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubMetersSection(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sub-Meters Configuration', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                  onPressed: _controller.addSubMeter,
                ),
              ],
            ),
            const Divider(),
            Obx(() {
              if (_controller.subMetersData.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No sub-meters added. Add at least one if applicable.', style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.subMetersData.length,
                itemBuilder: (context, index) {
                  final data = _controller.subMetersData[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sub-Meter ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _controller.removeSubMeter(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: data['label'],
                          decoration: const InputDecoration(labelText: 'Label/Flat (e.g. 9/A) *', isDense: true),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: data['baselineUnit'],
                          decoration: const InputDecoration(labelText: 'Baseline Unit *', isDense: true),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: data['tenantName'],
                          decoration: const InputDecoration(labelText: 'Tenant Name', isDense: true),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: data['tenantContact'],
                          decoration: const InputDecoration(labelText: 'Tenant Contact Number', isDense: true),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: data['tenantEmail'],
                          decoration: const InputDecoration(labelText: 'Tenant Gmail (For auto-login)', isDense: true),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
