import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/login_page.dart';
import 'utils/notification_service.dart';
import 'utils/constants.dart';
import 'pages/splash_page.dart';
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
      debugShowCheckedModeBanner: false, // Menghilangkan banner "DEBUG"

      theme: ThemeData(
        scaffoldBackgroundColor: scaffoldBg, // Latar belakang Off-white
        primaryColor: primaryPurple, 
        fontFamily: 'Inter', 

        appBarTheme: AppBarTheme(
          backgroundColor: scaffoldBg, // Latar belakang AppBar Off-white
          foregroundColor: textPrimary,   // Teks AppBar Hitam Pekat
          elevation: 0,                   // Hilangkan bayangan
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple, // Warna tombol (Ungu)
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // Tombol lebih 'chunky'
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0), // Rounded
            ),
            elevation: 2.0,
          ),
        ),

        // Tema Input Field (Lebih modern)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardBg,
          hintStyle: const TextStyle(color: textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1), // Border tipis
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: const BorderSide(color: primaryPurple, width: 2.0),
          ),
        ),

        // Tema SnackBar (Floating)
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating, // Tetap floating
          backgroundColor: textPrimary.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          insetPadding: const EdgeInsets.all(16.0),
          elevation: 4.0,
        ),
        
        // Tema Card (Kartu)
        cardTheme: CardThemeData(
          elevation: 2.0,
          color: cardBg,
          shadowColor: primaryPurple.withOpacity(0.05), // Bayangan ungu lembut
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Kartu lebih rounded
          ),
        ),
      ),

      home: const SplashPage(), // Halaman pertama yang ditampilkan
    );
  }
}
