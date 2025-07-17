import '../models/product.dart';
import '../services/product_service.dart';
import '../services/toxic_additive_service.dart';

class ComparisonService {
  final ProductService _productService = ProductService();
  final ToxicAdditiveService _toxicAdditiveService = ToxicAdditiveService();

  // Compare two products by barcode
  Future<ProductComparison?> compareProducts(String barcode1, String barcode2) async {
    try {
      final product1 = await _productService.fetchProduct(barcode1);
      final product2 = await _productService.fetchProduct(barcode2);

      if (product1 == null || product2 == null) {
        return null;
      }

      final analysis1 = await _toxicAdditiveService.analyzeProduct(product1);
      final analysis2 = await _toxicAdditiveService.analyzeProduct(product2);

      return ProductComparison(
        product1: product1,
        product2: product2,
        analysis1: analysis1,
        analysis2: analysis2,
      );
    } catch (e) {
      print('Error comparing products: $e');
      return null;
    }
  }

  // Compare list of products and find the best one
  Future<Product?> findBestProduct(List<String> barcodes) async {
    try {
      List<ProductAnalysis> analyses = [];

      for (String barcode in barcodes) {
        final product = await _productService.fetchProduct(barcode);
        if (product != null) {
          final analysis = await _toxicAdditiveService.analyzeProduct(product);
          analyses.add(analysis);
        }
      }

      if (analyses.isEmpty) return null;

      // Sort by safety score (highest first)
      analyses.sort((a, b) => b.safetyScore.compareTo(a.safetyScore));
      
      return analyses.first.product;
    } catch (e) {
      print('Error finding best product: $e');
      return null;
    }
  }
}

class ProductComparison {
  final Product product1;
  final Product product2;
  final ProductAnalysis analysis1;
  final ProductAnalysis analysis2;

  ProductComparison({
    required this.product1,
    required this.product2,
    required this.analysis1,
    required this.analysis2,
  });

  // Determine which product is safer
  Product get saferProduct {
    if (analysis1.safetyScore > analysis2.safetyScore) {
      return product1;
    } else if (analysis2.safetyScore > analysis1.safetyScore) {
      return product2;
    } else {
      // If scores are equal, prefer the one with fewer harmful additives
      return analysis1.harmfulAdditives <= analysis2.harmfulAdditives 
          ? product1 
          : product2;
    }
  }

  // Get comparison summary
  Map<String, dynamic> getComparisonSummary() {
    final winner = saferProduct;
    final winnerAnalysis = winner == product1 ? analysis1 : analysis2;
    final loserAnalysis = winner == product1 ? analysis2 : analysis1;

    List<String> reasons = [];

    // Compare safety scores
    if (winnerAnalysis.safetyScore > loserAnalysis.safetyScore) {
      reasons.add('Higher safety score (${winnerAnalysis.safetyScore.toStringAsFixed(1)} vs ${loserAnalysis.safetyScore.toStringAsFixed(1)})');
    }

    // Compare harmful additives
    if (winnerAnalysis.harmfulAdditives < loserAnalysis.harmfulAdditives) {
      reasons.add('Fewer harmful additives (${winnerAnalysis.harmfulAdditives} vs ${loserAnalysis.harmfulAdditives})');
    }

    // Compare nutrition grades
    if (winnerAnalysis.product.nutritionGrade != 'N/A' && 
        loserAnalysis.product.nutritionGrade != 'N/A') {
      final winnerGradeValue = _getGradeValue(winnerAnalysis.product.nutritionGrade);
      final loserGradeValue = _getGradeValue(loserAnalysis.product.nutritionGrade);
      
      if (winnerGradeValue < loserGradeValue) {
        reasons.add('Better nutrition grade (${winnerAnalysis.product.nutritionGrade} vs ${loserAnalysis.product.nutritionGrade})');
      }
    }

    // Compare NOVA groups
    if (winnerAnalysis.product.novaGroup != null && 
        loserAnalysis.product.novaGroup != null) {
      if (winnerAnalysis.product.novaGroup! < loserAnalysis.product.novaGroup!) {
        reasons.add('Less processed food (NOVA ${winnerAnalysis.product.novaGroup} vs ${loserAnalysis.product.novaGroup})');
      }
    }

    if (reasons.isEmpty) {
      reasons.add('Similar safety profiles');
    }

    return {
      'winner': winner.displayName,
      'reasons': reasons,
      'scoreDifference': (winnerAnalysis.safetyScore - loserAnalysis.safetyScore).abs(),
    };
  }

  // Convert grade letter to numeric value for comparison
  int _getGradeValue(String grade) {
    switch (grade.toLowerCase()) {
      case 'a': return 1;
      case 'b': return 2;
      case 'c': return 3;
      case 'd': return 4;
      case 'e': return 5;
      default: return 6;
    }
  }

  // Get detailed comparison data
  Map<String, dynamic> getDetailedComparison() {
    return {
      'product1': {
        'name': product1.displayName,
        'safetyScore': analysis1.safetyScore,
        'safetyGrade': analysis1.safetyGrade,
        'status': analysis1.status,
        'harmfulAdditives': analysis1.harmfulAdditives,
        'totalAdditives': analysis1.totalAdditives,
        'nutritionGrade': product1.nutritionGrade,
        'novaGroup': product1.novaGroup,
        'toxicAdditives': analysis1.toxicAdditives.map((a) => a.name).toList(),
      },
      'product2': {
        'name': product2.displayName,
        'safetyScore': analysis2.safetyScore,
        'safetyGrade': analysis2.safetyGrade,
        'status': analysis2.status,
        'harmfulAdditives': analysis2.harmfulAdditives,
        'totalAdditives': analysis2.totalAdditives,
        'nutritionGrade': product2.nutritionGrade,
        'novaGroup': product2.novaGroup,
        'toxicAdditives': analysis2.toxicAdditives.map((a) => a.name).toList(),
      },
      'summary': getComparisonSummary(),
    };
  }
}
