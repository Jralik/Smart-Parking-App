import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// Model cho từng sự kiện lịch sử
class HistoryEvent {
  final String type;
  final String message;
  final String timestamp;

  HistoryEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });

  factory HistoryEvent.fromMap(Map<dynamic, dynamic> map) {
    return HistoryEvent(
      type: map['type']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      timestamp: map['timestamp']?.toString() ?? '',
    );
  }
}

class FirebaseService extends ChangeNotifier {
  final _db = FirebaseDatabase.instance;

  // Trạng thái từ Realtime DB (backup cho MQTT)
  bool slot1 = false, slot2 = false, slot3 = false;
  String entryGate = 'CLOSED', exitGate = 'CLOSED';
  double temperature = 0.0;
  bool carWaiting = false;

  // Lịch sử (đọc từ Realtime DB — khớp với ESP32 pushJSON)
  List<HistoryEvent> historyList = [];

  FirebaseService() {
    _listenToStatus();
    _listenToHistory();
  }

  // Lắng nghe trạng thái realtime
  void _listenToStatus() {
    _db.ref().onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      final slots = data['slots'] as Map? ?? {};
      final gates = data['gates'] as Map? ?? {};

      slot1 = slots['slot1'] == true;
      slot2 = slots['slot2'] == true;
      slot3 = slots['slot3'] == true;
      entryGate = gates['entry']?.toString() ?? 'CLOSED';
      exitGate = gates['exit']?.toString() ?? 'CLOSED';
      temperature = (data['temperature'] as num?)?.toDouble() ?? 0.0;
      carWaiting = data['carWaiting'] == true;

      notifyListeners();
    }, onError: (e) {
      print('[FIREBASE] Loi doc trang thai: $e');
    });
  }

  // Lắng nghe lịch sử từ Realtime DB (ESP32 dùng pushJSON → /history)
  void _listenToHistory() {
    _db.ref('history').limitToLast(50).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        historyList = [];
        notifyListeners();
        return;
      }

      final events = data.entries
          .map((e) => HistoryEvent.fromMap(e.value as Map<dynamic, dynamic>))
          .toList()
        ..sort((a, b) {
          // Sort giảm dần theo timestamp (mới nhất lên đầu).
          // Chuỗi định dạng "YYYY-MM-DD HH:MM:SS" có thể so sánh chuỗi trực tiếp.
          return b.timestamp.compareTo(a.timestamp);
        });

      historyList = events;
      notifyListeners();
    }, onError: (e) {
      print('[FIREBASE] Loi doc lich su: $e');
    });
  }

  int get freeSlots =>
      (!slot1 ? 1 : 0) + (!slot2 ? 1 : 0) + (!slot3 ? 1 : 0);
}
