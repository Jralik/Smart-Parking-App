import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'notification_service.dart';

class MqttService extends ChangeNotifier {
  late MqttServerClient _client;
  bool isConnected = false;

  // Trạng thái realtime từ MQTT (cổng vào, cổng ra)
  String entryGate = 'CLOSED';
  String exitGate = 'CLOSED';
  bool carWaiting = false;
  String slotStatus = '000'; // "000" → "111"
  double temperature = 0.0;
  bool tempAlert = false;

  // Notification service
  final NotificationService _notif = NotificationService();

  static const String _host = 'broker.hivemq.com';
  static const String _clientId = 'smart-parking-flutter';

  // Topics publish
  static const String _topicCmdEntry = 'smart-parking/cmd/entry';

  // Topics subscribe
  static const String _topicStatusEntry = 'smart-parking/status/entry';
  static const String _topicStatusExit = 'smart-parking/status/exit';
  static const String _topicStatusSlots = 'smart-parking/status/slots';
  static const String _topicStatusTemp = 'smart-parking/status/temp';
  static const String _topicCarWaiting = 'smart-parking/status/carwaiting';
  static const String _topicAlertTemp = 'smart-parking/alert/temp';

  MqttService() {
    _connect();
  }

  Future<void> _connect() async {
    _client = MqttServerClient(_host, _clientId);
    _client.port = 1883;
    _client.keepAlivePeriod = 30;
    _client.logging(on: false);
    _client.autoReconnect = true;
    _client.onAutoReconnected = _onReconnected;
    _client.onDisconnected = _onDisconnected;

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .startClean();
    _client.connectionMessage = connMsg;

    try {
      await _client.connect();
      isConnected = true;
      _subscribeAll();
      _listenMessages();
      notifyListeners();
      print('[MQTT] Ket noi thanh cong');
    } catch (e) {
      print('[MQTT] Loi: $e');
      isConnected = false;
      notifyListeners();
    }
  }

  void _subscribeAll() {
    _client.subscribe(_topicStatusEntry, MqttQos.atLeastOnce);
    _client.subscribe(_topicStatusExit, MqttQos.atLeastOnce);
    _client.subscribe(_topicStatusSlots, MqttQos.atLeastOnce);
    _client.subscribe(_topicStatusTemp, MqttQos.atLeastOnce);
    _client.subscribe(_topicCarWaiting, MqttQos.atLeastOnce);
    _client.subscribe(_topicAlertTemp, MqttQos.atLeastOnce);
    print('[MQTT] Da subscribe tat ca topics');
  }

  void _listenMessages() {
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        final topic = msg.topic;
        final payload =
            (msg.payload as MqttPublishMessage).payload.message;
        final value =
            MqttPublishPayload.bytesToStringAsString(payload).trim();

        print('[MQTT] Nhan: $topic = $value');

        switch (topic) {
          case _topicStatusEntry:
            final oldGate = entryGate;
            entryGate = value;
            // Thông báo khi cổng vào mở
            if (value == 'OPEN' && value != oldGate) {
              _notif.notifyGateOpened('Cổng vào');
            }
            break;
          case _topicStatusExit:
            final oldGate = exitGate;
            exitGate = value;
            // Thông báo khi cổng ra mở
            if (value == 'OPEN' && value != oldGate) {
              _notif.notifyGateOpened('Cổng ra');
            }
            break;
          case _topicStatusSlots:
            final oldSlots = slotStatus;
            slotStatus = value;

            break;
          case _topicStatusTemp:
            temperature = double.tryParse(value) ?? temperature;
            break;
          case _topicCarWaiting:
            final wasWaiting = carWaiting;
            carWaiting = (value == 'YES');
            // ★ Thông báo khi có xe mới đến chờ
            if (carWaiting && !wasWaiting) {
              _notif.notifyCarWaiting();
            }
            break;
          case _topicAlertTemp:
            final wasAlert = tempAlert;
            tempAlert = (value == 'ALERT');
            // ★ Thông báo cảnh báo nhiệt độ
            if (tempAlert && !wasAlert) {
              _notif.notifyTempAlert(temperature);
            }
            break;
        }
        notifyListeners();
      }
    });
  }

  void _onReconnected() {
    print('[MQTT] Tu dong ket noi lai');
    isConnected = true;
    _subscribeAll();
    notifyListeners();
  }

  void _onDisconnected() {
    print('[MQTT] Mat ket noi');
    isConnected = false;
    notifyListeners();
  }

  // Gửi lệnh mở cổng vào
  void sendOpenEntry() {
    if (!isConnected) {
      print('[MQTT] Chua ket noi, khong gui duoc');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString('OPEN');
    _client.publishMessage(
        _topicCmdEntry, MqttQos.atLeastOnce, builder.payload!);
    print('[MQTT] Da gui lenh OPEN_ENTRY');
  }

  // Slot theo index (0, 1, 2)
  bool getSlot(int index) {
    if (slotStatus.length > index) {
      return slotStatus[index] == '1';
    }
    return false;
  }

  int get freeSlots =>
      (slotStatus.length >= 3)
          ? slotStatus.split('').where((c) => c == '0').length
          : 3;

  @override
  void dispose() {
    _client.disconnect();
    super.dispose();
  }
}
