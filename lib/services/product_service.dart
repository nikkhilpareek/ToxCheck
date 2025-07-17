import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  static const String baseUrl = 'https://world.openfoodfacts.org';
  
  // Fetch product by barcode
  Future<Product?> fetchProduct(String barcode) async {
    try {
      final url = '$baseUrl/api/v0/product/$barcode.json?lc=en';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 1 && data['product'] != null) {
          final product = Product.fromJson(data['product']);
          // For single product fetch, we're more lenient with language filtering
          // since user specifically scanned this barcode
          if (product.productName != null && product.productName!.trim().isNotEmpty) {
            return product;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  // Search products by name
  Future<List<Product>> searchProducts(String query, {int page = 1, int pageSize = 20}) async {
    try {
      // Handle common brand name variations
      String searchQuery = _normalizeSearchQuery(query);
      
      // Add language parameter and sort by popularity for better results
      final url = '$baseUrl/cgi/search.pl?search_terms=${Uri.encodeComponent(searchQuery)}&json=1&page=$page&page_size=$pageSize&lc=en&sort_by=popularity';
      print('DEBUG: Searching URL: $url');
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['products'] != null) {
          final List<dynamic> productsJson = data['products'];
          print('DEBUG: Found ${productsJson.length} products from API for query: $query (normalized: $searchQuery)');
          
          final allProducts = productsJson.map((json) => Product.fromJson(json)).toList();
          print('DEBUG: Sample products from API:');
          for (int i = 0; i < allProducts.length && i < 3; i++) {
            final product = allProducts[i];
            print('  ${i + 1}: ${product.productName} (Brand: ${product.brands ?? "Unknown"})');
          }
          
          final filteredProducts = allProducts.where((product) => _hasEnglishContent(product)).toList();
          
          print('DEBUG: After filtering, ${filteredProducts.length} products remain');
          
          // If no products after filtering, let's see what was filtered out
          if (filteredProducts.isEmpty && allProducts.isNotEmpty) {
            print('DEBUG: All products were filtered out. Examples:');
            for (int i = 0; i < allProducts.length && i < 5; i++) {
              final product = allProducts[i];
              print('  Filtered: ${product.productName} - Reason: ${_getFilterReason(product)}');
            }
          }
          
          // Sort products by relevance to search query
          _sortProductsByRelevance(filteredProducts, query);
          
          // Debug: Show top 3 results after sorting
          for (int i = 0; i < filteredProducts.length && i < 3; i++) {
            final product = filteredProducts[i];
            print('DEBUG: Top result ${i + 1}: ${product.productName} (Brand: ${product.brands ?? "Unknown"})');
          }
          
          return filteredProducts;
        }
      }
      return [];
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Get popular products by category
  Future<List<Product>> getPopularProducts({String category = '', int pageSize = 10}) async {
    try {
      String url = '$baseUrl/cgi/search.pl?';
      if (category.isNotEmpty) {
        url += 'categories_tags=$category&';
      }
      url += 'sort_by=popularity&json=1&page_size=$pageSize&lc=en';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['products'] != null) {
          final List<dynamic> productsJson = data['products'];
          return productsJson
              .map((json) => Product.fromJson(json))
              .where((product) => _hasEnglishContent(product))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching popular products: $e');
      return [];
    }
  }

  // Check if product exists in database
  Future<bool> productExists(String barcode) async {
    try {
      final product = await fetchProduct(barcode);
      return product != null;
    } catch (e) {
      return false;
    }
  }

  // Normalize search query to handle brand variations
  String _normalizeSearchQuery(String query) {
    final queryLower = query.toLowerCase().trim();
    
    // Handle common brand name variations
    switch (queryLower) {
      case 'lays':
        return "lay's"; // Try with apostrophe first, as it's more common
      case "lay's":
        return "lay's"; // Keep as is
      case 'mcdonalds':
        return "mcdonald's";
      case 'kellogs':
        return "kellogg's";
      default:
        return query; // Return original query
    }
  }

  // Get reason why a product was filtered out (for debugging)
  String _getFilterReason(Product product) {
    if (product.productName == null || product.productName!.trim().isEmpty) {
      return 'No product name';
    }

    final productName = product.productName!.toLowerCase();
    final ingredients = (product.ingredientsText ?? '').toLowerCase();

    // Check for French words in ingredients
    if (ingredients.contains('farine de blé')) return 'French: farine de blé';
    if (ingredients.contains('émulsifiant')) return 'French: émulsifiant';
    if (ingredients.contains('ingrédients')) return 'French: ingrédients';
    if (ingredients.contains('peut contenir')) return 'French: peut contenir';

    // Check for French in product name
    if (productName.contains('français')) return 'French: français';
    if (productName.contains('française')) return 'French: française';

    return 'Unknown reason (should not be filtered)';
  }

  // Sort products by relevance to search query
  void _sortProductsByRelevance(List<Product> products, String query) {
    final queryLower = query.toLowerCase().trim();
    
    products.sort((a, b) {
      final aName = (a.productName ?? '').toLowerCase();
      final aBrands = (a.brands ?? '').toLowerCase();
      final bName = (b.productName ?? '').toLowerCase();
      final bBrands = (b.brands ?? '').toLowerCase();
      
      // Calculate relevance scores
      int aScore = _calculateRelevanceScore(aName, aBrands, queryLower);
      int bScore = _calculateRelevanceScore(bName, bBrands, queryLower);
      
      // Higher score = more relevant = should come first
      return bScore.compareTo(aScore);
    });
  }

  int _calculateRelevanceScore(String productName, String brands, String query) {
    int score = 0;
    
    // Exact match gets highest priority
    if (productName == query) {
      score += 1000;
    }
    
    // Brand exact match gets very high priority
    if (brands.split(',').any((brand) => brand.trim() == query)) {
      score += 800;
    }
    
    // Product name starts with query gets high priority
    if (productName.startsWith(query)) {
      score += 600;
    }
    
    // Brand starts with query
    if (brands.split(',').any((brand) => brand.trim().startsWith(query))) {
      score += 500;
    }
    
    // Product name contains query as whole word
    if (productName.split(' ').contains(query)) {
      score += 400;
    }
    
    // Brand contains query as whole word
    if (brands.split(',').any((brand) => brand.trim().split(' ').contains(query))) {
      score += 350;
    }
    
    // Product name contains query anywhere
    if (productName.contains(query)) {
      score += 200;
    }
    
    // Brand contains query anywhere
    if (brands.contains(query)) {
      score += 150;
    }
    
    // Special handling for common brand names
    if (query == 'pepsi' || query == 'coca cola' || query == 'coke') {
      // Prioritize simple product names over complex variants
      final words = productName.split(' ');
      if (words.length <= 2 && words.any((word) => word.toLowerCase() == query)) {
        score += 300; // Boost simple names like "Pepsi" over "Pepsi Max Zero Sugar"
      }
      
      // Deprioritize variants with "max", "zero", "diet", etc.
      if (productName.toLowerCase().contains('max') ||
          productName.toLowerCase().contains('zero') ||
          productName.toLowerCase().contains('diet') ||
          productName.toLowerCase().contains('light')) {
        score -= 100;
      }
    }
    
    // Bonus for shorter names (more likely to be the main product)
    if (productName.length <= 20) {
      score += 50;
    }
    
    // Bonus for single-word names (like "Pepsi" vs "Pepsi Max Zero Sugar")
    if (productName.split(' ').length <= 2) {
      score += 30;
    }
    
    // Penalty for very long names (likely to be specific variants)
    if (productName.length > 50) {
      score -= 50;
    }
    
    return score;
  }

  // Helper method to check if product has English content
  bool _hasEnglishContent(Product product) {
    // Product must have a name
    if (product.productName == null || product.productName!.trim().isEmpty) {
      return false;
    }

    final productName = product.productName!.toLowerCase();
    final ingredients = (product.ingredientsText ?? '').toLowerCase();

    // Only filter out products with obvious French patterns
    // Be very lenient - only exclude if we find clear French indicators

    // Check for very obvious French words in ingredients
    if (ingredients.contains('farine de blé') ||
        ingredients.contains('émulsifiant') ||
        ingredients.contains('ingrédients') ||
        ingredients.contains('peut contenir')) {
      return false;
    }

    // Check for obvious French in product name
    if (productName.contains('français') ||
        productName.contains('française')) {
      return false;
    }

    // For everything else, allow it through
    return true;
  }

}
