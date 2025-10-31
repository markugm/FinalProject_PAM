// File: lib/pages/collection_page.dart (LENGKAP & BENAR)
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'book_detail_page.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final Color oliveGreen = const Color(0xFF84994F);
  String? _loggedInUser; // Untuk simpan username

  @override
  void initState() {
    super.initState();
    _loadUsername(); // Panggil fungsi ambil username
  }

  // Fungsi untuk ambil username dari SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    // Pakai mounted check untuk keamanan
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
      appBar: AppBar(
        title: const Text("Koleksiku"),
        backgroundColor: oliveGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ValueListenableBuilder(
        valueListenable: bookBox.listenable(),
        builder: (context, Box box, _) {
          // Jika username belum termuat, tampilkan loading
          if (_loggedInUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final allKeys = box.keys;
          // --- FILTER DATA BERDASARKAN USERNAME ---
          final userBookKeys = allKeys.where((key) {
            // Konversi aman dan cek username
            try {
              final bookMap = Map<String, dynamic>.from(box.get(key) as Map);
              return bookMap['username'] == _loggedInUser;
            } catch (e) {
              print(
                "Error casting book data: $e",
              ); // Debugging jika ada data rusak
              return false; // Abaikan data yang rusak
            }
          }).toList(); // Ubah hasil filter jadi List

          if (userBookKeys.isEmpty) {
            return const Center(
              child: Text(
                "Koleksimu masih kosong.\nSilakan tambahkan buku di tab 'Cari'.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Gunakan list yang sudah difilter (userBooks)
          return ListView.builder(
            itemCount: userBookKeys.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final String hiveKey = userBookKeys[index] as String;
              final bookData =
                  Map<String, dynamic>.from(box.get(hiveKey) as Map);

              // Ambil detail buku dari bookData yang sudah difilter
              final String title = bookData['title'] ?? 'Tanpa Judul';
              final String authors = bookData['authors'] ?? 'N/A';
              final String thumbnail = bookData['coverUrl'] ?? '';
              final int currentPage = bookData['currentPage'] ?? 0;
              final int pageCount = bookData['pageCount'] ?? 0;
              final double progress = (pageCount > 0)
                  ? (currentPage / pageCount)
                  : 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: thumbnail.isNotEmpty
                      ? Image.network(thumbnail, width: 50, fit: BoxFit.cover)
                      : Container(
                          width: 50,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Icon(Icons.book_outlined),
                        ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authors,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(oliveGreen),
                      ),
                      Text("Progres: $currentPage / $pageCount halaman"),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Kirim Hive Key asli
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookDetailPage(
                          bookId: hiveKey), // Kirim HIVE KEY
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
