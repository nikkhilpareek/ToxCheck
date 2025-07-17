import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/local_storage_service.dart';
import '../services/product_service.dart';
import '../models/scan_history.dart';
import '../pages/product_details_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.onDataCleared});

  final VoidCallback? onDataCleared;

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  final LocalStorageService _storageService = LocalStorageService();
  List<ScanHistory> _scanHistory = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final history = _storageService.getRecentScans();
      final stats = _storageService.getStatistics();
      
      print('DEBUG: Loaded ${history.length} items in history');
      
      if (mounted) {
        setState(() {
          _scanHistory = history;
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refreshHistory() async {
    await _loadHistory();
  }

  void _deleteHistoryItem(int index) {
    final deletedItem = _scanHistory[index];

    setState(() => _scanHistory.removeAt(index));
    
    // Remove from storage
    _storageService.deleteScan(index);

    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Deleted ${deletedItem.productName}"),
        backgroundColor: const Color(0xFF2D2F34),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFF5FFA8),
          onPressed: () {
            setState(() => _scanHistory.insert(index, deletedItem));
            // Note: Undo for storage deletion would require more complex logic
          },
        ),
      ),
    );
  }

  IconData _getStatusIcon(double score) {
    if (score >= 8.0) return Icons.check_circle;
    if (score >= 6.0) return Icons.warning;
    return Icons.dangerous;
  }

  Color _getStatusColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }

  String _getStatusText(double score) {
    if (score >= 8.0) return 'Safe';
    if (score >= 6.0) return 'Caution';
    return 'Warning';
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.orange;
    return Colors.red;
  }

  double _calculateSafetyScore(ScanHistory item) {
    // Calculate comprehensive safety score based on multiple factors
    double score = 10.0; // Start with perfect score
    
    // Deduct for actual risky additives (more significant impact)
    score -= item.additiveRisks.length * 2.0;
    
    // Deduct for poor nutrition grade
    if (item.nutritionGrade != null) {
      switch (item.nutritionGrade!) {
        case 1: break; // A grade - No deduction
        case 2: score -= 0.5; break; // B grade
        case 3: score -= 1.0; break; // C grade
        case 4: score -= 1.5; break; // D grade
        case 5: score -= 2.0; break; // E grade
      }
    }
    
    // Deduct for high NOVA group (ultra-processed foods)
    if (item.novaGroup != null && item.novaGroup! > 2) {
      score -= (item.novaGroup! - 2) * 1.0;
    }
    
    // Note: We don't penalize for total additive count in history 
    // since we already have the actual harmful additives count
    
    return score.clamp(0.0, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1F24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Scan History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: refreshHistory,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFFF5FFA8),
            ),
            tooltip: 'Refresh History',
          ),
          if (_scanHistory.isNotEmpty)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF2D2F34),
                    title: const Text(
                      'Clear All Data',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'This will permanently delete all scan history, search history, and cached data. This action cannot be undone.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          setState(() => _scanHistory.clear());
                          
                          // Clear all related data
                          await _storageService.clearHistory();
                          await _storageService.clearSearchHistory();
                          await _storageService.clearCache();
                          
                          HapticFeedback.mediumImpact();
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All history and search data cleared'),
                                backgroundColor: Color(0xFFF5FFA8),
                              ),
                            );
                            
                            // Notify parent that data was cleared
                            widget.onDataCleared?.call();
                          }
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFF5FFA8),
              ),
            )
          : _scanHistory.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildStatsSection(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: refreshHistory,
                        color: const Color(0xFFF5FFA8),
                        backgroundColor: const Color(0xFF2D2F34),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _scanHistory.length,
                          itemBuilder: (context, index) {
                            final item = _scanHistory[index];
                            return Dismissible(
                              key: Key(item.dateTime.toString()),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _deleteHistoryItem(index),
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                            child: _buildHistoryItem(item, index),
                          );
                        },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No scan history yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning products to see your history here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_scanHistory.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2F34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total Scans',
              _statistics['totalScans']?.toString() ?? '0',
              Icons.qr_code_scanner,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.1),
          ),
          Expanded(
            child: _buildStatItem(
              'Safe Products',
              _statistics['safeProducts']?.toString() ?? '0',
              Icons.check_circle,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.1),
          ),
          Expanded(
            child: _buildStatItem(
              'Avg. Score',
              (_statistics['averageScore'] ?? 0.0).toStringAsFixed(1),
              Icons.star,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFF5FFA8),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(ScanHistory item, int index) {
    final safetyScore = _calculateSafetyScore(item);
    return GestureDetector(
      onTap: () => _navigateToProductDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2F34),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(safetyScore).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(safetyScore),
                color: _getStatusColor(safetyScore),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _getStatusText(safetyScore),
                        style: TextStyle(
                          color: _getStatusColor(safetyScore),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(item.dateTime),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(safetyScore).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                safetyScore.toStringAsFixed(1),
                style: TextStyle(
                  color: _getScoreColor(safetyScore),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
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

  Future<void> _navigateToProductDetails(ScanHistory item) async {
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
      // Fetch the product using the barcode
      final productService = ProductService();
      final product = await productService.fetchProduct(item.barcode);
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        if (product != null) {
          // Navigate to product details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsPage(
                product: product,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product no longer available in database'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
