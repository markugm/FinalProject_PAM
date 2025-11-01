import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/helpers.dart'; // Untuk xpForNextLevel & updateStreak
import '../utils/constants.dart'; // Import warna BARU
import 'book_detail_page.dart'; // Kita butuh ini untuk navigasi 'Koleksimu'

// Dashboard sekarang adalah 'Home'
class DashboardPage extends StatefulWidget {
  // Callback untuk pindah tab
  final VoidCallback onNavigateToSearch;
  final VoidCallback onNavigateToCollection;

  const DashboardPage({
    super.key,
    required this.onNavigateToSearch,
    required this.onNavigateToCollection,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _loggedInUser;
  // Kita butuh bookBox di sini untuk list buku terbaru
  final Box bookBox = Hive.box('bookBox');

  @override
  void initState() {
    super.initState();
    _loadUsernameAndStreak(); // Muat username DAN update streak
  }

  // Muat username DAN update streak
  Future<void> _loadUsernameAndStreak() async {
    final prefs = await SharedPreferences.getInstance();
    String? user = prefs.getString('loggedInUser');

    if (mounted) {
      setState(() {
        _loggedInUser = user;
      });
    }
    
    // Logic Streak tetap di sini (ini pemicu utamanya)
    if (user != null) {
      await updateStreak(user); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kita dengarkan profileBox (untuk XP/Level) & bookBox (untuk Koleksimu)
    return AnimatedBuilder(
      animation: Listenable.merge([
        Hive.box('profileBox').listenable(),
        Hive.box('bookBox').listenable(),
      ]),
      builder: (context, child) {
        
        // --- Tampilkan loading jika username belum siap ---
        if (_loggedInUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Home")), // Judul baru
            body: const Center(child: CircularProgressIndicator(color: primaryPurple))
          );
        }

        // --- Ambil Data Gamification ---
        final profileBox = Hive.box('profileBox');
        var profile = profileBox.get(_loggedInUser);
        
        int userLevel = 1;
        int userXp = 0;
        int userStreak = 1;
        int xpToNextLevel = xpForNextLevel(1);
        double xpProgress = 0.0;

        if (profile != null) {
          final userProfile = Map<String, dynamic>.from(profile as Map);
          userLevel = userProfile['level'] ?? 1;
          userXp = userProfile['xp'] ?? 0;
          userStreak = userProfile['streak'] ?? 1;
          xpToNextLevel = xpForNextLevel(userLevel);
          xpProgress = (xpToNextLevel > 0) ? (userXp / xpToNextLevel) : 0.0;
        }

        // --- Ambil 3 Buku Terbaru (Helper di bawah) ---
        final recentBooks = _getRecentBooks(bookBox: bookBox, loggedInUser: _loggedInUser!);

        // --- UI BARU (VIBRANT & COLORFUL) ---
        return Scaffold(
          // Kita tidak pakai AppBar agar lebih 'full screen'
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Header (Greetings) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 60.0, 20.0, 24.0), // Padding atas lebih besar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang,',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        _loggedInUser ?? 'Reader', // Tampilkan nama
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- 2. Gamification Card (COLORFUL) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      // Pakai GRADIENT sesuai referensi
                      gradient: LinearGradient(
                        colors: [primaryPurple, primaryPurple.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24.0), // Lebih rounded
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Level (dengan Ikon)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Level $userLevel",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Streak (dengan Ikon)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.local_fire_department_rounded, color: accentPink, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$userStreak Hari",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        // XP Progress Bar
                        LinearProgressIndicator(
                          value: xpProgress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(accentYellow), // Warna kuning
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$userXp / $xpToNextLevel XP",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),
                ),

                // --- 3. Tombol "Baca Buku Baru >" (Sesuai Wireframe) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0.0),
                  child: ElevatedButton(
                    onPressed: widget.onNavigateToSearch, // Panggil callback
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentPink, // Warna aksen Pink/Merah
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Baca Buku Baru', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.white),
                      ],
                    ),
                  ),
                ),

                // --- 4. Koleksimu (Sesuai Wireframe) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 32.0, 16.0, 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Koleksimu",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      TextButton(
                        onPressed: widget.onNavigateToCollection, // Panggil callback
                        style: TextButton.styleFrom(
                          foregroundColor: primaryPurple,
                        ),
                        child: const Text(
                          "Selengkapnya >", 
                          style: TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tampilkan list buku
                (recentBooks.isEmpty)
                  ? _buildEmptyCollectionCTA(onNavigate: widget.onNavigateToSearch) // <-- PANGGILAN YANG BENAR
                  : SizedBox(
                      height: 180, 
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentBooks.length,
                        padding: const EdgeInsets.only(left: 16.0), // Tambah padding kiri
                        itemBuilder: (context, index) {
                          final bookData = recentBooks[index];
                          final String thumbnail = bookData['coverUrl'] ?? '';
                          final String hiveKey = bookData['hiveKey']; 
                          
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BookDetailPage(bookId: hiveKey),
                                ),
                              );
                            },
                            child: Container(
                              width: 110, 
                              margin: const EdgeInsets.only(right: 12.0),
                              child: Column(
                                children: [
                                  Card(
                                    elevation: 4.0,
                                    shadowColor: textPrimary.withOpacity(0.1),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16.0),
                                      child: thumbnail.isNotEmpty
                                          ? Image.network(
                                              thumbnail,
                                              height: 150,
                                              width: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(height: 150, width: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: textSecondary)),
                                            )
                                          : Container(
                                              height: 150,
                                              width: 100,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.book_outlined, color: textSecondary),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                const SizedBox(height: 100), // Padding bawah agar tidak mentok Nav
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Helper Ambil Buku (SAMA) ---
  List<Map<String, dynamic>> _getRecentBooks({required Box bookBox, required String loggedInUser}) {
      final List<Map<String, dynamic>> userBooks = [];
      for (var key in bookBox.keys) { 
        try {
          final bookMap = Map<String, dynamic>.from(bookBox.get(key) as Map);
          if (bookMap['username'] == loggedInUser) {
            bookMap['hiveKey'] = key;
            userBooks.add(bookMap);
          }
        } catch (e) { /* abaikan */ }
      }
      return userBooks.reversed.take(3).toList();
  }

  // --- WIDGET BARU: Tampilan jika koleksi kosong (DENGAN PERBAIKAN) ---
  Widget _buildEmptyCollectionCTA({required VoidCallback onNavigate}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentGreen.withOpacity(0.8), accentGreen.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            const Text(
              "Koleksimu masih kosong",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onNavigate, // <-- GUNAKAN CALLBACK
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accentGreen, // Teks warna hijau
              ),
              child: const Text("Tambah Buku Pertamamu!", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}