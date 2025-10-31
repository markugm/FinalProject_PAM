import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/helpers.dart'; // For xpForNextLevel
import 'login_page.dart'; // For logout

// Changed to StatefulWidget
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// Changed to State
class _DashboardPageState extends State<DashboardPage> {
  // --- Define colors ---
  final Color oliveGreen = const Color(0xFF84994F);
  final Color warmOrange = const Color(0xFFFCB53B);
  final Color paleYellow = const Color(0xFFFFE797);
  String? _loggedInUser; // Variable to store the logged-in username

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Load username when the page starts
  }

  // --- Function to load username from SharedPreferences ---
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    // Use mounted check for safety in async operations
    if (mounted) {
      setState(() {
        _loggedInUser = prefs.getString('loggedInUser');
      });
    }
  }

  // --- Logout function ---
  void _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all session data

    // Navigate to LoginPage and remove all previous routes
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false, // Remove all routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Use AnimatedBuilder to listen to multiple Hive boxes ---
    return AnimatedBuilder(
      // Listen to changes in BOTH bookBox and logBox
      animation: Listenable.merge([
        Hive.box('bookBox').listenable(),
        Hive.box('logBox').listenable(),
        Hive.box('profileBox').listenable(),
      ]),
      builder: (context, child) {
        // The builder function
        // --- Show loading if username isn't loaded yet ---
        if (_loggedInUser == null) {
          // Provide a Scaffold during loading so the AppBar doesn't disappear
          return Scaffold(
            appBar: AppBar(
              title: const Text("Dashboard"),
              backgroundColor: oliveGreen,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // --- Get Hive boxes ---
        final bookBox = Hive.box('bookBox');
        final logBox = Hive.box('logBox');
        final profileBox = Hive.box('profileBox');

        //ambil data profile user
        var profile = profileBox.get(_loggedInUser);
        Map<String, dynamic> userProfile = {};

        int userLevel = 1;
        int userXp = 0;
        int userStreak = 1;
        int xpToNextLevel = xpForNextLevel(1);
        double xpProgress = 0.0;

        if (profile != null) {
          userProfile = Map<String, dynamic>.from(profile as Map);
          userLevel = userProfile['level'] ?? 1;
          userXp = userProfile['xp'] ?? 0;
          userStreak = userProfile['streak'] ?? 1;
          xpToNextLevel = xpForNextLevel(userLevel);
          xpProgress = (xpToNextLevel > 0) ? (userXp / xpToNextLevel) : 0.0;
        }

        // --- 1. FILTER DATA BY USERNAME ---
        final userBooks = bookBox.values.where((book) {
          try {
            final bookMap = Map<String, dynamic>.from(book as Map);
            return bookMap['username'] == _loggedInUser;
          } catch (e) {
            print("Error casting book data in Dashboard: $e");
            return false;
          } // Filter out invalid data
        }).toList();

        final userLogs = logBox.values.where((log) {
          try {
            final logMap = Map<String, dynamic>.from(log as Map);
            return logMap['username'] == _loggedInUser;
          } catch (e) {
            print("Error casting log data in Dashboard: $e");
            return false;
          } // Filter out invalid data
        }).toList();

        // --- 2. CALCULATE STATS (from filtered data) ---
        final int totalBooks = userBooks.length;
        final int totalFinishedBooks = userBooks
            .where((book) => (book as Map)['status'] == 'Finished')
            .length;
        final int totalLogs = userLogs.length;

        int totalPagesRead = 0;
        for (var bookMap in userBooks) {
          try {
            // Safely cast and add pages
            totalPagesRead += (bookMap as Map)['currentPage'] as int? ?? 0;
          } catch (e) {
            print("Error calculating total pages read: $e");
          }
        }

        // --- 3. CHECK ACHIEVEMENTS (from filtered data) ---
        bool hasUsedLBS = userLogs.any(
          (log) => (log as Map)['latitude'] != null,
        );

        // --- Return the main Scaffold for the Dashboard ---
        return Scaffold(
          appBar: AppBar(
            title: const Text("Dashboard"),
            backgroundColor: oliveGreen,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false, // No back button
          ),
          body: SingleChildScrollView(
            // Allow scrolling
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- SAPAAN PERSONAL (HILANG) ---
                Text(
                  'Selamat Datang, $_loggedInUser!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: oliveGreen,
                  ),
                ),

                // --- BLOK GAMIFICATION (HILANG) ---
                const SizedBox(height: 24),
                Card(
                  elevation: 2.0,
                  color: paleYellow, // Warna dari palette
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Baris Level & Streak
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Level $userLevel",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: oliveGreen,
                              ),
                            ),
                            Row(
                              // Streak
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  color: warmOrange,
                                  size: 30,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "$userStreak Hari",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // XP Progress Bar
                        LinearProgressIndicator(
                          value: xpProgress,
                          minHeight: 12, // Bikin tebal
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(warmOrange),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 4),
                        // Teks XP
                        Text(
                          "$userXp / $xpToNextLevel XP",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 48, thickness: 1),

                // --- Stats Section ---
                Text(
                  "Ringkasan Membaca",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: oliveGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard("Total Buku", totalBooks.toString()),
                    _buildStatCard(
                      "Buku Selesai",
                      totalFinishedBooks.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard("Total Halaman", totalPagesRead.toString()),
                    _buildStatCard("Sesi Baca", totalLogs.toString()),
                  ],
                ),

                const Divider(height: 48, thickness: 1), // Separator
                // --- Achievements Section ---
                Text(
                  "Pencapaian (Achievement)",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: oliveGreen,
                  ),
                ),
                const SizedBox(height: 16),

                // Achievement List (using filtered stats)
                _buildAchievement(
                  title: "Kutu Buku Pemula",
                  subtitle: "Selesaikan 1 buku pertama Anda.",
                  isUnlocked: (totalFinishedBooks >= 1),
                  progressValue: totalFinishedBooks.toDouble(), // <-- Progres saat ini
                  targetValue: 1, // <-- Target
                ),
                _buildAchievement(
                  title: "Maraton Pemula",
                  subtitle: "Capai 1.000 total halaman terbaca.",
                  isUnlocked: (totalPagesRead >= 1000),
                  progressValue: totalPagesRead.toDouble(), // <-- Progres saat ini
                  targetValue: 1000, // <-- Target
                ),
                _buildAchievement(
                  title: "Kolektor",
                  subtitle: "Miliki 5 buku di koleksi Anda.",
                  isUnlocked: (totalBooks >= 5),
                  progressValue: totalBooks.toDouble(), // <-- Progres saat ini
                  targetValue: 5, // <-- Target
                ),
                _buildAchievement(
                  title: "Penjelajah",
                  subtitle: "Gunakan fitur Check-in LBS.",
                  isUnlocked: hasUsedLBS,
                  // Tidak perlu progress bar, karena ini 0 atau 1
                ),

              ],
            ),
          ),
        );
      }, // End of AnimatedBuilder builder
    ); // End of AnimatedBuilder
  }

  // --- Helper widget for Stat Cards (No changes needed) ---
  Widget _buildStatCard(String title, String value) {
    return Card(
      elevation: 2.0,
      color: paleYellow, // Use color from palette
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: oliveGreen,
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

// --- Helper widget untuk list Achievement (Kode BARU dengan Progress Bar) ---
  Widget _buildAchievement({
    required String title,
    required String subtitle,
    required bool isUnlocked,
    double progressValue = 0.0, // <-- BARU: Progres saat ini (misal: 300)
    double targetValue = 1.0, // <-- BARU: Target (misal: 1000)
  }) {
    // Hitung persColor.fromARGB(255, 96, 67, 67)es (0.0 sampai 1.0)
    double progressPercent = (targetValue > 0) ? (progressValue / targetValue) : 0.0;
    if (progressPercent > 1.0) progressPercent = 1.0; // Pastikan tidak lebih dari 100%

    return Card(
      color: isUnlocked ? Colors.white : Colors.grey[100],
      elevation: isUnlocked ? 3.0 : 0.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          isUnlocked ? Icons.verified_rounded : Icons.lock_outline_rounded,
          color: isUnlocked ? warmOrange : Colors.grey,
          size: 40,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isUnlocked ? Colors.black : Colors.grey[600],
          ),
        ),
        subtitle: Column( // <-- BARU: Ubah Subtitle jadi Column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: isUnlocked ? Colors.black87 : Colors.grey[500],
              ),
            ),
            // --- BARU: Tampilkan Progress Bar jika BELUM UNLOCKED ---
            if (!isUnlocked && progressValue > 0) 
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: progressPercent,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(oliveGreen),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${progressValue.toInt()} / ${targetValue.toInt()}", // Teks (300 / 1000)
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} // <-- End of _DashboardPageState class
