import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../services/local_storage_service.dart';
import '../services/toxic_additive_service.dart';
import '../models/product.dart';
import '../pages/product_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialSearchTerm});

  final String? initialSearchTerm;

  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final LocalStorageService _storageService = LocalStorageService();
  final ToxicAdditiveService _toxicService = ToxicAdditiveService();

  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    if (widget.initialSearchTerm != null) {
      _searchController.text = widget.initialSearchTerm!;
      // Automatically perform search after widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialSearchTerm!);
      });
    }
  }

  void _loadRecentSearches() {
    setState(() {
      _recentSearches = _storageService.getRecentSearches();
    });
  }

  // Public method to refresh recent searches from external calls
  void refreshRecentSearches() {
    _loadRecentSearches();
  }

  // Public method to search with a specific query from external calls
  void searchWithQuery(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload recent searches when the widget comes into view
    _loadRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1F24),
        elevation: 0,
        title: const Text(
          "Search Products",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF272A32),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF393C44)),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) => _performSearch(value),
                decoration: InputDecoration(
                  hintText: "Search by product name or ingredient...",
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFF5FFA8)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults.clear();
                              _hasSearched = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 24),

            // Content Section - Search Results or Recent/Popular
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF5FFA8),
                      ),
                    )
                  : _hasSearched
                      ? _buildSearchResults()
                      : _buildDefaultContent(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _productService.searchProducts(query);
      await _storageService.saveSearchTerm(query);
      _loadRecentSearches(); // Reload recent searches
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Warning Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF9800).withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber,
                color: Color(0xFFFF9800),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Disclaimer',
                      style: TextStyle(
                        color: Color(0xFFFF9800),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The data on this app regarding allergens, additives, and ingredients is sourced from OpenFoodFacts. We do not take any responsibility for its credibility. Always verify with product packaging.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Search Results List
        Expanded(
          child: ListView.separated(
            itemCount: _searchResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Popular Searches Today Section
        const Text(
          "Popular Searches Today",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildPopularSearchChip("Maggi Noodles"),
              _buildPopularSearchChip("Coca Cola"),
              _buildPopularSearchChip("Dairy Milk"),
              _buildPopularSearchChip("Lay's Chips"),
              _buildPopularSearchChip("Biscoff"),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          "Recent Searches",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Recent Search List
        Expanded(
          child: _recentSearches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent searches',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Search for products to see them here',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _recentSearches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _searchController.text = _recentSearches[index];
                        _performSearch(_recentSearches[index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF272A32),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.history, color: Color(0xFFF5FFA8)),
                          title: Text(
                            _recentSearches[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _navigateToProductDetails(product),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF272A32),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1D1F24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.fastfood,
                            color: Color(0xFFF5FFA8),
                            size: 30,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.fastfood,
                      color: Color(0xFFF5FFA8),
                      size: 30,
                    ),
            ),
            
            const SizedBox(width: 16),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.brands != null)
                    Text(
                      product.brands!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Safety Score
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSafetyScoreColor(_calculateSafetyScore(product)).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 12,
                              color: _getSafetyScoreColor(_calculateSafetyScore(product)),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_calculateSafetyScore(product).toStringAsFixed(1)}/10',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getSafetyScoreColor(_calculateSafetyScore(product)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.nutritionGrade != 'N/A') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getNutritionGradeColor(product.nutritionGrade).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Grade ${product.nutritionGrade}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getNutritionGradeColor(product.nutritionGrade),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (product.hasAdditives)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.additivesTags!.length} additives',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToProductDetails(Product product) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF5FFA8),
        ),
      ),
    );

    try {
      // Analyze the product and save to history
      final analysis = await _toxicService.analyzeProduct(product);
      await _storageService.saveScan(analysis);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Navigate to product details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              product: product,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Calculate comprehensive safety score for a product
  double _calculateSafetyScore(Product product) {
    double score = 10.0; // Start with perfect score
    
    // Estimate harmful additives as 30% of total (conservative estimate)
    final totalAdditives = product.additivesTags?.length ?? 0;
    final estimatedHarmfulAdditives = (totalAdditives * 0.3).round();
    score -= estimatedHarmfulAdditives * 2.0;
    
    // Deduct for poor nutrition grade
    final nutritionGrade = product.nutritionGrade;
    if (nutritionGrade != 'N/A') {
      switch (nutritionGrade.toLowerCase()) {
        case 'a': break; // No deduction
        case 'b': score -= 0.5; break;
        case 'c': score -= 1.0; break;
        case 'd': score -= 1.5; break;
        case 'e': score -= 2.0; break;
      }
    }
    
    // Deduct for high NOVA group
    final novaGroup = product.novaGroup;
    if (novaGroup != null && novaGroup > 2) {
      score -= (novaGroup - 2) * 1.0;
    }
    
    // Small deduction for high number of total additives
    if (totalAdditives > 10) {
      score -= (totalAdditives - 10) * 0.1;
    }
    
    return score.clamp(0.0, 10.0);
  }

  Color _getSafetyScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }

  Color _getNutritionGradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'a':
        return Colors.green;
      case 'b':
        return Colors.lightGreen;
      case 'c':
        return Colors.yellow;
      case 'd':
        return Colors.orange;
      case 'e':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPopularSearchChip(String searchTerm) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          _searchController.text = searchTerm;
          _performSearch(searchTerm);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF272A32),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF393C44),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.trending_up,
                size: 16,
                color: Color(0xFFF5FFA8),
              ),
              const SizedBox(width: 6),
              Text(
                searchTerm,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
