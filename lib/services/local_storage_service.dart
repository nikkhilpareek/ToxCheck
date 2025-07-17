import 'package:hive_flutter/hive_flutter.dart';
import '../models/scan_history.dart';
import '../models/product.dart';
import '../services/toxic_additive_service.dart';

class LocalStorageService {
  static const String _scanHistoryBoxName = 'scanHistory';
  static const String _productCacheBoxName = 'productCache';
  static const String _settingsBoxName = 'settings';
  
  static Box<ScanHistory>? _scanHistoryBox;
  static Box<Map>? _productCacheBox;
  static Box? _settingsBox;

  // Initialize Hive boxes with proper device isolation
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ScanHistoryAdapter());
    }
    
    // Open boxes with device-specific storage
    // Hive automatically uses device-specific directories
    _scanHistoryBox = await Hive.openBox<ScanHistory>(_scanHistoryBoxName);
    _productCacheBox = await Hive.openBox<Map>(_productCacheBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    
    // Ensure we have a device-specific session marker
    await _ensureDeviceSession();
  }

  // Ensure device-specific session
  static Future<void> _ensureDeviceSession() async {
    try {
      final sessionId = _settingsBox?.get('device_session_id');
      if (sessionId == null) {
        // Create a new session ID for this device
        final newSessionId = DateTime.now().millisecondsSinceEpoch.toString();
        await _settingsBox?.put('device_session_id', newSessionId);
        await _settingsBox?.put('device_session_created', DateTime.now().toIso8601String());
        print('New device session created: $newSessionId');
      }
    } catch (e) {
      print('Error ensuring device session: $e');
    }
  }

  // Get device session information
  String? getDeviceSessionId() {
    try {
      return _settingsBox?.get('device_session_id') as String?;
    } catch (e) {
      print('Error getting device session ID: $e');
      return null;
    }
  }

  // Clear all device-specific data (for testing/reset)
  Future<void> clearAllDeviceData() async {
    try {
      await clearHistory();
      await clearCache();
      await clearSearchHistory();
      await _settingsBox?.clear();
      print('All device data cleared');
    } catch (e) {
      print('Error clearing device data: $e');
    }
  }

  // Scan History Methods
  Future<void> saveScan(ProductAnalysis analysis) async {
    try {
      // Convert nutrition grade letter to number (A=1, B=2, C=3, D=4, E=5)
      double? nutritionGradeNumber;
      final nutritionGrade = analysis.product.nutritionGrade;
      if (nutritionGrade != 'N/A') {
        switch (nutritionGrade.toLowerCase()) {
          case 'a': nutritionGradeNumber = 1.0; break;
          case 'b': nutritionGradeNumber = 2.0; break;
          case 'c': nutritionGradeNumber = 3.0; break;
          case 'd': nutritionGradeNumber = 4.0; break;
          case 'e': nutritionGradeNumber = 5.0; break;
        }
      }
      
      final scanHistory = ScanHistory(
        productName: analysis.product.displayName,
        barcode: analysis.product.barcode ?? '',
        dateTime: DateTime.now(),
        additiveRisks: analysis.harmfulTags,
        status: analysis.status,
        imageUrl: analysis.product.imageUrl,
        nutritionGrade: nutritionGradeNumber,
        novaGroup: analysis.product.novaGroup,
      );
      
      await _scanHistoryBox?.add(scanHistory);
      
      // Keep only last 100 scans
      if ((_scanHistoryBox?.length ?? 0) > 100) {
        await _scanHistoryBox?.deleteAt(0);
      }
    } catch (e) {
      print('Error saving scan: $e');
    }
  }

  List<ScanHistory> getRecentScans({int limit = 50}) {
    try {
      final scans = _scanHistoryBox?.values.toList() ?? [];
      scans.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return limit > 0 ? scans.take(limit).toList() : scans;
    } catch (e) {
      print('Error getting recent scans: $e');
      return [];
    }
  }

  Future<void> deleteScan(int index) async {
    try {
      if (index >= 0 && index < (_scanHistoryBox?.length ?? 0)) {
        await _scanHistoryBox?.deleteAt(index);
      }
    } catch (e) {
      print('Error deleting scan: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _scanHistoryBox?.clear();
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  // Product Cache Methods (for offline support)
  Future<void> cacheProduct(Product product, ProductAnalysis analysis) async {
    try {
      if (product.barcode != null) {
        final cacheData = {
          'product': product.toJson(),
          'analysis': {
            'status': analysis.status,
            'safetyScore': analysis.safetyScore,
            'harmfulTags': analysis.harmfulTags,
            'toxicAdditives': analysis.toxicAdditives.map((a) => a.toJson()).toList(),
          },
          'cachedAt': DateTime.now().toIso8601String(),
        };
        
        await _productCacheBox?.put(product.barcode!, cacheData);
        
        // Keep only last 10 cached products
        if ((_productCacheBox?.length ?? 0) > 10) {
          final oldestKey = _productCacheBox?.keys.first;
          await _productCacheBox?.delete(oldestKey);
        }
      }
    } catch (e) {
      print('Error caching product: $e');
    }
  }

  Map<String, dynamic>? getCachedProduct(String barcode) {
    try {
      final result = _productCacheBox?.get(barcode);
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      print('Error getting cached product: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      await _productCacheBox?.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Settings Methods
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox?.put(key, value);
    } catch (e) {
      print('Error saving setting: $e');
    }
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      print('Error getting setting: $e');
      return defaultValue;
    }
  }

  // Search History Methods
  Future<void> saveSearchTerm(String searchTerm) async {
    try {
      List<String> recentSearches = getRecentSearches();
      
      // Remove if already exists
      recentSearches.remove(searchTerm);
      
      // Add to beginning
      recentSearches.insert(0, searchTerm);
      
      // Keep only last 10 searches
      if (recentSearches.length > 10) {
        recentSearches = recentSearches.take(10).toList();
      }
      
      await saveSetting('recentSearches', recentSearches);
    } catch (e) {
      print('Error saving search term: $e');
    }
  }

  List<String> getRecentSearches() {
    try {
      final searches = getSetting<List>('recentSearches', defaultValue: []);
      return searches?.cast<String>() ?? [];
    } catch (e) {
      print('Error getting recent searches: $e');
      return [];
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      await saveSetting('recentSearches', []);
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }

  // Statistics Methods
  Map<String, dynamic> getStatistics() {
    try {
      final scans = getRecentScans();
      final totalScans = scans.length;
      final safeProducts = scans.where((s) => s.status == 'safe').length;
      final cautionProducts = scans.where((s) => s.status == 'caution').length;
      final warningProducts = scans.where((s) => s.status == 'warning').length;
      
      // Calculate average score from scan history
      double averageScore = 0.0;
      if (totalScans > 0) {
        double totalScore = 0.0;
        for (final scan in scans) {
          // Calculate safety score for each scan using same logic as history page
          double score = 10.0;
          score -= scan.additiveRisks.length * 2.0;
          
          if (scan.nutritionGrade != null) {
            switch (scan.nutritionGrade!) {
              case 1: break; // A grade - No deduction
              case 2: score -= 0.5; break; // B grade
              case 3: score -= 1.0; break; // C grade
              case 4: score -= 1.5; break; // D grade
              case 5: score -= 2.0; break; // E grade
            }
          }
          
          if (scan.novaGroup != null && scan.novaGroup! > 2) {
            score -= (scan.novaGroup! - 2) * 1.0;
          }
          
          totalScore += score.clamp(0.0, 10.0);
        }
        averageScore = totalScore / totalScans;
      }
      
      return {
        'totalScans': totalScans,
        'safeProducts': safeProducts,
        'cautionProducts': cautionProducts,
        'warningProducts': warningProducts,
        'safePercentage': totalScans > 0 ? (safeProducts / totalScans * 100).round() : 0,
        'averageScore': averageScore,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalScans': 0,
        'safeProducts': 0,
        'cautionProducts': 0,
        'warningProducts': 0,
        'safePercentage': 0,
        'averageScore': 0.0,
      };
    }
  }
}
