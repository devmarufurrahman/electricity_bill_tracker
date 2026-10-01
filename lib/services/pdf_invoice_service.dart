import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/bill_calculation.dart';

class PdfInvoiceService {
  Future<Uint8List> generateInvoice(BillCalculation calculation) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(calculation),
            pw.SizedBox(height: 24),
            _buildSummaryTable(calculation),
            pw.SizedBox(height: 24),
            _buildCostBreakdown(calculation),
            pw.SizedBox(height: 24),
            _buildSettlement(calculation),
            pw.Spacer(),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(BillCalculation calc) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ELECTRICITY BILL',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Month: ${calc.month}',
                style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColors.blue100,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Issued On:',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.blue200,
                ),
              ),
              pw.Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryTable(BillCalculation calc) {
    List<List<String>> data = [
      [
        'Mother Meter',
        calc.previousMotherReading.toStringAsFixed(2),
        calc.currentMotherReading.toStringAsFixed(2),
        calc.totalMotherUnits.toStringAsFixed(2),
      ]
    ];

    for (var flat in calc.flats) {
      if (flat.currentReading > 0 || flat.previousReading > 0) {
        data.add([
          'Sub-meter (${flat.flatLabel})',
          flat.previousReading.toStringAsFixed(2),
          flat.currentReading.toStringAsFixed(2),
          flat.unitsUsed.toStringAsFixed(2),
        ]);
      } else {
        data.add([
          'Main Flat (${flat.flatLabel})',
          '-',
          '-',
          flat.unitsUsed.toStringAsFixed(2),
        ]);
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Meter Readings', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: PdfColors.grey300),
            bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          headerHeight: 35,
          cellHeight: 30,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          headers: ['Meter Details', 'Previous Unit', 'Current Unit', 'Total Consumed'],
          data: data,
        ),
      ],
    );
  }

  pw.Widget _buildCostBreakdown(BillCalculation calc) {
    List<List<String>> data = [];
    for (var flat in calc.flats) {
      data.add([
        flat.flatLabel,
        '${flat.unitsUsed.toStringAsFixed(2)} Unit',
        '${flat.cost.toStringAsFixed(2)} BDT',
        '${flat.rechargedAmount.toStringAsFixed(2)} BDT',
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Cost Breakdown', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: PdfColors.orange200),
              ),
              child: pw.Text(
                'Unit Rate: ${calc.unitRate.toStringAsFixed(2)} BDT/Unit',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.orange900),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: PdfColors.grey300),
            bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
          headerHeight: 35,
          cellHeight: 30,
          headers: ['Flat', 'Usage', 'Actual Bill', 'Deposited'],
          data: data,
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Total Mother Meter Bill: ${calc.totalRecharge.toStringAsFixed(2)} BDT',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSettlement(BillCalculation calc) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Final Settlement', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: calc.flats.map((flat) {
            final isDue = flat.settlementAmount > 0;
            final isSettled = flat.settlementAmount == 0;
            final absVal = flat.settlementAmount.abs().toStringAsFixed(2);
            
            final color = isSettled ? PdfColors.grey700 : (isDue ? PdfColors.red700 : PdfColors.green700);
            final bgColor = isSettled ? PdfColors.grey100 : (isDue ? PdfColors.red50 : PdfColors.green50);
            final title = isSettled ? 'CLEAR' : (isDue ? 'DUE (Payable)' : 'ADVANCE (Receivable)');

            return pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: bgColor,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: color, width: 1.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    flat.flatLabel,
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(title, style: pw.TextStyle(fontSize: 12, color: color)),
                  pw.Text('$absVal BDT', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated automatically by Electricity Bill Tracker App',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }
}
