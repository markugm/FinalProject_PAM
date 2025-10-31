import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/login_page.dart';
import 'utils/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
// import 'package:shared_preferences/shared_preferences.dart'; // Kita akan pakai ini nanti

// Fungsi main() adalah yang pertama kali dijalankan
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Notification Service
  await NotificationService().init();

  // Inisialisasi (menyalakan) Hive
  await Hive.initFlutter();

  tz.initializeTimeZones();

  // Membuka "kotak" (tabel) untuk menyimpan data user
  await Hive.openBox('userBox');
  // Membuka "kotak" (tabel) untuk menyimpan data buku
  await Hive.openBox('bookBox');
  // Membuka "kotak" (tabel) untuk menyimpan data log baca
  await Hive.openBox('logBox');
  await Hive.openBox('profileBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary',
      theme: ThemeData(
        // Atur warna primer agar AppBar dll otomatis pakai warna ini
        primaryColor: const Color(0xFF84994F),
        // Atur warna dasar
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF84994F)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false, // Menghilangkan banner "DEBUG"

      home: const LoginPage(), // Halaman pertama yang ditampilkan
    );
  }
}
