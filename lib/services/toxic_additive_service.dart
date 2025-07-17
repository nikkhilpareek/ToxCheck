import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/toxic_additive.dart';
import '../models/product.dart';

class ToxicAdditiveService {
  static Map<String, ToxicAdditive>? _toxicAdditives;

  // Load toxic additives from local JSON file
  Future<Map<String, ToxicAdditive>> loadToxicAdditives() async {
    if (_toxicAdditives != null) {
      return _toxicAdditives!;
    }

    try {
      final data = await rootBundle.loadString('assets/data/toxic_additives.json');
      final Map<String, dynamic> jsonData = json.decode(data);
      
      _toxicAdditives = {};
      jsonData.forEach((key, value) {
        _toxicAdditives![key] = ToxicAdditive.fromJson(value);
      });
      
      return _toxicAdditives!;
    } catch (e) {
      print('Error loading toxic additives: $e');
      return {};
    }
  }

  // Check if an additive is toxic
  Future<ToxicAdditive?> getToxicAdditiveInfo(String additiveTag) async {
    final toxicAdditives = await loadToxicAdditives();
    return toxicAdditives[additiveTag.toLowerCase()];
  }

  // Analyze product for toxic additives
  Future<ProductAnalysis> analyzeProduct(Product product) async {
    final toxicAdditives = await loadToxicAdditives();
    
    List<ToxicAdditive> foundToxicAdditives = [];
    List<String> harmfulTags = [];
    
    if (product.additivesTags != null) {
      for (String additiveTag in product.additivesTags!) {
        final toxicAdditive = toxicAdditives[additiveTag.toLowerCase()];
        if (toxicAdditive != null) {
          foundToxicAdditives.add(toxicAdditive);
          harmfulTags.add(additiveTag);
        }
      }
    }

    // Determine overall safety status
    String status = _determineSafetyStatus(foundToxicAdditives);
    double safetyScore = _calculateSafetyScore(foundToxicAdditives, product);

    return ProductAnalysis(
      product: product,
      toxicAdditives: foundToxicAdditives,
      harmfulTags: harmfulTags,
      status: status,
      safetyScore: safetyScore,
      totalAdditives: product.additivesTags?.length ?? 0,
      harmfulAdditives: foundToxicAdditives.length,
    );
  }

  // Determine safety status based on toxic additives found
  String _determineSafetyStatus(List<ToxicAdditive> toxicAdditives) {
    if (toxicAdditives.isEmpty) {
      return 'safe';
    }

    bool hasHighRisk = toxicAdditives.any((additive) => additive.isHighRisk);
    bool hasMediumRisk = toxicAdditives.any((additive) => additive.isMediumRisk);

    if (hasHighRisk) {
      return 'warning';
    } else if (hasMediumRisk || toxicAdditives.length > 2) {
      return 'caution';
    } else {
      return 'caution';
    }
  }

  // Calculate safety score (0-10, higher is safer)
  double _calculateSafetyScore(List<ToxicAdditive> toxicAdditives, Product product) {
    double baseScore = 10.0;
    
    // Deduct points for toxic additives
    for (ToxicAdditive additive in toxicAdditives) {
      switch (additive.severity) {
        case 'high':
          baseScore -= 3.0;
          break;
        case 'medium':
          baseScore -= 2.0;
          break;
        case 'low':
          baseScore -= 1.0;
          break;
      }
    }

    // Consider NOVA group (higher NOVA group = more processed = lower score)
    if (product.novaGroup != null) {
      switch (product.novaGroup!) {
        case 4:
          baseScore -= 1.5;
          break;
        case 3:
          baseScore -= 1.0;
          break;
        case 2:
          baseScore -= 0.5;
          break;
      }
    }

    // Consider nutrition grade
    if (product.nutritionGrade != 'N/A') {
      switch (product.nutritionGrade.toLowerCase()) {
        case 'd':
          baseScore -= 1.0;
          break;
        case 'e':
          baseScore -= 1.5;
          break;
      }
    }

    return (baseScore < 0) ? 0.0 : baseScore;
  }

  // Get all toxic additives for reference
  Future<List<ToxicAdditive>> getAllToxicAdditives() async {
    final toxicAdditives = await loadToxicAdditives();
    return toxicAdditives.values.toList();
  }
}

// Product analysis result class
class ProductAnalysis {
  final Product product;
  final List<ToxicAdditive> toxicAdditives;
  final List<String> harmfulTags;
  final String status; // 'safe', 'caution', 'warning'
  final double safetyScore; // 0-10
  final int totalAdditives;
  final int harmfulAdditives;

  ProductAnalysis({
    required this.product,
    required this.toxicAdditives,
    required this.harmfulTags,
    required this.status,
    required this.safetyScore,
    required this.totalAdditives,
    required this.harmfulAdditives,
  });

  bool get isSafe => status == 'safe';
  bool get isCaution => status == 'caution';
  bool get isWarning => status == 'warning';
  
  String get safetyGrade {
    if (safetyScore >= 8.5) return 'A';
    if (safetyScore >= 7.0) return 'B';
    if (safetyScore >= 5.5) return 'C';
    if (safetyScore >= 4.0) return 'D';
    return 'E';
  }
}
