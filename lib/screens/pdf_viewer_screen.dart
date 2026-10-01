import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../models/bill_calculation.dart';
import '../services/pdf_invoice_service.dart';

class PdfViewerScreen extends StatelessWidget {
  final BillCalculation calculation;
  
  PdfViewerScreen({super.key, required this.calculation});

  final PdfInvoiceService _pdfService = Get.find<PdfInvoiceService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice: ${calculation.month}'),
      ),
      body: PdfPreview(
        build: (format) => _pdfService.generateInvoice(calculation),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
