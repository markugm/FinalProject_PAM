import 'dart:convert'; // Wajib untuk mengubah data JSON
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Wajib untuk simpan ke Hive
import 'package:http/http.dart' as http; // Wajib untuk mengambil data API
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/notification_service.dart';
import '../utils/constants.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  // 1. Definisikan Warna
  final Color oliveGreen = const Color(0xFF84994F);
  final Color warmOrange = const Color(0xFFFCB53B);

  // 2. State Variables
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _bookResults = []; // List untuk menyimpan hasil pencarian
  bool _isLoading = false; // Status apakah sedang loading
  bool _userHasSearched = false; // Status apakah user sudah mencari

  // 3. Logic untuk Mencari Buku
  Future<void> _searchBooks() async {
    final query = _searchController.text;

    // Validasi: Jangan cari jika input kosong
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan masukkan judul atau penulis.")),
      );
      return;
    }

    // Set state loading
    setState(() {
      _isLoading = true;
      _userHasSearched = true; // User sudah pernah mencari
      _bookResults = []; // Kosongkan hasil lama
    });

    // Panggil API menggunakan API_KEY dari constants.dart
    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=$query&key=$GOOGLE_BOOKS_API_KEY',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Jika sukses (200 OK)
        final data = jsonDecode(response.body);

        // Update state dengan data baru
        setState(() {
          // 'items' adalah list buku dari JSON
          _bookResults = data['items'] ?? [];
          _isLoading = false;
        });
      } else {
        // Jika gagal (misal 404, 500)
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengambil data buku.")),
        );
      }
    } catch (e) {
      // Jika error (misal: tidak ada internet)
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // 4. Logic untuk Simpan Buku ke Hive
  void _saveBookToHive(dynamic bookData) async {

    // Buka 'kotak' buku
    final bookBox = Hive.box('bookBox');

    // 'id' dari Google Books API adalah ID unik
    final String bookId = bookData['id'];

    // Ambil data penting dari JSON
    final String title = bookData['volumeInfo']['title'] ?? 'Tanpa Judul';
    final List<dynamic>? authorsList = bookData['volumeInfo']['authors'];
    final String authors = (authorsList ?? ['N/A']).join(', ');
    final String coverUrl =
        bookData['volumeInfo']['imageLinks']?['thumbnail'] ?? '';
    final int pageCount = bookData['volumeInfo']['pageCount'] ?? 0;
    final String description =
        bookData['volumeInfo']['description'] ?? 'Tidak ada sinopsis.';

    // Ambil list kategori, lalu ambil item pertama. Jika tidak ada, 'N/A'.
    final List<dynamic>? categoriesList = bookData['volumeInfo']['categories'];
    final String category = (categoriesList != null && categoriesList.isNotEmpty)
        ? categoriesList[0] as String
        : 'N/A';

    // DAPATKAN USERNAME YANG LOGIN
    final prefs = await SharedPreferences.getInstance();
    final String? loggedInUser = prefs.getString(
      'loggedInUser',
    ); // Ambil dari session

    // 2. Cek apakah buku ini sudah ada di koleksi USER INI
    final bool alreadyExists = bookBox.values.any((book) {
      final bookMap = Map<String, dynamic>.from(book as Map);
      return bookMap['id'] == bookId && bookMap['username'] == loggedInUser;
    });

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Buku ini sudah ada di koleksimu."),
          backgroundColor: warmOrange,
        ),
      );
      return; // Hentikan fungsi
    }

    // Siapkan data untuk disimpan ke Hive
    final Map<String, dynamic> bookMap = {
      'id': bookId,
      'title': title,
      'authors': authors,
      'coverUrl': coverUrl,
      'pageCount': pageCount,
      'description': description,
      'category': category,
      'currentPage': 0,
      'status': 'To Read',
      'price': 0.0,
      'review': '',
      'rating': 0,
      'username': loggedInUser ?? 'unknown', 
    };

    final String uniqueHiveKey = '${loggedInUser}_$bookId';
    bookBox.put(uniqueHiveKey, bookMap);

    // Panggil notifikasi "Buku Ditambahkan" ---
    final notificationService = NotificationService();
    await notificationService.requestPermissions(); 
    await notificationService.scheduleNotificationNow(
      title: "Ada Buku Baru di Koleksimu!",
      body: "Ayo mulai perjalananmu membaca '$title'!",
      delaySeconds: 2, // Muncul 2 detik setelah ditambah
      notificationId: 3, // Pakai ID unik (misal 3)
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title berhasil ditambahkan ke koleksi!"),
        backgroundColor: oliveGreen, // Warna sukses
      ),
    );
  }

  // 5. Jangan lupa dispose controller
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 6. Tampilan (UI) Halaman
  @override
  Widget build(BuildContext context) {
    // --- TAMBAHKAN SCAFFOLD & APPBAR ---
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cari Buku"),
        backgroundColor: oliveGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Hapus tombol back
      ),
      body: Padding(
        // <--- WIDGET ASLI ANDA SEKARANG ADA DI DALAM BODY
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Bagian Search Bar ---
            Row(
              children: [
                // TextField
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari judul atau penulis...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: oliveGreen, width: 2.0),
                      ),
                    ),
                    // Panggil _searchBooks saat user menekan 'Enter' di keyboard
                    onSubmitted: (value) => _searchBooks(),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Tombol Search
                IconButton(
                  icon: const Icon(Icons.search, size: 32.0),
                  color: oliveGreen,
                  onPressed: _searchBooks, // Panggil _searchBooks saat ditekan
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // --- Bagian Hasil Pencarian ---
            // Tampilkan loading spinner jika sedang mengambil data
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            // Tampilkan list hasil jika tidak loading
            else
              Expanded(
                // Jika user belum mencari, tampilkan pesan
                child: !_userHasSearched
                    ? const Center(child: Text("Silakan mulai mencari buku."))
                    // Jika sudah mencari tapi hasil 0
                    : _bookResults.isEmpty
                    ? const Center(child: Text("Buku tidak ditemukan."))
                    // Jika hasil ditemukan, tampilkan ListView
                    : ListView.builder(
                        itemCount: _bookResults.length,
                        itemBuilder: (context, index) {
                          final book = _bookResults[index];
                          final volumeInfo = book['volumeInfo'];

                          // Ambil data (dengan pengecekan data kosong)
                          final String title =
                              volumeInfo['title'] ?? 'Tanpa Judul';
                          final String authors =
                              (volumeInfo['authors'] ?? ['N/A']).join(', ');
                          final String thumbnail =
                              volumeInfo['imageLinks']?['thumbnail'] ?? '';

                          // Tampilkan sebagai ListTile
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              // Tampilkan Gambar Cover
                              leading: thumbnail.isNotEmpty
                                  ? Image.network(
                                      thumbnail,
                                      width: 50,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      // Placeholder jika tidak ada gambar
                                      width: 50,
                                      height: 70,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.book),
                                    ),

                              // Tampilkan Judul (RAPIAH)
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2, // Perintah 1: Maksimal 2 baris
                                overflow: TextOverflow
                                    .ellipsis, // Perintah 2: Tampilkan ...
                              ),

                              // Tampilkan Penulis (RAPIAH)
                              subtitle: Text(
                                authors,
                                maxLines:
                                    1, // Subtitle juga kita batasi 1 baris
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Tombol "Tambah" (Aksi Simpan ke Hive)
                              trailing: IconButton(
                                icon: Icon(Icons.add_circle, color: warmOrange),
                                onPressed: () {
                                  // Panggil fungsi simpan
                                  _saveBookToHive(book);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
