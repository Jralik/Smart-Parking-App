import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'ENTRY':
        return Icons.login;
      case 'EXIT':
        return Icons.logout;
      case 'TEMP_ALERT':
        return Icons.thermostat;
      case 'SLOT':
        return Icons.local_parking;
      default:
        return Icons.info;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'ENTRY':
        return Colors.blue;
      case 'EXIT':
        return Colors.green;
      case 'TEMP_ALERT':
        return Colors.red;
      case 'SLOT':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'ENTRY':
        return 'Vào bãi';
      case 'EXIT':
        return 'Ra bãi';
      case 'TEMP_ALERT':
        return 'Cảnh báo nhiệt';
      case 'SLOT':
        return 'Chỗ đỗ';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebase = context.watch<FirebaseService>();
    final historyList = firebase.historyList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hoạt động'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: historyList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có lịch sử',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Lịch sử sẽ xuất hiện khi ESP32 hoạt động',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: historyList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = historyList[index];
                final color = _colorForType(event.type);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconForType(event.type),
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _labelForType(event.type),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event.message,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Thời điểm: ${event.timestamp} ms',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
