import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../services/firebase_service.dart';
import '../services/mqtt_service.dart';
import '../widgets/slot_card.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  // ── Xác thực vân tay rồi mở cổng ──────────────
  Future<void> _authenticateAndOpen() async {
    final mqtt = context.read<MqttService>();

    try {
      // Gọi thẳng authenticate — MIUI trả getAvailableBiometrics() rỗng
      // dù đã đăng ký vân tay, nên không dùng check đó
      final auth = await _auth.authenticate(
        localizedReason: 'Đặt ngón tay lên cảm biến để mở cổng vào',
        options: const AuthenticationOptions(
          biometricOnly: true,  // Chỉ vân tay / khuôn mặt
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (auth) {
        mqtt.sendOpenEntry();
        _showSnackbar('✅ Vân tay hợp lệ! Đã mở cổng.', Colors.green);
      } else {
        _showSnackbar('❌ Xác thực vân tay thất bại', Colors.red);
      }
    } on Exception catch (e) {
      final msg = e.toString();
      print('[AUTH] Loi: $msg');

      // Thiết bị thực sự không hỗ trợ biometric → fallback PIN
      if (msg.contains('NotAvailable') ||
          msg.contains('NotEnrolled') ||
          msg.contains('no_fragment_activity') ||
          msg.contains('PasscodeNotSet')) {
        _showPinDialog();
      } else {
        // Lỗi khác (người dùng huỷ, v.v.) → không làm gì
        _showSnackbar('❌ Đã huỷ xác thực', Colors.orange);
      }
    }
  }

  // ── Dialog PIN backup khi không có vân tay ─────
  void _showPinDialog() {
    final pinController = TextEditingController();
    const correctPin = '1234'; // Đổi PIN theo ý bạn

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pin, color: Colors.blue),
            SizedBox(width: 8),
            Text('Nhập mã PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chưa đăng ký vân tay.\nNhập PIN để mở cổng.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'PIN 4 số',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == correctPin) {
                Navigator.pop(ctx);
                final mqtt = context.read<MqttService>();
                mqtt.sendOpenEntry();
                _showSnackbar('✅ PIN đúng! Đã mở cổng.', Colors.green);
              } else {
                _showSnackbar('❌ PIN sai!', Colors.red);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    // MQTT là nguồn chính (realtime), Firebase là backup
    final mqtt = context.watch<MqttService>();
    final firebase = context.watch<FirebaseService>();

    // Ưu tiên MQTT, fallback Firebase
    final entryGate =
        mqtt.isConnected ? mqtt.entryGate : firebase.entryGate;
    final exitGate =
        mqtt.isConnected ? mqtt.exitGate : firebase.exitGate;
    final carWaiting =
        mqtt.isConnected ? mqtt.carWaiting : firebase.carWaiting;
    final temperature =
        mqtt.isConnected ? mqtt.temperature : firebase.temperature;
    final slot1 = mqtt.isConnected ? mqtt.getSlot(0) : firebase.slot1;
    final slot2 = mqtt.isConnected ? mqtt.getSlot(1) : firebase.slot2;
    final slot3 = mqtt.isConnected ? mqtt.getSlot(2) : firebase.slot3;
    final freeSlots = (slot1 ? 0 : 1) + (slot2 ? 0 : 1) + (slot3 ? 0 : 1);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          '🚗 Smart Parking',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Trạng thái kết nối MQTT ──────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: mqtt.isConnected ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: mqtt.isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mqtt.isConnected ? 'MQTT: Đã kết nối' : 'MQTT: Mất kết nối',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Thông tin tổng quan ───────────────
            Row(
              children: [
                _InfoCard(
                  icon: Icons.local_parking,
                  label: 'Chỗ trống',
                  value: '$freeSlots/3',
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _InfoCard(
                  icon: Icons.thermostat,
                  label: 'Nhiệt độ',
                  value: '${temperature.toStringAsFixed(1)}°C',
                  color: temperature > 50 ? Colors.red : Colors.orange,
                ),
              ],
            ),

            // Cảnh báo nhiệt độ cao
            if (mqtt.tempAlert) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      '⚠️ NHIỆT ĐỘ QUÁ CAO! Nguy hiểm!',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ── Sơ đồ chỗ đỗ ─────────────────────
            const Text(
              'Sơ đồ bãi xe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                SlotCard(slotNumber: 1, isOccupied: slot1),
                SlotCard(slotNumber: 2, isOccupied: slot2),
                SlotCard(slotNumber: 3, isOccupied: slot3),
              ],
            ),
            const SizedBox(height: 16),

            // ── Trạng thái cổng ───────────────────
            const Text(
              'Trạng thái cổng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _GateCard(label: 'Cổng vào', state: entryGate),
                const SizedBox(width: 12),
                _GateCard(label: 'Cổng ra', state: exitGate),
              ],
            ),
            const SizedBox(height: 16),

            // ── Có xe chờ ─────────────────────────
            if (carWaiting)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Có xe đang chờ vào!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Nút mở cổng vào ───────────────────
            const Text(
              'Điều khiển',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                // Chỉ cho phép mở cổng khi có xe đang chờ
                onPressed: carWaiting ? _authenticateAndOpen : null,
                icon: const Icon(Icons.lock_open),
                label: Text(
                  carWaiting ? '🔓 Xác thực vân tay để mở cổng' : '🔒 Chờ xe đến cổng...',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: carWaiting ? Colors.green : Colors.grey[300],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget phụ ────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GateCard extends StatelessWidget {
  final String label, state;
  const _GateCard({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final isOpen = state == 'OPEN';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOpen ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isOpen ? Colors.green : Colors.grey),
        ),
        child: Column(
          children: [
            Icon(
              isOpen ? Icons.door_front_door : Icons.door_front_door_outlined,
              color: isOpen ? Colors.green : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              isOpen ? '🟢 Đang mở' : '🔴 Đã đóng',
              style: TextStyle(
                color: isOpen ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
