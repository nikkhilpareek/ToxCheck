import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> recentSearches = [
    "Maggi Noodles",
    "Coca Cola",
    "Lay's Chips",
    "Dairy Milk Chocolate",
    "Biscoff Cookies"
  ];

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
                decoration: const InputDecoration(
                  hintText: "Search by product name or ingredient...",
                  hintStyle: TextStyle(color: Colors.white60),
                  prefixIcon: Icon(Icons.search, color: Color(0xFFF5FFA8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 24),

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
              child: ListView.separated(
                itemCount: recentSearches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _searchController.text = recentSearches[index];
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
                          recentSearches[index],
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
        ),
      ),
    );
  }

  Widget _buildPopularSearchChip(String searchTerm) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          _searchController.text = searchTerm;
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
