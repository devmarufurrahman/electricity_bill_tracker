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
            _buildQuickActions(context),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Get.to(() => CalculateBillScreen()),
            child: const Text('Calculate Month-End Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionItem(
            context,
            icon: Icons.account_balance_wallet,
            label: 'Ledger',
            color: Colors.orange,
            onTap: () => Get.to(() => LedgerScreen()),
          ),
          _buildActionItem(
            context,
            icon: Icons.receipt_long,
            label: 'Past Bills',
            color: Colors.green,
            onTap: () => Get.to(() => ReportsScreen()),
          ),
          _buildActionItem(
            context,
            icon: Icons.person,
            label: 'Profiles',
            color: Colors.purple,
            onTap: () => Get.to(() => MeterProfileScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Month: ${_controller.currentMonthTag.value}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit_calendar, color: Colors.white70),
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
                      // fallback
                    }
                  },
                ),
              ],
            ),
            const Divider(color: Colors.white30),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceAround,
              children: _controller.availableFlats.map((flat) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(flat, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('${_controller.getTotalRechargeForFlat(flat)} BDT', style: const TextStyle(fontSize: 14, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Last: ${_controller.lastReadingsMap[flat] ?? 0.0}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white30),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Deposited', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${_controller.totalRecharge} BDT', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Mother Reading', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${_controller.lastReadingsMap["Mother"] ?? 0.0}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
