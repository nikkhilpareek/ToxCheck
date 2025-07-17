import 'package:flutter/material.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/scan_card.dart';
import '../services/local_storage_service.dart';
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
  UniqueKey _homeKey = UniqueKey();
  Key _searchPageKey = UniqueKey();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomePageContent(key: _homeKey, onNavigateToSearch: _navigateToSearch),
      SearchPage(key: _searchPageKey),
      HistoryPage(key: _historyPageKey, onDataCleared: _onDataCleared),
    ]);
  }

  void _onDataCleared() {
    // Refresh home page to update recent searches and search page to clear search history
    setState(() {
      _homeKey = UniqueKey();
      _searchPageKey = UniqueKey();
      _pages[0] = HomePageContent(key: _homeKey, onNavigateToSearch: _navigateToSearch);
      _pages[1] = SearchPage(key: _searchPageKey);
    });
  }

  void _navigateToSearch(String searchTerm) {
    setState(() {
      _currentIndex = 1; // Navigate to search page
      _searchPageKey = UniqueKey();
      _pages[1] = SearchPage(key: _searchPageKey, initialSearchTerm: searchTerm);
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Refresh the home page when switching to it
    if (index == 0) {
      setState(() {
        _homeKey = UniqueKey();
        _pages[0] = HomePageContent(key: _homeKey, onNavigateToSearch: _navigateToSearch);
      });
    }
    
    // Refresh history when switching to it
    if (index == 2) {
      _historyPageKey.currentState?.refreshHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1F24),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1D1F24), 
        currentIndex: _currentIndex,
        onTap: _onTabChanged, 
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFF5FFA8), 
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(
            label: "Home",
            icon: Icon(Icons.home_outlined),
          ),
          BottomNavigationBarItem(
            label: "Search",
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            label: "History",
            icon: Icon(Icons.history),
          ),
        ],
      ),
    );
  }
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key, this.onNavigateToSearch});

  final Function(String)? onNavigateToSearch;

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final LocalStorageService _storageService = LocalStorageService();
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _debugDeviceSession();
  }

  void _debugDeviceSession() {
    final sessionId = _storageService.getDeviceSessionId();
    print('Device Session ID: $sessionId');
    print('Recent searches count: ${_recentSearches.length}');
  }

  void _loadRecentSearches() {
    setState(() {
      _recentSearches = _storageService.getRecentSearches();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload recent searches when the widget comes into view
    _loadRecentSearches();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning,";
    } else if (hour < 17) {
      return "Good Afternoon,";
    } else {
      return "Good Evening,";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ToxCheck", style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20,),
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4,),
              const Text(
                "Food Explorer",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              // Disclaimer Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5FFA8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF5FFA8).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFFF5FFA8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This app provides general information only. Always consult healthcare professionals for medical advice.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          height: 1.3,
                        ),
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
              const Text(
                "Recent Searches",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              // Recent Search List
              _recentSearches.isEmpty
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
                              // Navigate to search page with this term
                              widget.onNavigateToSearch?.call(_recentSearches[index]);
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
            ],
          ),
        ),
      ),
    );
  }
}

