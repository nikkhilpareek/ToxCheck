import 'package:flutter/material.dart';

import '../widgets/quick_action_card.dart';
import '../widgets/scan_card.dart';
import 'search_page.dart';
import 'history_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const HomePageContent(),
    const SearchPage(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1D1F24), 
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index), 
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
          BottomNavigationBarItem(
            label: "Profile",
            icon: Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ToxCheck", style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),),
      ),
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20,),
              const Text(
                "Good Afternoon,",
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4,),
              const Text(
                "Nikhil Pareek",
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold
                ),
              ),
              ScanCard(
                onTap: () {
                  print("Scan tapped");
                },
              ),
              const SizedBox(height: 8,),
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          QuickActionCard(
            icon: Icons.search,
            label: "Search by\nIngredients",
            iconBackgroundColor: const Color(0xFFF5FFA8),
            onTap: () => print("Search tapped"),
          ),
          QuickActionCard(
            icon: Icons.compare_arrows,
            label: "Compare\nProducts",
            iconBackgroundColor: const Color(0xFFB8E2DC),
            onTap: () => print("Compare tapped"),
          ),
          QuickActionCard(
            icon: Icons.health_and_safety_outlined,
            label: "Allergen\nCheck",
            iconBackgroundColor: const Color(0xFFBFB2C9),
            onTap: () => print("Allergen tapped"),
          ),
        ],
      ),],
          ),
        ),
      ),
    );
  }
}