import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/toxic_additive.dart';
import '../services/product_service.dart';
import '../services/toxic_additive_service.dart';

class CompareProductsPage extends StatefulWidget {
  const CompareProductsPage({super.key});

  @override
  State<CompareProductsPage> createState() => _CompareProductsPageState();
}

class _CompareProductsPageState extends State<CompareProductsPage> {
  final TextEditingController _product1Controller = TextEditingController();
  final TextEditingController _product2Controller = TextEditingController();
  final ProductService _productService = ProductService();
  final ToxicAdditiveService _toxicService = ToxicAdditiveService();

  Product? _selectedProduct1;
  Product? _selectedProduct2;
  List<Product> _searchResults1 = [];
  List<Product> _searchResults2 = [];
  bool _isSearching1 = false;
  bool _isSearching2 = false;
  bool _showResults1 = false;
  bool _showResults2 = false;
  Map<String, ToxicAdditive> _toxicAdditives = {};
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadToxicAdditives();
  }

  @override
  void dispose() {
    _product1Controller.dispose();
    _product2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadToxicAdditives() async {
    try {
      _toxicAdditives = await _toxicService.loadToxicAdditives();
      setState(() {
        _dataLoaded = true;
      });
    } catch (e) {
      print('Error loading toxic additives: $e');
    }
  }

  Future<void> _searchProduct1(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showResults1 = false;
        _searchResults1.clear();
      });
      return;
    }

    setState(() {
      _isSearching1 = true;
      _showResults1 = true;
    });

    try {
      final results = await _productService.searchProducts(query.trim());
      setState(() {
        _searchResults1 = results.take(5).toList(); // Limit to 5 results
        _isSearching1 = false;
      });
    } catch (e) {
      setState(() {
        _isSearching1 = false;
      });
    }
  }

  Future<void> _searchProduct2(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _showResults2 = false;
        _searchResults2.clear();
      });
      return;
    }

    setState(() {
      _isSearching2 = true;
      _showResults2 = true;
    });

    try {
      final results = await _productService.searchProducts(query.trim());
      setState(() {
        _searchResults2 = results.take(5).toList(); // Limit to 5 results
        _isSearching2 = false;
      });
    } catch (e) {
      setState(() {
        _isSearching2 = false;
      });
    }
  }

  void _selectProduct1(Product product) {
    setState(() {
      _selectedProduct1 = product;
      _product1Controller.text = product.productName ?? 'Unknown Product';
      _showResults1 = false;
      _searchResults1.clear();
    });
  }

  void _selectProduct2(Product product) {
    setState(() {
      _selectedProduct2 = product;
      _product2Controller.text = product.productName ?? 'Unknown Product';
      _showResults2 = false;
      _searchResults2.clear();
    });
  }

  List<ToxicAdditive> _getHarmfulAdditives(Product product) {
    final harmfulAdditives = <ToxicAdditive>[];
    for (String additive in (product.additivesTags ?? [])) {
      final toxicInfo = _toxicAdditives[additive.toLowerCase()];
      if (toxicInfo != null) {
        harmfulAdditives.add(toxicInfo);
      }
    }
    return harmfulAdditives;
  }

  double _calculateSafetyScore(Product product) {
    final harmfulAdditives = _getHarmfulAdditives(product);
    double baseScore = 10.0;
    
    for (ToxicAdditive additive in harmfulAdditives) {
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
    
    return baseScore.clamp(0.0, 10.0);
  }

  String _getSafetyGrade(double score) {
    if (score >= 8.0) return 'A';
    if (score >= 6.0) return 'B';
    if (score >= 4.0) return 'C';
    return 'D';
  }

  Color _getSafetyColor(double score) {
    if (score >= 8.0) return const Color(0xFF4CAF50); // Green
    if (score >= 6.0) return const Color(0xFF8BC34A); // Light Green
    if (score >= 4.0) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1F24),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compare Products',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Warning Banner - only show when not comparing
            if (!(_selectedProduct1 != null && _selectedProduct2 != null && _dataLoaded))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
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

            // Main Content
            if (_selectedProduct1 != null && _selectedProduct2 != null && _dataLoaded)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildComparisonResults(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF272A32),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF393C44)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.compare_arrows,
                                color: Color(0xFFB8E2DC),
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Select Products to Compare',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Search and select two products to compare their safety',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Product 1 Search
                          const Text(
                            'Product 1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSearchField(
                            controller: _product1Controller,
                            hintText: 'Search for first product...',
                            onChanged: _searchProduct1,
                            onClear: () {
                              setState(() {
                                _selectedProduct1 = null;
                                _showResults1 = false;
                                _searchResults1.clear();
                              });
                            },
                          ),
                          
                          // Show selected product 1
                          if (_selectedProduct1 != null) ...[
                            const SizedBox(height: 8),
                            _buildSelectedProductCard(_selectedProduct1!, 1),
                          ],

                          const SizedBox(height: 16),

                          // Product 2 Search
                          const Text(
                            'Product 2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSearchField(
                            controller: _product2Controller,
                            hintText: 'Search for second product...',
                            onChanged: _searchProduct2,
                            onClear: () {
                              setState(() {
                                _selectedProduct2 = null;
                                _showResults2 = false;
                                _searchResults2.clear();
                              });
                            },
                          ),
                          
                          // Show selected product 2
                          if (_selectedProduct2 != null) ...[
                            const SizedBox(height: 8),
                            _buildSelectedProductCard(_selectedProduct2!, 2),
                          ],
                        ],
                      ),
                    ),

                    // Search Results Section
                    if (_showResults1 || _showResults2) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300, // Fixed height for search results
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              if (_showResults1) ...[
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Product 1 Results:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildSearchResults(_searchResults1, _isSearching1, _selectProduct1),
                              ],
                              if (_showResults1 && _showResults2) const SizedBox(height: 12),
                              if (_showResults2) ...[
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Product 2 Results:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildSearchResults(_searchResults2, _isSearching2, _selectProduct2),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ] else if (!_dataLoaded) ...[
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFB8E2DC),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.compare_arrows,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select two products to compare',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Search and choose products above to see detailed comparison',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required Function(String) onChanged,
    required VoidCallback onClear,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF393C44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  controller.clear();
                  onClear();
                },
              )
            : null,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSearchResults(List<Product> results, bool isLoading, Function(Product) onSelect) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: const Color(0xFF393C44),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFFB8E2DC),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          : results.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No products found',
                    style: TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF4A4D55), height: 1),
                  itemBuilder: (context, index) {
                    final product = results[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A4D55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.fastfood,
                                    color: Color(0xFFB8E2DC),
                                    size: 16,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.fastfood,
                                color: Color(0xFFB8E2DC),
                                size: 16,
                              ),
                      ),
                      title: Text(
                        product.productName ?? 'Unknown Product',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: product.brands != null
                          ? Text(
                              product.brands!,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => onSelect(product),
                    );
                  },
                ),
    );
  }

  Widget _buildSelectedProductCard(Product product, int productNumber) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF393C44),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4A4D55),
              borderRadius: BorderRadius.circular(6),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fastfood,
                        color: Color(0xFFB8E2DC),
                        size: 20,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.fastfood,
                    color: Color(0xFFB8E2DC),
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? 'Unknown Product',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.brands != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.brands!,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonResults() {
    final product1HarmfulAdditives = _getHarmfulAdditives(_selectedProduct1!);
    final product2HarmfulAdditives = _getHarmfulAdditives(_selectedProduct2!);
    final product1Score = _calculateSafetyScore(_selectedProduct1!);
    final product2Score = _calculateSafetyScore(_selectedProduct2!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparison Results',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Products Overview Cards
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _buildProductOverviewCard(_selectedProduct1!, product1Score, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildProductOverviewCard(_selectedProduct2!, product2Score, false)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Safety Comparison
        _buildSafetyComparison(product1Score, product2Score),

        const SizedBox(height: 20),

        // Additives Comparison
        _buildAdditivesComparison(product1HarmfulAdditives, product2HarmfulAdditives),

        const SizedBox(height: 20),

        // Allergens Comparison
        _buildAllergensComparison(_selectedProduct1!, _selectedProduct2!),
        
        const SizedBox(height: 20), // Extra padding at bottom
      ],
    );
  }

  Widget _buildProductOverviewCard(Product product, double score, bool isFirst) {
    final grade = _getSafetyGrade(score);
    final color = _getSafetyColor(score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272A32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF393C44),
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fastfood,
                        color: Color(0xFFF5FFA8),
                        size: 24,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.fastfood,
                    color: Color(0xFFF5FFA8),
                    size: 24,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            product.productName ?? 'Unknown Product',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Grade $grade',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyComparison(double score1, double score2) {
    final bool score1Higher = score1 > score2;
    final bool scoresEqual = score1 == score2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272A32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF393C44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Color(0xFFB8E2DC), size: 20),
              SizedBox(width: 8),
              Text(
                'Safety Score Comparison',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${score1.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        color: scoresEqual 
                            ? Colors.white 
                            : score1Higher 
                                ? const Color(0xFF4CAF50) 
                                : const Color(0xFFFFB74D),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${score2.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        color: scoresEqual 
                            ? Colors.white 
                            : !score1Higher 
                                ? const Color(0xFF4CAF50) 
                                : const Color(0xFFFFB74D),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (scoresEqual) ...[
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Both products have equal safety scores',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditivesComparison(List<ToxicAdditive> additives1, List<ToxicAdditive> additives2) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272A32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF393C44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science, color: Color(0xFFFF9800), size: 20),
              SizedBox(width: 8),
              Text(
                'Harmful Additives Comparison',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${additives1.length} harmful additives',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (additives1.isEmpty)
                      const Text(
                        'No harmful additives found',
                        style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                      )
                    else
                      ...additives1.map((additive) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${additive.name}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      )),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${additives2.length} harmful additives',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (additives2.isEmpty)
                      const Text(
                        'No harmful additives found',
                        style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                      )
                    else
                      ...additives2.map((additive) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${additive.name}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllergensComparison(Product product1, Product product2) {
    final allergens1 = product1.allergensTags ?? [];
    final allergens2 = product2.allergensTags ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272A32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF393C44)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFFFF9800), size: 20),
              SizedBox(width: 8),
              Text(
                'Allergens Comparison',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${allergens1.length} allergens',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (allergens1.isEmpty)
                      const Text(
                        'No allergens found',
                        style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                      )
                    else
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: allergens1.map((allergen) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            allergen.replaceAll('en:', '').replaceAll('-', ' ').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFFF9800),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${allergens2.length} allergens',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (allergens2.isEmpty)
                      const Text(
                        'No allergens found',
                        style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                      )
                    else
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: allergens2.map((allergen) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            allergen.replaceAll('en:', '').replaceAll('-', ' ').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFFF9800),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
