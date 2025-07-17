import 'package:flutter/material.dart';
import '../models/toxic_additive.dart';
import '../services/toxic_additive_service.dart';

class AdditiveSearchPage extends StatefulWidget {
  const AdditiveSearchPage({super.key});

  @override
  State<AdditiveSearchPage> createState() => _AdditiveSearchPageState();
}

class _AdditiveSearchPageState extends State<AdditiveSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ToxicAdditiveService _toxicService = ToxicAdditiveService();
  
  Map<String, ToxicAdditive> _allAdditives = {};
  List<MapEntry<String, ToxicAdditive>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAdditives();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdditives() async {
    try {
      _allAdditives = await _toxicService.loadToxicAdditives();
      
      // Debug: Print INS numbers found
      print('=== DEBUG: INS Numbers found ===');
      for (final entry in _allAdditives.entries) {
        if (entry.value.insNumber != null) {
          print('${entry.key}: ${entry.value.insNumber}');
        }
      }
      print('=== END DEBUG ===');
      
      setState(() {
        _dataLoaded = true;
      });
    } catch (e) {
      print('Error loading additives: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading additive data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchAdditives() async {
    if (_searchController.text.trim().isEmpty || !_dataLoaded) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final query = _searchController.text.trim().toLowerCase();
      final results = <MapEntry<String, ToxicAdditive>>[];

      // Search by code (key), name, E number, or INS number
      for (final entry in _allAdditives.entries) {
        final code = entry.key.toLowerCase();
        final additive = entry.value;
        final name = additive.name.toLowerCase();
        final eNumber = additive.eNumber?.toLowerCase() ?? '';
        final insNumber = additive.insNumber?.toLowerCase() ?? '';

        // Debug for INS search
        if (query.toLowerCase().contains('ins') || query == '621' || query == '120') {
          print('DEBUG: Checking ${entry.key} - INS: "${additive.insNumber}" for query: "$query"');
          if (additive.insNumber != null) {
            final insNumOnly = additive.insNumber!.toLowerCase().replaceAll('ins ', '').trim();
            print('  - INS number only: "$insNumOnly"');
            print('  - Query normalized: "${query.toLowerCase().trim()}"');
          }
        }

        // Check if query matches any field
        bool matches = false;
        
        // Direct matches
        if (code.contains(query) || name.contains(query)) {
          matches = true;
        }
        
        // E number matches (with or without 'e' prefix)
        if (eNumber.isNotEmpty) {
          if (eNumber.contains(query) || 
              query.startsWith('e') && eNumber.contains(query.substring(1)) ||
              query.replaceAll(' ', '').contains(eNumber.replaceAll(' ', ''))) {
            matches = true;
          }
        }
        
        // INS number matches (with or without 'ins' prefix)
        if (insNumber.isNotEmpty) {
          // Extract just the number part from "ins 123" format  
          final insNumOnly = insNumber.toLowerCase().replaceAll('ins ', '').trim();
          final queryLower = query.toLowerCase().trim();
          
          // Handle various INS search patterns
          bool insMatch = false;
          
          // Direct match with full INS number
          if (insNumber.toLowerCase() == queryLower) {
            insMatch = true;
          }
          
          // Match just the number part
          if (insNumOnly == queryLower) {
            insMatch = true;
          }
          
          // Handle "ins" prefix variations
          if (queryLower.startsWith('ins')) {
            String queryNumber = queryLower.substring(3).trim();
            // Remove any spaces or additional characters
            queryNumber = queryNumber.replaceAll(' ', '');
            if (insNumOnly == queryNumber) {
              insMatch = true;
            }
          }
          
          // Handle when user types "ins 621", "ins621", etc.
          String normalizedQuery = queryLower.replaceAll(' ', '');
          String normalizedInsNumber = insNumber.toLowerCase().replaceAll(' ', '');
          if (normalizedInsNumber == normalizedQuery) {
            insMatch = true;
          }
          
          if (insMatch) {
            matches = true;
          }
        }

        if (matches) {
          results.add(entry);
        }
      }

      // Enhanced sorting: exact matches first, then partial matches
      results.sort((a, b) {
        final aCode = a.key.toLowerCase();
        final bCode = b.key.toLowerCase();
        final aName = a.value.name.toLowerCase();
        final bName = b.value.name.toLowerCase();
        final aENumber = a.value.eNumber?.toLowerCase() ?? '';
        final bENumber = b.value.eNumber?.toLowerCase() ?? '';
        final aInsNumber = a.value.insNumber?.toLowerCase() ?? '';
        final bInsNumber = b.value.insNumber?.toLowerCase() ?? '';

        // Helper function to check exact matches
        bool isExactMatch(String field, String searchQuery) {
          return field == searchQuery || 
                 field.replaceAll(' ', '') == searchQuery.replaceAll(' ', '');
        }

        // Exact code match gets highest priority
        if (isExactMatch(aCode, query) && !isExactMatch(bCode, query)) return -1;
        if (isExactMatch(bCode, query) && !isExactMatch(aCode, query)) return 1;

        // Exact E number match gets second priority
        if (aENumber.isNotEmpty && isExactMatch(aENumber, query) && 
            !(bENumber.isNotEmpty && isExactMatch(bENumber, query))) return -1;
        if (bENumber.isNotEmpty && isExactMatch(bENumber, query) && 
            !(aENumber.isNotEmpty && isExactMatch(aENumber, query))) return 1;

        // Exact INS number match gets third priority
        final aInsNumOnly = aInsNumber.toLowerCase().replaceAll('ins ', '').trim();
        final bInsNumOnly = bInsNumber.toLowerCase().replaceAll('ins ', '').trim();
        final queryLower = query.toLowerCase().trim();
        
        // Helper function to check if query matches INS number
        bool matchesInsNumber(String insNumber, String insNumOnly, String searchQuery) {
          if (insNumber.isEmpty) return false;
          
          // Direct match
          if (insNumber == searchQuery || insNumOnly == searchQuery) return true;
          
          // Handle ins prefix
          if (searchQuery.startsWith('ins')) {
            String queryNumber = searchQuery.substring(3).trim().replaceAll(' ', '');
            if (insNumOnly == queryNumber) return true;
          }
          
          // Handle normalized comparison (remove spaces)
          String normalizedQuery = searchQuery.replaceAll(' ', '');
          String normalizedInsNumber = insNumber.replaceAll(' ', '');
          if (normalizedInsNumber == normalizedQuery) return true;
          
          return false;
        }
        
        bool aInsMatch = matchesInsNumber(aInsNumber.toLowerCase(), aInsNumOnly, queryLower);
        bool bInsMatch = matchesInsNumber(bInsNumber.toLowerCase(), bInsNumOnly, queryLower);
        
        if (aInsMatch && !bInsMatch) return -1;
        if (bInsMatch && !aInsMatch) return 1;

        // Exact name match gets fourth priority
        if (isExactMatch(aName, query) && !isExactMatch(bName, query)) return -1;
        if (isExactMatch(bName, query) && !isExactMatch(aName, query)) return 1;

        // Code starts with query gets fifth priority
        if (aCode.startsWith(query) && !bCode.startsWith(query)) return -1;
        if (bCode.startsWith(query) && !aCode.startsWith(query)) return 1;

        // Name starts with query gets sixth priority
        if (aName.startsWith(query) && !bName.startsWith(query)) return -1;
        if (bName.startsWith(query) && !aName.startsWith(query)) return 1;

        // Alphabetical order for the rest
        return aCode.compareTo(bCode);
      });

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching additives: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          'Search Additive',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Color(0xFFF5FFA8),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Search for Additives',
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
                    'Enter an additive name, E-number, or INS code to learn about it',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., E621, INS 621, MSG, Sodium benzoate...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF393C44),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
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
                    ),
                    onSubmitted: (_) => _searchAdditives(),
                    onChanged: (value) => setState(() {}), // To update clear button
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !_dataLoaded) ? null : _searchAdditives,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5FFA8),
                        foregroundColor: const Color(0xFF1D1F24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Color(0xFF1D1F24),
                                strokeWidth: 2,
                              ),
                            )
                          : !_dataLoaded
                              ? const Text(
                                  'Loading Additive Data...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : const Text(
                                  'Search Additives',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Results Section
            if (_hasSearched) ...[
              Text(
                _searchResults.isEmpty 
                    ? 'No additives found' 
                    : 'Found ${_searchResults.length} additive${_searchResults.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Additive Results
            Expanded(
              child: !_dataLoaded
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFFF5FFA8),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading additive database...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF5FFA8),
                          ),
                        )
                      : _searchResults.isEmpty && _hasSearched
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No additives found',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching with a different name or E-number',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final entry = _searchResults[index];
                                return _buildAdditiveCard(entry.key, entry.value);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditiveCard(String code, ToxicAdditive additive) {
    Color severityColor;
    String severityText;
    IconData severityIcon;

    switch (additive.severity.toLowerCase()) {
      case 'high':
        severityColor = const Color(0xFFF44336);
        severityText = 'HIGH RISK';
        severityIcon = Icons.dangerous;
        break;
      case 'medium':
        severityColor = const Color(0xFFFF9800);
        severityText = 'MEDIUM RISK';
        severityIcon = Icons.warning;
        break;
      case 'low':
        severityColor = const Color(0xFFFFC107);
        severityText = 'LOW RISK';
        severityIcon = Icons.info;
        break;
      default:
        severityColor = const Color(0xFF4CAF50);
        severityText = 'UNKNOWN';
        severityIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272A32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  code.toUpperCase(),
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      severityIcon,
                      color: severityColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      severityText,
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Additive Name
          Text(
            additive.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // E and INS numbers if available
          if (additive.eNumber != null || additive.insNumber != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (additive.eNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF393C44),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      additive.eNumber!,
                      style: const TextStyle(
                        color: Color(0xFFB8E2DC),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (additive.insNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF393C44),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      additive.insNumber!,
                      style: const TextStyle(
                        color: Color(0xFFF5FFA8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Risk Description
          Text(
            additive.risk,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          
          if (additive.status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: severityColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status:',
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    additive.status,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
