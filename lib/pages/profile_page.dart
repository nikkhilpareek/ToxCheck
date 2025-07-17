import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LocalStorageService _storageService = LocalStorageService();
  Map<String, dynamic> _statistics = {};
  Map<String, bool> _healthPreferences = {};
  Map<String, bool> _allergenAlerts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = _storageService.getStatistics();
      final healthPrefs = {
        'diabetesFriendly': _storageService.getSetting<bool>('diabetesFriendly', defaultValue: false) ?? false,
        'glutenFree': _storageService.getSetting<bool>('glutenFree', defaultValue: false) ?? false,
        'lowSodium': _storageService.getSetting<bool>('lowSodium', defaultValue: true) ?? true,
        'noArtificialColors': _storageService.getSetting<bool>('noArtificialColors', defaultValue: true) ?? true,
      };
      final allergenAlerts = {
        'nuts': _storageService.getSetting<bool>('allergen_nuts', defaultValue: true) ?? true,
        'dairy': _storageService.getSetting<bool>('allergen_dairy', defaultValue: false) ?? false,
        'eggs': _storageService.getSetting<bool>('allergen_eggs', defaultValue: false) ?? false,
        'soy': _storageService.getSetting<bool>('allergen_soy', defaultValue: true) ?? true,
      };

      setState(() {
        _statistics = stats;
        _healthPreferences = healthPrefs;
        _allergenAlerts = allergenAlerts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _toggleHealthPreference(String key, bool value) async {
    setState(() {
      _healthPreferences[key] = value;
    });
    await _storageService.saveSetting(key, value);
  }

  void _toggleAllergenAlert(String key, bool value) async {
    setState(() {
      _allergenAlerts[key] = value;
    });
    await _storageService.saveSetting('allergen_$key', value);
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2F34),
        title: const Text(
          'About ToxCheck',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'ToxCheck helps you make informed decisions about food safety by analyzing product ingredients and additives.\n\nVersion: 1.0.0\nDeveloped with care for your health.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFF5FFA8)),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2F34),
        title: const Text(
          'Clear All Data',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all your scan history, preferences, and cached data. This action cannot be undone.',
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
              await _storageService.clearHistory();
              await _storageService.clearCache();
              await _storageService.clearSearchHistory();
              _loadData(); // Reload to show updated stats
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared successfully'),
                    backgroundColor: Color(0xFFF5FFA8),
                  ),
                );
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1D1F24),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF5FFA8),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1D1F24),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              // Settings functionality - could expand this later
              _showAboutDialog();
            },
            icon: const Icon(Icons.settings, color: Color(0xFFF5FFA8)),
            iconSize: 28,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF272A32),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFF5FFA8),
                    child: Text(
                      "TC",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1F24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "ToxCheck User",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Health-conscious food explorer",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(
                        (_statistics['totalScans'] ?? 0).toString(), 
                        "Scans"
                      ),
                      _buildStatColumn(
                        (_healthPreferences.values.where((v) => v).length + 
                         _allergenAlerts.values.where((v) => v).length).toString(), 
                        "Alerts Set"
                      ),
                      _buildStatColumn(
                        "${_statistics['safePercentage'] ?? 0}%", 
                        "Safe Choices"
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Health Preferences
            _buildSectionCard(
              "Health Preferences",
              Icons.health_and_safety,
              [
                _buildPreferenceItem("Diabetes-friendly", _healthPreferences['diabetesFriendly'] ?? false, 
                  (value) => _toggleHealthPreference('diabetesFriendly', value)),
                _buildPreferenceItem("Gluten-free", _healthPreferences['glutenFree'] ?? false,
                  (value) => _toggleHealthPreference('glutenFree', value)),
                _buildPreferenceItem("Low sodium", _healthPreferences['lowSodium'] ?? true,
                  (value) => _toggleHealthPreference('lowSodium', value)),
                _buildPreferenceItem("No artificial colors", _healthPreferences['noArtificialColors'] ?? true,
                  (value) => _toggleHealthPreference('noArtificialColors', value)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Allergen Alerts
            _buildSectionCard(
              "Allergen Alerts",
              Icons.warning_amber,
              [
                _buildPreferenceItem("Nuts", _allergenAlerts['nuts'] ?? true,
                  (value) => _toggleAllergenAlert('nuts', value)),
                _buildPreferenceItem("Dairy", _allergenAlerts['dairy'] ?? false,
                  (value) => _toggleAllergenAlert('dairy', value)),
                _buildPreferenceItem("Eggs", _allergenAlerts['eggs'] ?? false,
                  (value) => _toggleAllergenAlert('eggs', value)),
                _buildPreferenceItem("Soy", _allergenAlerts['soy'] ?? true,
                  (value) => _toggleAllergenAlert('soy', value)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // App Settings
            _buildMenuSection(),
            
            const SizedBox(height: 24),
            
            // Clear Data Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _clearAllData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Clear All Data",
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
    );
  }
  
  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5FFA8),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFF5FFA8),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildPreferenceItem(String title, bool isEnabled, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: const Color(0xFFF5FFA8),
            activeTrackColor: const Color(0xFFF5FFA8).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuSection() {
    return Container(
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
      child: Column(
        children: [
          _buildMenuItem(Icons.notifications, "Notifications", () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications settings coming soon!'))
            );
          }),
          _buildMenuItem(Icons.privacy_tip, "Privacy & Security", () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy settings coming soon!'))
            );
          }),
          _buildMenuItem(Icons.help, "Help & Support", () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF2D2F34),
                title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
                content: const Text(
                  'Need help?\n\n• Scan barcodes to check product safety\n• Search for products in the search tab\n• View your scan history\n• Set health preferences and allergen alerts\n\nFor technical support, please contact us.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(color: Color(0xFFF5FFA8))),
                  ),
                ],
              ),
            );
          }),
          _buildMenuItem(Icons.info, "About ToxCheck", _showAboutDialog),
        ],
      ),
    );
  }
  
  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFFF5FFA8),
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white54,
        size: 16,
      ),
      onTap: onTap,
    );
  }
}
