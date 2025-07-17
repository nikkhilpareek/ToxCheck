import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/scan_history.dart';
import '../services/toxic_additive_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final ScanHistory? scanHistory;

  const ProductDetailsPage({
    super.key,
    required this.product,
    this.scanHistory,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final ToxicAdditiveService _toxicService = ToxicAdditiveService();
  List<Map<String, dynamic>> _harmfulAdditives = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToxicAdditives();
  }

  Future<void> _loadToxicAdditives() async {
    try {
      await _toxicService.loadToxicAdditives();
      await _checkHarmfulAdditives();
    } catch (e) {
      print('Error loading toxic additives: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkHarmfulAdditives() async {
    _harmfulAdditives.clear();
    for (String additive in (widget.product.additivesTags ?? [])) {
      final toxicInfo = await _toxicService.getToxicAdditiveInfo(additive);
      if (toxicInfo != null) {
        _harmfulAdditives.add({
          'tag': additive,
          'info': toxicInfo.toJson(),
        });
      }
    }
  }

  String _getSafetyGrade() {
    if (_harmfulAdditives.length >= 3) return 'D';
    if (_harmfulAdditives.length == 2) return 'C';
    if (_harmfulAdditives.length == 1) return 'B';
    return 'A';
  }

  double _getSafetyScore() {
    switch (_getSafetyGrade()) {
      case 'A': return 9.0;
      case 'B': return 7.0;
      case 'C': return 5.0;
      case 'D': return 3.0;
      default: return 5.0;
    }
  }

  Color _getSafetyColor() {
    switch (_getSafetyGrade()) {
      case 'A': return const Color(0xFF4CAF50); // Green
      case 'B': return const Color(0xFF8BC34A); // Light Green
      case 'C': return const Color(0xFFFF9800); // Orange
      case 'D': return const Color(0xFFF44336); // Red
      default: return const Color(0xFFFF9800);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            'Product Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF5FFA8),
          ),
        ),
      );
    }

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
          'Product Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF272A32),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF393C44)),
              ),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF393C44),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.product.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.fastfood,
                                color: Color(0xFFF5FFA8),
                                size: 40,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.fastfood,
                            color: Color(0xFFF5FFA8),
                            size: 40,
                          ),
                  ),
                  const SizedBox(width: 16),
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.productName ?? 'Unknown Product',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.brands ?? 'Unknown Brand',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Safety Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSafetyColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getSafetyColor().withOpacity(0.5)),
                          ),
                          child: Text(
                            _harmfulAdditives.isEmpty ? 'SAFE' : 'CAUTION',
                            style: TextStyle(
                              color: _getSafetyColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Safety Score Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getSafetyColor().withOpacity(0.8),
                    _getSafetyColor(),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Safety Score',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_getSafetyScore().toStringAsFixed(1)}/10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Grade: ${_getSafetyGrade()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Statistics Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.science,
                    value: (widget.product.additivesTags?.length ?? 0).toString(),
                    label: 'Total\nAdditives',
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.warning,
                    value: _harmfulAdditives.length.toString(),
                    label: 'Harmful\nAdditives',
                    color: const Color(0xFFFF9800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.restaurant,
                    value: widget.product.novaGroup != null ? widget.product.novaGroup.toString() : 'N/A',
                    label: 'NOVA\nGroup',
                    color: const Color(0xFF9C27B0),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Harmful Additives Section
            if (_harmfulAdditives.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.dangerous,
                    color: Color(0xFFF44336),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Harmful Additives Found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...(_harmfulAdditives.map((additive) => _buildAdditiveCard(additive))),
            ],

            const SizedBox(height: 20),

            // Ingredients Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF272A32),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF393C44)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        color: Color(0xFFF5FFA8),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ingredients',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.product.ingredientsText != null && widget.product.ingredientsText!.isNotEmpty
                        ? widget.product.ingredientsText!
                        : 'No ingredient information available.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Allergens Section
            if ((widget.product.allergensTags?.isNotEmpty ?? false)) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF272A32),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF393C44)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Color(0xFFFF9800),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Allergens',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.product.allergensTags ?? []).map((allergen) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.5)),
                          ),
                          child: Text(
                            allergen.replaceAll('en:', '').replaceAll('-', ' ').toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFFF9800),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272A32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF393C44)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditiveCard(Map<String, dynamic> additive) {
    final info = additive['info'] as Map<String, dynamic>;
    final riskLevel = info['risk_level'] ?? 'medium';
    
    Color riskColor;
    String riskText;
    switch (riskLevel.toLowerCase()) {
      case 'high':
        riskColor = const Color(0xFFF44336);
        riskText = 'HIGH RISK';
        break;
      case 'medium':
        riskColor = const Color(0xFFFF9800);
        riskText = 'MEDIUM RISK';
        break;
      default:
        riskColor = const Color(0xFFFFC107);
        riskText = 'LOW RISK';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272A32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  riskText,
                  style: TextStyle(
                    color: riskColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.warning,
                color: riskColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info['name'] ?? additive['tag'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info['risk'] ?? 'Unknown risk',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (info['status'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Status: ${info['status']}',
              style: TextStyle(
                color: riskColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
