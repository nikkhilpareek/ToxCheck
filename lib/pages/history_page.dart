import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ScanStatus { safe, caution, warning }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final List<Map<String, dynamic>> _history = [
    {"name": "Maggi 2-Minute Noodles", "time": "2h ago", "status": "warning", "score": 6.2},
    {"name": "Coca-Cola Original", "time": "1d ago", "status": "caution", "score": 5.8},
    {"name": "Organic Valley Milk", "time": "2d ago", "status": "safe", "score": 8.5},
    {"name": "Lay's Classic Chips", "time": "3d ago", "status": "warning", "score": 4.2},
    {"name": "Amul Fresh Paneer", "time": "4d ago", "status": "safe", "score": 9.1},
    {"name": "Britannia Good Day", "time": "5d ago", "status": "caution", "score": 6.8},
    {"name": "Haldiram's Bhujia", "time": "6d ago", "status": "warning", "score": 5.2},
    {"name": "Mother Dairy Curd", "time": "1w ago", "status": "safe", "score": 8.9},
  ];

  void _deleteHistoryItem(int index) {
    final deletedItem = _history[index];

    setState(() => _history.removeAt(index));

    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${deletedItem["name"]} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _history.insert(index, deletedItem);
            });
          },
        ),
      ),
    );
  }

  ScanStatus _parseStatus(String status) {
    switch (status) {
      case "safe":
        return ScanStatus.safe;
      case "caution":
        return ScanStatus.caution;
      case "warning":
      default:
        return ScanStatus.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1F24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D1F24),
        elevation: 0,
        title: const Text(
          "Scan History",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => setState(() => _history.clear()),
            icon: const Icon(Icons.clear_all, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _history.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.history, size: 64, color: Colors.white30),
                    SizedBox(height: 16),
                    Text("No scan history yet", style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat Cards
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Total", "${_history.length}", Icons.qr_code_2_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard("Safe", "${_history.where((e) => e['status'] == 'safe').length}", Icons.check_circle_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard("Warnings", "${_history.where((e) => e['status'] == 'warning').length}", Icons.cancel_rounded)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Filter Chips (non-functional)
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilter("All", true),
                        _buildFilter("Today", false),
                        _buildFilter("This Week", false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Recent Scans",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dismissible List
                  Expanded(
                    child: ListView.separated(
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return Dismissible(
                          key: Key(item["name"] + item["time"]),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteHistoryItem(index),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: InkWell(
                            onTap: () {
                              // TODO: Navigate to details screen
                            },
                            child: _buildHistoryTile(item),
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272A32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: const Color(0xFFF5FFA8)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildFilter(String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {},
        selectedColor: const Color(0xFFF5FFA8),
        backgroundColor: const Color(0xFF272A32),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF1D1F24) : Colors.white,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> product) {
    final status = _parseStatus(product['status']);
    late Color statusColor;
    late IconData statusIcon;

    switch (status) {
      case ScanStatus.safe:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case ScanStatus.caution:
        statusColor = Colors.amber;
        statusIcon = Icons.error_outline_rounded;
        break;
      case ScanStatus.warning:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF272A32),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['name'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 4),
                Text(product['time'], style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product['score'].toString(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
