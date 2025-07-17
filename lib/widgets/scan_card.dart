import 'package:flutter/material.dart';
import '../services/qr_scanner_service.dart';
import '../services/product_service.dart';
import '../services/local_storage_service.dart';
import '../services/toxic_additive_service.dart';
import '../pages/product_details_page.dart';

class ScanCard extends StatelessWidget {
  const ScanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _startScan(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5FFA8), Color(0xFFDFF6C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: const Color(0xFFF5FFA8).withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 5),
              ),
            ],
        ),
        child: Stack(
          children: [
            Align(
                alignment: Alignment.center,
                child: Text(
                  "Tap to Scan",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color.fromARGB(197, 36, 36, 36),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.qr_code_scanner,
                  color: Colors.black87.withOpacity(0.3),
                  size: 80,
                ),
              ),
      
          ],
        ),
        
      ),
    );
  }

  Future<void> _startScan(BuildContext context) async {
    // Check camera permission
    final hasPermission = await QRScannerService.checkCameraPermission();
    if (!hasPermission) {
      final granted = await QRScannerService.requestCameraPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to scan barcodes'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Navigate to scanner
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QRScannerWidget(
            onScan: (barcode) => _handleScan(context, barcode),
          ),
        ),
      );
    }
  }

  Future<void> _handleScan(BuildContext context, String barcode) async {
    Navigator.pop(context); // Close scanner

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF5FFA8),
          ),
        ),
      );
    }

    try {
      final productService = ProductService();
      final storageService = LocalStorageService();
      final toxicService = ToxicAdditiveService();

      // Fetch product
      final product = await productService.fetchProduct(barcode);
      
      if (product == null) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product not found in database'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Analyze product and save to history
      final analysis = await toxicService.analyzeProduct(product);
      await storageService.saveScan(analysis);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      // Navigate to product details
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              product: product,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
