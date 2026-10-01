import 'package:cloud_firestore/cloud_firestore.dart';

class SubMeterConfig {
  final String label;
  final double baselineUnit;
  final String? serialNumber;
  final String? tenantName;
  final String? tenantContact;
  final String? tenantEmail;

  SubMeterConfig({
    required this.label,
    required this.baselineUnit,
    this.serialNumber,
    this.tenantName,
    this.tenantContact,
    this.tenantEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'baselineUnit': baselineUnit,
      'serialNumber': serialNumber,
      'tenantName': tenantName,
      'tenantContact': tenantContact,
      'tenantEmail': tenantEmail,
    };
  }

  factory SubMeterConfig.fromMap(Map<String, dynamic> map) {
    return SubMeterConfig(
      label: map['label'] ?? '',
      baselineUnit: (map['baselineUnit'] ?? 0.0).toDouble(),
      serialNumber: map['serialNumber'],
      tenantName: map['tenantName'],
      tenantContact: map['tenantContact'],
      tenantEmail: map['tenantEmail'],
    );
  }
}

class MeterConfig {
  final String accountNumber;
  final String? mainMeterNumber;
  final double baselineMotherUnit;
  final String startMonthYear;
  final String mainFlatLabel;
  final String? mainTenantName;
  final String? mainTenantContact;
  final String? mainTenantEmail;
  final List<SubMeterConfig> subMeters;
  final String? driveFolderId;

  MeterConfig({
    required this.accountNumber,
    this.mainMeterNumber,
    required this.baselineMotherUnit,
    required this.startMonthYear,
    required this.mainFlatLabel,
    this.mainTenantName,
    this.mainTenantContact,
    this.mainTenantEmail,
    required this.subMeters,
    this.driveFolderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'accountNumber': accountNumber,
      'mainMeterNumber': mainMeterNumber,
      'baselineMotherUnit': baselineMotherUnit,
      'startMonthYear': startMonthYear,
      'mainFlatLabel': mainFlatLabel,
      'mainTenantName': mainTenantName,
      'mainTenantContact': mainTenantContact,
      'mainTenantEmail': mainTenantEmail,
      'subMeters': subMeters.map((x) => x.toMap()).toList(),
      'driveFolderId': driveFolderId,
    };
  }

  factory MeterConfig.fromMap(Map<String, dynamic> map) {
    return MeterConfig(
      accountNumber: map['accountNumber'] ?? '',
      mainMeterNumber: map['mainMeterNumber'],
      baselineMotherUnit: (map['baselineMotherUnit'] ?? 0.0).toDouble(),
      startMonthYear: map['startMonthYear'] ?? '',
      mainFlatLabel: map['mainFlatLabel'] ?? 'Main',
      mainTenantName: map['mainTenantName'],
      mainTenantContact: map['mainTenantContact'],
      mainTenantEmail: map['mainTenantEmail'],
      subMeters: List<SubMeterConfig>.from(
        (map['subMeters'] ?? []).map((x) => SubMeterConfig.fromMap(Map<String, dynamic>.from(x))),
      ),
      driveFolderId: map['driveFolderId'],
    );
  }
}
