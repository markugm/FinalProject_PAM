import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/utils/constants.dart'; // Import warna BARU
import 'book_detail_page.dart'; // Import halaman detail

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  String? _loggedInUser;

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Panggil fungsi ambil username
  }

  // Fungsi untuk ambil username dari SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _loggedInUser = prefs.getString('loggedInUser');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Box bookBox = Hive.box('bookBox');

    return Scaffold(
      // AppBar sudah di-style oleh main.dart
      appBar: AppBar(
        title: const Text("Koleksiku"),
        automaticallyImplyLeading: false,
      ),
      // Kita pakai ValueListenableBuilder agar auto-update
      body: ValueListenableBuilder(
        valueListenable: bookBox.listenable(),
        builder: (context, Box box, _) {
          
          // Jika username belum termuat, tampilkan loading
          if (_loggedInUser == null) {
            return const Center(child: CircularProgressIndicator(color: primaryPurple));
          }

          // --- FILTER DATA BERDASARKAN USERNAME (SAMA) ---
          final userBookKeys = box.keys.where((key) {
            try {
              final bookMap = Map<String, dynamic>.from(box.get(key) as Map);
              return bookMap['username'] == _loggedInUser;
            } catch (e) { return false; }
          }).toList(); 
          
          // --- UI BARU: Jika Koleksi Kosong ---
          if (userBookKeys.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    "Koleksimu masih kosong.",
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tambahkan buku dari tab 'Cari'.",
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // --- UI BARU: Tampilkan sebagai ListView ---
          return ListView.builder(
            itemCount: userBookKeys.length, 
            // Padding bawah agar tidak tertutup floating nav bar
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 120.0), 
            itemBuilder: (context, index) {
              
              final String hiveKey = userBookKeys[index] as String;
              final bookData = Map<String, dynamic>.from(box.get(hiveKey) as Map);

              // Ambil detailnya
              final String title = bookData['title'] ?? 'Tanpa Judul';
              final String authors = bookData['authors'] ?? 'N/A';
              final String thumbnail = bookData['coverUrl'] ?? '';
              final int currentPage = bookData['currentPage'] ?? 0;
              final int pageCount = bookData['pageCount'] ?? 0;
              final double progress = (pageCount > 0) ? (currentPage / pageCount) : 0.0;

              // --- CARD BARU (VIBRANT TECH) ---
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                // Style Card sudah dari main.dart (shape, color, shadow)
                child: InkWell( // Bungkus dengan InkWell agar bisa di-tap
                  onTap: () {
                    // Kirim HIVE KEY yang benar ke halaman detail
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailPage(bookId: hiveKey),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.0), // Sesuaikan dengan CardTheme
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover Buku
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: thumbnail.isNotEmpty
                              ? Image.network(
                                  thumbnail,
                                  width: 70, 
                                  height: 100, 
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(width: 70, height: 100, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: textSecondary)),
                                )
                              : Container(
                                  width: 70,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.book_outlined, color: textSecondary),
                                ),
                        ),
                        const SizedBox(width: 16),
                        // Info Teks (Termasuk Progress Bar)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authors,
                                style: const TextStyle(color: textSecondary, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12), // Jarak ke progress bar
                              
                              // --- Progress Bar (Style Baru) ---
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: accentYellow.withOpacity(0.1),
                                valueColor: const AlwaysStoppedAnimation<Color>(accentYellow),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Progres: $currentPage / $pageCount halaman",
                                style: const TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8), // Jarak ke panah
                        // Ikon panah
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: textSecondary),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}