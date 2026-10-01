import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/home_controller.dart';
import 'calculate_bill_screen.dart';
import 'ledger_screen.dart';
import 'reports_screen.dart';
import 'meter_profile_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController _controller = Get.put(HomeController());

  void _showAddRechargeDialog(BuildContext context) {
    if (_controller.availableFlats.isEmpty) {
      Get.snackbar('Error', 'No flats configured');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedFlat = _controller.availableFlats.first;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Add Recharge', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedFlat,
                      decoration: const InputDecoration(labelText: 'Flat', border: OutlineInputBorder()),
                      items: _controller.availableFlats.map((flat) {
                        return DropdownMenuItem(value: flat, child: Text(flat));
                      }).toList(),
                      onChanged: (value) => setState(() => selectedFlat = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Amount (BDT)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please enter amount';
                        if (double.tryParse(val) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: 'Note (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('Date Paid: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => selectedDate = date);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Adding to Bill Month: ${_controller.currentMonthTag.value}',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await _controller.addRecharge(
                            date: selectedDate,
                            flat: selectedFlat,
                            amount: double.parse(amountCtrl.text),
                            targetMonthTag: _controller.currentMonthTag.value,
                            note: noteCtrl.text,
                          );
                          Get.back();
                        }
                      },
                      child: const Text('Save Recharge'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electricity Bill Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'View Past Bill Reports',
            onPressed: () => Get.to(() => ReportsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            tooltip: 'View All Balances (Ledger)',
            onPressed: () => Get.to(() => LedgerScreen()),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Get.to(() => MeterProfileScreen());
              } else if (value == 'logout') {
                Get.find<AuthService>().signOut();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.blue),
                  title: Text('Profiles & Config'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          )
        ],
      ),
      body: Obx(() {
        if (_controller.meterConfig.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildSummaryCard(context),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent Recharges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            Expanded(
              child: _controller.recharges.isEmpty
                  ? const Center(child: Text('No recharges this month.'))
                  : ListView.builder(
                      itemCount: _controller.recharges.length,
                      itemBuilder: (context, index) {
                        final r = _controller.recharges[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(r.flat, style: const TextStyle(fontSize: 12)),
                          ),
                          title: Text('${r.amount} BDT'),
                          subtitle: Text('${DateFormat('yyyy-MM-dd').format(r.date)} ${r.note != null && r.note!.isNotEmpty ? " - ${r.note}" : ""}'),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRechargeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Recharge'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.to(() => CalculateBillScreen()),
            child: const Text('Calculate Month-End Bill', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Month: ${_controller.currentMonthTag.value}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit_calendar, color: Colors.blue),
                  onPressed: () async {
                    try {
                      final currentParsed = DateFormat('yyyy-MM').parse(_controller.currentMonthTag.value);
                      final date = await showDatePicker(
                        context: context,
                        initialDate: currentParsed,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        _controller.changeMonth(DateFormat('yyyy-MM').format(date));
                      }
                    } catch (e) {
                      // fallback if parsing fails
                    }
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceAround,
              children: _controller.availableFlats.map((flat) {
                return Column(
                  children: [
                    Text('$flat Deposited', style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
                    const SizedBox(height: 4),
                    Text('${_controller.getTotalRechargeForFlat(flat)} BDT', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Last Reading: ${_controller.lastReadingsMap[flat] ?? 0.0}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Recharge: ${_controller.totalRecharge} BDT', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Mother Reading: ${_controller.lastReadingsMap["Mother"] ?? 0.0}', style: const TextStyle(fontSize: 14, color: Colors.brown)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
