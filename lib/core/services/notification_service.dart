import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;

    // Create Android notification channel for schedule reminders
    const androidChannel = AndroidNotificationChannel(
      'schedule_reminders',
      '日程提醒',
      description: '日程和番茄钟相关通知',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  int _notificationId = 0;

  Future<void> showScheduleReminder(String title, String body) async {
    await _show(title, body);
  }

  Future<void> showFocusComplete() async {
    await _show('番茄钟完成', '恭喜你完成了专注时段，休息一下吧。');
  }

  Future<void> showEveningReminder() async {
    await _show('晚间复盘', '今天收获了什么？花 2 分钟回顾一下吧。');
  }

  Future<void> _show(String title, String body) async {
    if (!_initialized) return;
    final id = _notificationId++;
    const androidDetails = AndroidNotificationDetails(
      'schedule_reminders',
      '日程提醒',
      channelDescription: '日程和番茄钟相关通知',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    try {
      await _plugin.show(id, title, body, details);
    } catch (_) {
      // Silently ignore on unsupported platforms (e.g. Windows debug)
    }
  }
}
