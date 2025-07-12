import 'package:flutter/material.dart';

class ScanCard extends StatelessWidget {
  const ScanCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}
