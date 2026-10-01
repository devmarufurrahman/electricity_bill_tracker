import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../controllers/tenant_home_controller.dart';

class TenantHomeScreen extends StatefulWidget {
  final String managerUid;
  final String flatLabel;

  const TenantHomeScreen({
    super.key,
    required this.managerUid,
    required this.flatLabel,
  });

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  int _currentIndex = 0;
  late final TenantHomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(TenantHomeController(managerUid: widget.managerUid, flatLabel: widget.flatLabel));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flat ${widget.flatLabel} Dashboard'),
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

        return IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardTab(),
            _buildBillsTab(),
            _buildDepositsTab(),
          ],
        );
      }),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Bills'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Deposits'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: () async => controller.onInit(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 16),
          _buildManagerContactCard(),
          const SizedBox(height: 16),
          _buildUsageGraph(),
        ],
      ),
    );
  }

  Widget _buildBillsTab() {
    return RefreshIndicator(
      onRefresh: () async => controller.onInit(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Monthly Bills', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(),
          _buildBillsList(),
        ],
      ),
    );
  }

  Widget _buildDepositsTab() {
    return RefreshIndicator(
      onRefresh: () async => controller.onInit(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Deposit History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(),
          _buildRechargesList(),
        ],
      ),
    );
  }

  Widget _buildManagerContactCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(controller.managerName.value.isEmpty ? 'Manager' : controller.managerName.value),
        subtitle: Text(controller.managerPhone.value.isEmpty ? 'Contact unknown' : controller.managerPhone.value),
        trailing: controller.managerPhone.value.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () async {
                  final url = Uri.parse('tel:${controller.managerPhone.value}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
              )
            : null,
      ),
    );
  }

  Widget _buildUsageGraph() {
    if (controller.usageSpots.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Electricity Usage (Last 6 Months)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (controller.usageSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2).clamp(10, double.infinity),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 && value.toInt() < controller.xAxisLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(controller.xAxisLabels[value.toInt()], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: controller.usageSpots.map((spot) {
                    return BarChartGroupData(
                      x: spot.x.toInt(),
                      barRods: [
                        BarChartRodData(
                          toY: spot.y,
                          color: Colors.blue.shade400,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
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

  Widget _buildBillsList() {
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

  Widget _buildRechargesList() {
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
