import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import '../utils/notification_service.dart'; // Import service notifikasi
import 'login_page.dart'; // Import LoginPage untuk logout

// DIUBAH jadi StatefulWidget
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// DIUBAH jadi State
class _ProfilePageState extends State<ProfilePage> {
  // Definisikan warna
  final Color oliveGreen = const Color(0xFF84994F);
  final Color warmOrange = const Color(0xFFFCB53B);
  final Color paleYellow = const Color(0xFFFFE797);
  final Color burntRed = const Color(0xFFA72703); // Untuk tombol logout

  String _loggedInUser = "Pengguna"; // Nilai default

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Panggil fungsi ambil username
  }

  // --- FUNGSI BARU: Ambil Username ---
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _loggedInUser = prefs.getString('loggedInUser') ?? "Pengguna";
      });
    }
  }

  // --- FUNGSI BARU: Logout (Pindahan dari Dashboard) ---
  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua session

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false, // Hapus semua rute
      );
    }
  }

  // Fungsi tes notifikasi (sama seperti sebelumnya)
  void _activateManualReminder(BuildContext context) async {
    final notificationService = NotificationService();
    await notificationService.requestPermissions();
    await notificationService.scheduleNotificationNow(
        title: "Tes Manual Notifikasi",
        body: "Ini adalah notifikasi tes manual.",
        delaySeconds: 3,
        notificationId: 3);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Notifikasi tes akan muncul dalam 3 detik!"),
          backgroundColor: oliveGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: oliveGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: paleYellow,
              child: Icon(Icons.person, size: 60, color: oliveGreen),
            ),
            const SizedBox(height: 16),
            
            // --- TAMPILKAN USERNAME ---
            Text(
              _loggedInUser, // Tampilkan nama user yang login
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // --- Tombol Tes Notifikasi ---
            ElevatedButton.icon(
              icon: const Icon(Icons.notifications_active),
              label: const Text("Tes Notifikasi Manual (3 dtk)"),
              onPressed: () => _activateManualReminder(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: warmOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
              ),
            ),
            const SizedBox(height: 16),

            // --- TOMBOL LOGOUT BARU ---
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              onPressed: () => _logout(context), // Panggil fungsi logout
              style: ElevatedButton.styleFrom(
                backgroundColor: burntRed, // Warna merah
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}