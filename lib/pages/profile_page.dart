import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/notification_service.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';
import 'about_page.dart'; // <-- IMPORT HALAMAN BARU
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _loggedInUser;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _loggedInUser = prefs.getString('loggedInUser');
      });
    }
  }

  // ... (Fungsi _logout dan _activateManualReminder SAMA PERSIS) ...
  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
    }
  }
  void _activateManualReminder(BuildContext context) async {
    final notificationService = NotificationService();
    await notificationService.requestPermissions();
    await notificationService.scheduleNotificationNow(
      title: "Tes Manual Notifikasi", body: "Ini adalah notifikasi tes manual.",
      delaySeconds: 3, notificationId: 3
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notifikasi tes akan muncul dalam 3 detik!"))
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        Hive.box('bookBox').listenable(),
        Hive.box('logBox').listenable(),
        Hive.box('profileBox').listenable(),
      ]),
      builder: (context, child) {
        
        if (_loggedInUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Profil")),
            body: const Center(child: CircularProgressIndicator(color: primaryPurple)),
          );
        }

        // --- Ambil Data (SAMA) ---
        final bookBox = Hive.box('bookBox');
        final logBox = Hive.box('logBox');
        final profileBox = Hive.box('profileBox');

        var profile = profileBox.get(_loggedInUser);
        Map<String, dynamic> userProfile = {};
        int userLevel = 1, userXp = 0;
        int xpToNextLevel = xpForNextLevel(1);
        double xpProgress = 0.0;

        if (profile != null) {
          userProfile = Map<String, dynamic>.from(profile as Map);
          userLevel = userProfile['level'] ?? 1;
          userXp = userProfile['xp'] ?? 0;
          xpToNextLevel = xpForNextLevel(userLevel);
          xpProgress = (xpToNextLevel > 0) ? (userXp / xpToNextLevel) : 0.0;
        }

        final userBooks = bookBox.values.where((book) => (book as Map)['username'] == _loggedInUser).toList();
        final userLogs = logBox.values.where((log) => (log as Map)['username'] == _loggedInUser).toList();
        final int totalFinishedBooks = userBooks.where((book) => (book as Map)['status'] == 'Finished').length;
        final int totalLogs = userLogs.length;
        int totalPagesRead = 0;
        for (var bookMap in userBooks) {
          totalPagesRead += (bookMap as Map)['currentPage'] as int? ?? 0;
        }
        bool hasUsedLBS = userLogs.any((log) => (log as Map)['latitude'] != null);

        // --- UI PROFIL (PERBAIKAN TOTAL SESUAI PERMINTAAN) ---
        return Scaffold(
          appBar: AppBar(
            title: const Text("Profil"),
            automaticallyImplyLeading: false, 
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 1. Info Pengguna (Req 1, 2, 3) ---
                Card(
                  color: primaryPurple, // <-- REQ 1: KARTU KEPALA BERWARNA
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                    child: Column( 
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loggedInUser ?? "Pengguna", // Nama
                          style: const TextStyle(
                            fontSize: 24, // <-- REQ 2: FONT LEBIH KECIL
                            fontWeight: FontWeight.bold, 
                            color: Colors.white // Teks putih
                          ),
                        ),
                        const SizedBox(height: 16), // Jarak
                        // --- REQ 3: TAMBAHKAN XP BAR ---
                        Text(
                          "Level $userLevel ($userXp / $xpToNextLevel XP)", 
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: xpProgress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(accentYellow),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // --- AKHIR REQ 3 ---
                      ],
                    ),
                  ),
                ),

                // --- 2. Aktivitasmu (Req 4: Warna & Tinggi Sama) ---
                const SizedBox(height: 24),
                const Text("Aktivitasmu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      context, 
                      title: "Buku Selesai", 
                      value: totalFinishedBooks.toString(), 
                      color: accentGreen.withOpacity(0.15), // <-- REQ 4: WARNA BARU
                      icon: Icons.check_circle_rounded,
                      iconColor: accentGreen,
                    ),
                    _buildStatCard(
                      context, 
                      title: "Total Halaman", 
                      value: totalPagesRead.toString(), 
                      color: accentYellow.withOpacity(0.2), // <-- REQ 4: WARNA BARU
                      icon: Icons.menu_book_rounded,
                      iconColor: accentYellow,
                    ),
                    _buildStatCard(
                      context, 
                      title: "Total Sesi Log", 
                      value: totalLogs.toString(), 
                      color: accentPink.withOpacity(0.15), // <-- REQ 4: WARNA BARU
                      icon: Icons.edit_note_rounded,
                      iconColor: accentPink,
                    ),
                  ],
                ),

                // --- 3. Pencapaian (Req 5: Warna Berbeda) ---
                const SizedBox(height: 24),
                const Text("Pencapaian", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 16),
                
                _buildAchievement(
                  title: "Kutu Buku Pemula",
                  subtitle: "Selesaikan 1 buku pertama Anda.",
                  isUnlocked: (totalFinishedBooks >= 1),
                  progressValue: totalFinishedBooks.toDouble(),
                  targetValue: 1,
                  cardColor: accentGreen.withOpacity(0.15), // <-- REQ 5: WARNA BARU
                ),
                _buildAchievement(
                  title: "Maraton Pemula",
                  subtitle: "Capai 1.000 total halaman terbaca.",
                  isUnlocked: (totalPagesRead >= 1000),
                  progressValue: totalPagesRead.toDouble(),
                  targetValue: 1000,
                  cardColor: accentYellow.withOpacity(0.2), // <-- REQ 5: WARNA BARU
                ),
                _buildAchievement(
                  title: "Kolektor",
                  subtitle: "Miliki 5 buku di koleksi Anda.",
                  isUnlocked: (userBooks.length >= 5),
                  progressValue: userBooks.length.toDouble(),
                  targetValue: 5,
                  cardColor: accentPink.withOpacity(0.15), // <-- REQ 5: WARNA BARU
                ),
                _buildAchievement(
                  title: "Penjelajah",
                  subtitle: "Gunakan fitur Check-in LBS.",
                  isUnlocked: hasUsedLBS,
                  cardColor: primaryPurple.withOpacity(0.1), // <-- REQ 5: WARNA BARU
                ),
                
                // --- 4. Pengaturan (Req 6: Link ke Halaman Baru) ---
                const SizedBox(height: 24),
                const Text("Pengaturan & Lainnya", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded, color: primaryPurple),
                        title: const Text("Tentang Kami", style: TextStyle(color: textPrimary)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textSecondary),
                        onTap: () {
                           // --- REQ 6: PINDAH KE HALAMAN BARU ---
                           Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AboutPage()),
                           );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.notifications_active_rounded, color: primaryPurple),
                        title: const Text("Tes Notifikasi Manual", style: TextStyle(color: textPrimary)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: textSecondary),
                        onTap: () => _activateManualReminder(context),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: errorRed),
                        title: const Text("Logout", style: TextStyle(color: errorRed, fontWeight: FontWeight.bold)),
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
                 const SizedBox(height: 80), // Padding bawah
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HELPER WIDGET STATISTIK (Req 4: Tinggi Sama & Warna) ---
  Widget _buildStatCard(BuildContext context, 
    { required String title, required String value, required Color color, 
      required IconData icon, required Color iconColor }) {
    return Card(
      elevation: 0.0,
      color: color, // <-- REQ 4: WARNA DARI PARAMETER
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox( // <-- REQ 4: TINGGI SAMA
        height: 110, 
        width: (MediaQuery.of(context).size.width - 32 - 32) / 3.2, 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Pusatkan
            children: [
              Icon(icon, color: iconColor, size: 28), // <-- Tambah Ikon
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGET ACHIEVEMENT (Req 5: Warna Berbeda) ---
  Widget _buildAchievement({
    required String title,
    required String subtitle,
    required bool isUnlocked,
    double progressValue = 0.0,
    double targetValue = 1.0,
    required Color cardColor, // <-- REQ 5: WARNA DARI PARAMETER
  }) {
    double progressPercent = (targetValue > 0) ? (progressValue / targetValue) : 0.0;
    if (progressPercent > 1.0) progressPercent = 1.0; 

    return Card(
      color: isUnlocked ? cardBg : cardColor, // <-- REQ 5: Terapkan warna
      elevation: isUnlocked ? 2.0 : 0.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
          color: isUnlocked ? accentYellow : Colors.grey, 
          size: 40,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnlocked ? textPrimary : textSecondary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: isUnlocked ? textSecondary : Colors.grey[500],
              ),
            ),
            if (!isUnlocked && progressValue > 0) 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(primaryPurple),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${progressValue.toInt()} / ${targetValue.toInt()}",
                      style: const TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}