import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;

  // Notification channel cho Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'smart_parking_alerts',
    'Smart Parking Alerts',
    description: 'Thông báo từ hệ thống bãi xe thông minh',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  Future<void> init() async {
    if (_initialized) return;

    // ── 1. Khởi tạo Local Notifications ──────────
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotif.initialize(initSettings);

    // Tạo notification channel (Android 8+)
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // ── 2. Xin quyền Notification (Android 13+) ──
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ── 3. Lấy FCM Token (debug) ────────────────
    try {
      final token = await _fcm.getToken();
      print('[FCM] Token: $token');
    } catch (e) {
      print('[FCM] Lỗi khi lấy token: $e');
    }

    // ── 4. Lắng nghe FCM khi app đang mở ────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FCM] Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        showNotification(
          title: message.notification!.title ?? 'Smart Parking',
          body: message.notification!.body ?? '',
        );
      }
    });

    _initialized = true;
    print('[NOTIFICATION] Khoi tao thanh cong');
  }

  // ── Hiển thị thông báo trên điện thoại ─────────
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    await _localNotif.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  // ── Thông báo cụ thể cho từng sự kiện ─────────
  void notifyCarWaiting() {
    showNotification(
      id: 1,
      title: '🚗 Có xe đang chờ!',
      body: 'Xe đang chờ ở cổng vào. Mở app để xác thực vân tay.',
    );
  }

  void notifyTempAlert(double temp) {
    showNotification(
      id: 2,
      title: '🔥 CẢNH BÁO NHIỆT ĐỘ!',
      body: 'Nhiệt độ bãi xe: ${temp.toStringAsFixed(1)}°C — Nguy hiểm!',
    );
  }

  void notifyGateOpened(String gate) {
    showNotification(
      id: 3,
      title: '🚧 Cổng đã mở',
      body: '$gate đã được mở.',
    );
  }

  void notifyGateClosed(String gate) {
    showNotification(
      id: 4,
      title: '🔒 Cổng đã đóng',
      body: '$gate đã đóng lại.',
    );
  }

  void notifySlotChange(String slotStatus) {
    final free = slotStatus.split('').where((c) => c == '0').length;
    if (free == 0) {
      showNotification(
        id: 5,
        title: '🅿️ Bãi xe đã đầy!',
        body: 'Tất cả 3 chỗ đỗ đều đã có xe.',
      );
    }
  }
}
