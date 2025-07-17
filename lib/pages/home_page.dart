import 'package:flutter/material.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/scan_card.dart';
import 'search_page.dart';
import 'history_page.dart';
import 'allergen_check_page.dart';
import 'additive_search_page.dart';
import 'compare_products_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalKey<HistoryPageState> _historyPageKey = GlobalKey<HistoryPageState>();
  final GlobalKey<_HomePageContentState> _homePageKey = GlobalKey<_HomePageContentState>();
  final GlobalKey<SearchPageState> _searchPageKey = GlobalKey<SearchPageState>();

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePageContent(
        key: _homePageKey,
        onNavigateToSearch: (query) {
          _searchPageKey.currentState?.searchWithQuery(query);
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      SearchPage(key: _searchPageKey),
      HistoryPage(
        key: _historyPageKey,
        onDataCleared: () {
          // Refresh search page recent searches
          _searchPageKey.currentState?.refreshRecentSearches();
        },
      ),
    ];
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E2E),
        selectedItemColor: const Color(0xFFF5FFA8),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  final Function(String)? onNavigateToSearch;

  const HomePageContent({
    super.key,
    this.onNavigateToSearch,
  });

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  @override
  void initState() {
    super.initState();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning!';
    } else if (hour < 17) {
      return 'Good Afternoon!';
    } else {
      return 'Good Evening!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'ToxCheck',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Check ingredients safely',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Disclaimer Banner
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
            
              const ScanCard(),
              const SizedBox(height: 8,),
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  QuickActionCard(
                    icon: Icons.search,
                    label: "Search\nAdditive",
                    iconBackgroundColor: const Color(0xFFF5FFA8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdditiveSearchPage(),
                        ),
                      );
                    },
                  ),
                  QuickActionCard(
                    icon: Icons.compare_arrows,
                    label: "Compare\nProducts",
                    iconBackgroundColor: const Color(0xFFB8E2DC),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompareProductsPage(),
                        ),
                      );
                    },
                  ),
                  QuickActionCard(
                    icon: Icons.health_and_safety_outlined,
                    label: "Allergen\nCheck",
                    iconBackgroundColor: const Color(0xFFBFB2C9),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AllergenCheckPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Special thanks banner at the bottom
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: const Color(0xFF4CAF50),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Special thanks to OpenFoodFacts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.favorite,
                      color: const Color(0xFF4CAF50),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
