import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz; // Wajib import lagi

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Inisialisasi Service (Tidak perlu tz.initialize di sini)
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    // Kita panggil tz.initializeTimeZones() di main.dart saja
  }

  // 2. Minta Izin (INI BAGIAN YANG LENGKAP)
  Future<void> requestPermissions() async {
    // Minta izin dasar untuk post notifikasi (Android 13+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Minta izin untuk alarm terjadwal (penting untuk zonedSchedule)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // 3. Jadwalkan Notifikasi (Kembali ke zonedSchedule yang benar)
  Future<void> scheduleNotificationNow({
    required String title,
    required String body,
    int delaySeconds = 3,
    int notificationId = 2 // Pakai ID 2 untuk notif log
  }) async {
    // Tentukan waktu notifikasi: sekarang + delaySeconds
    final DateTime triggerTime = DateTime.now().add(Duration(seconds: delaySeconds));

    // --- KONVERSI WAKTU KE TZDateTime (INI KUNCINYA) ---
    // Pastikan zona waktu lokal sudah di-set (sebaiknya di initState aplikasi atau main)
    try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // Atau zona waktu device
    } catch (e) {
        print("Error setting timezone location: $e");
        // Fallback jika timezone belum siap
         tz.initializeTimeZones(); // Coba inisialisasi lagi
         try {
             tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
         } catch (e2) {
             print("Error setting timezone location after retry: $e2");
             // Jika masih gagal, gunakan UTC sebagai fallback
             tz.setLocalLocation(tz.UTC);
         }
    }
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(triggerTime, tz.local);
    // --- AKHIR KONVERSI ---


    // Batalkan notifikasi lama dengan ID yang sama
    await flutterLocalNotificationsPlugin.cancel(notificationId);

    // Detail notifikasi (channel ID bisa sama atau beda)
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'immediate_reminder_channel_v4', // ID Channel baru lagi
      'Immediate Action Reminder',
      channelDescription: 'Channel untuk notifikasi setelah aksi user',
      importance: Importance.max,       // Pastikan High Importance
      priority: Priority.high,          // Pastikan High Priority
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    print("MENJADWALKAN notifikasi (zoned) SEKARANG...");

    // Gunakan zonedSchedule lagi
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate, // Pakai TZDateTime yang sudah dikonversi
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Izinkan saat idle
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    print("Notifikasi ($notificationId) dijadwalkan: '$title' pada $scheduledDate");
  }
} // <-- Akhir Class