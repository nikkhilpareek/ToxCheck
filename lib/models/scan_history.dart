import 'package:hive/hive.dart';

part 'scan_history.g.dart';

@HiveType(typeId: 0)
class ScanHistory extends HiveObject {
  @HiveField(0)
  final String productName;

  @HiveField(1)
  final String barcode;

  @HiveField(2)
  final DateTime dateTime;

  @HiveField(3)
  final List<String> additiveRisks;

  @HiveField(4)
  final String status; // 'safe', 'warning', 'caution'

  @HiveField(5)
  final String? imageUrl;

  @HiveField(6)
  final double? nutritionGrade;

  @HiveField(7)
  final int? novaGroup;

  ScanHistory({
    required this.productName,
    required this.barcode,
    required this.dateTime,
    required this.additiveRisks,
    required this.status,
    this.imageUrl,
    this.nutritionGrade,
    this.novaGroup,
  });

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'barcode': barcode,
      'dateTime': dateTime.toIso8601String(),
      'additiveRisks': additiveRisks,
      'status': status,
      'imageUrl': imageUrl,
      'nutritionGrade': nutritionGrade,
      'novaGroup': novaGroup,
    };
  }

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      productName: json['productName'] ?? '',
      barcode: json['barcode'] ?? '',
      dateTime: DateTime.parse(json['dateTime']),
      additiveRisks: List<String>.from(json['additiveRisks'] ?? []),
      status: json['status'] ?? 'safe',
      imageUrl: json['imageUrl'],
      nutritionGrade: json['nutritionGrade']?.toDouble(),
      novaGroup: json['novaGroup'],
    );
  }
}
