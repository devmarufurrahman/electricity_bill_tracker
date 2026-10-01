import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'screens/auth_gate.dart';
import 'services/firestore_service.dart';
import 'services/google_drive_service.dart';
import 'services/pdf_invoice_service.dart';
import 'services/auth_service.dart';
import 'controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Register Services
  Get.put(AuthService());
  Get.put(FirestoreService());
  Get.put(GoogleDriveService());
  Get.put(PdfInvoiceService());
  
  // Register Global Controllers
  Get.put(AuthController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Electricity Bill Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: AuthGate(),
    );
  }
}
