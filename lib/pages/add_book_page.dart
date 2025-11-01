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
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _bookResults = [];
  bool _isLoading = false;
  bool _userHasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIC PENCARIAN (TANPA CEK KONEKSI) ---
  Future<void> _searchBooks() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan masukkan judul atau penulis."), backgroundColor: errorRed),
      );
      return;
    }

    // --- BLOK CEK KONEKSI DIHAPUS ---

    setState(() {
      _isLoading = true;
      _userHasSearched = true;
      _bookResults = [];
    });

    final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=$query&key=$GOOGLE_BOOKS_API_KEY');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bookResults = data['items'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengambil data buku."), backgroundColor: errorRed),
        );
      }
    } catch (e) {
      // Catch ini sekarang akan menangani error (termasuk tidak ada internet)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Tidak ada koneksi atau server bermasalah."), backgroundColor: errorRed),
      );
    }
    
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  // --- LOGIC SIMPAN BUKU (SAMA PERSIS, SUDAH LENGKAP) ---
  void _saveBookToHive(dynamic bookData) async {
    final bookBox = Hive.box('bookBox');
    final String bookId = bookData['id'];

    final String title = bookData['volumeInfo']['title'] ?? 'Tanpa Judul';
    final List<dynamic>? authorsList = bookData['volumeInfo']['authors'];
    final String authors = (authorsList ?? ['N/A']).join(', ');
    final String coverUrl = bookData['volumeInfo']['imageLinks']?['thumbnail'] ?? '';
    final int pageCount = bookData['volumeInfo']['pageCount'] ?? 0;
    final String description = bookData['volumeInfo']['description'] ?? 'Tidak ada sinopsis.';
    final List<dynamic>? categoriesList = bookData['volumeInfo']['categories'];
    final String category = (categoriesList != null && categoriesList.isNotEmpty)
        ? categoriesList[0] as String
        : 'N/A';

    final prefs = await SharedPreferences.getInstance();
    final String? loggedInUser = prefs.getString('loggedInUser');

    final bool alreadyExists = bookBox.values.any((book) {
       final bookMap = Map<String, dynamic>.from(book as Map);
       return bookMap['id'] == bookId && bookMap['username'] == loggedInUser;
    });

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Buku ini sudah ada di koleksimu."),
          backgroundColor: accentYellow,
          behavior: SnackBarBehavior.floating, 
        ),
      );
      return;
    }

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
    
    final String uniqueHiveKey = "${loggedInUser}_$bookId";
    bookBox.put(uniqueHiveKey, bookMap);
    
    final notificationService = NotificationService();
    await notificationService.requestPermissions(); 
    await notificationService.scheduleNotificationNow(
      title: "Buku Baru Ditambahkan!",
      body: "Ayo mulai perjalananmu membaca '$title'!",
      delaySeconds: 2,
      notificationId: 3, 
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Buku berhasil ditambahkan ke koleksi!"),
        backgroundColor: accentGreen,
      ),
    );
  }

  // --- UI BARU (VIBRANT TECH) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cari Buku"),
        automaticallyImplyLeading: false, 
      ),
      body: Column( 
        children: [
          // --- Bagian Search Bar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 6.0, 16.0, 10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari judul, penulis...',
                    ),
                    onSubmitted: (value) => _searchBooks(), 
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _searchBooks,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0)
                    ),
                  ),
                  child: const Icon(Icons.search_rounded, color: Colors.white),
                )
              ],
            ),
          ),
          
          // --- Bagian Hasil Pencarian ---
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: primaryPurple),
              ),
            )
          else
            Expanded(
              child: !_userHasSearched
                  ? Center( 
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text("Silakan mulai mencari buku.", style: TextStyle(color: textSecondary, fontSize: 16)),
                        ],
                      )
                    )
                  : _bookResults.isEmpty
                      ? Center( 
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sentiment_dissatisfied_rounded, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              const Text("Buku tidak ditemukan.", style: TextStyle(color: textSecondary, fontSize: 16)),
                            ],
                          )
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 100.0), 
                          itemCount: _bookResults.length,
                          itemBuilder: (context, index) {
                            final book = _bookResults[index];
                            final volumeInfo = book['volumeInfo'];

                            final String title = volumeInfo['title'] ?? 'Tanpa Judul';
                            final String authors = (volumeInfo['authors'] ?? ['N/A']).join(', ');
                            final String thumbnail = volumeInfo['imageLinks']?['thumbnail'] ?? '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_rounded, color: accentGreen, size: 30),
                                      onPressed: () {
                                        _saveBookToHive(book);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
        ],
      ),
    );
  }
}
