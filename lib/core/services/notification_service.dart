import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar click en notificación
      },
    );
  }

  Future<void> showFrostAlert({required String recommendation}) async {
    const androidDetails = AndroidNotificationDetails(
      'frost_alerts',
      'Alertas de Helada',
      channelDescription: 'Notificaciones cuando hay riesgo alto de helada',
      importance: Importance.max,
      priority: Priority.high,
      color: Color(0xFFC1440E),
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(android: androidDetails, iOS: iosSettings);
    
    await _notifications.show(
      0,
      '🚨 ¡Alerta de Helada!',
      recommendation,
      details,
    );
  }

  Future<void> scheduleFrostCheck({required String recommendation}) async {
    await _notifications.zonedSchedule(
      1,
      '🚨 Recordatorio de Helada',
      'El riesgo para hoy es ALTO. Recomendación: $recommendation',
      _nextInstanceOfSixPM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'frost_scheduled',
          'Recordatorios Programados',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfSixPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

const iosSettings = DarwinNotificationDetails();
