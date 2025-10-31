import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'log_entry_page.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId; // Ini adalah HIVE KEY

  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final Color oliveGreen = const Color(0xFF84994F);
  final Color warmOrange = const Color(0xFFFCB53B);
  final Color burntRed = const Color(0xFFA72703);
  final Color paleYellow = const Color(0xFFFFE797);

  late Box bookBox;
  late Box logBox;
  Map<String, dynamic> currentBookData = {};
  String? _loggedInUser;

  final double rateUSD = 0.000061;
  final double rateEUR = 0.000057;

  String _selectedZone = "WIB";
  final Map<String, int> _timeZoneOffsets = {
    "WIB": 0,
    "WITA": 1,
    "WIT": 2,
    "London": -7,
  };
  String _selectedCurrency = "IDR";

  @override
  void initState() {
    super.initState();
    bookBox = Hive.box('bookBox');
    logBox = Hive.box('logBox');
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

  // --- Widget Helper Harga ---
  Widget _buildPriceDisplay(double priceIDR) {
    String formattedPrice;
    
    // Tentukan format berdasarkan state _selectedCurrency
    if (_selectedCurrency == "USD") {
      double priceUSD = priceIDR * rateUSD;
      formattedPrice = NumberFormat.currency(locale: 'en_US', symbol: '\$ ').format(priceUSD);
    } else if (_selectedCurrency == "EUR") {
      double priceEUR = priceIDR * rateEUR;
      formattedPrice = NumberFormat.currency(locale: 'de_DE', symbol: '€ ').format(priceEUR);
    } else {
      // Default ke IDR
      formattedPrice = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(priceIDR);
    }

    // Hanya return 1 Teks
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          "Harga Beli:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: oliveGreen),
        ),
        Text(
          formattedPrice, // Tampilkan harga yang sudah diformat
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  // --- Widget Helper Waktu ---
  String _formatLogTime(DateTime timestamp) {
    final adjustedTime = timestamp.add(
      Duration(hours: _timeZoneOffsets[_selectedZone]!),
    );
    return DateFormat('dd MMM yyyy, HH:mm').format(adjustedTime) +
        " ($_selectedZone)";
  }

  Future<void> _showReviewDialog(
    BuildContext context,
    Map<String, dynamic> bookData,
    String hiveKey,
  ) async {
    // Kita butuh state DI DALAM dialog (untuk bintang & teks)
    int currentRating = bookData['rating'] ?? 0;
    final TextEditingController reviewController = TextEditingController(
      text: bookData['review'] ?? '',
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User harus menekan tombol
      builder: (BuildContext dialogContext) {
        // StatefulBuilder agar bintang di dalam dialog bisa di-update
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Beri Review Buku'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    // --- Widget Bintang Rating ---
                    Text(
                      'Rating Anda:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: oliveGreen,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < currentRating
                                ? Icons.star
                                : Icons.star_border,
                            color: warmOrange,
                            size: 35,
                          ),
                          onPressed: () {
                            // Update rating di dalam state dialog
                            setDialogState(() {
                              currentRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // --- Widget Teks Review ---
                    TextField(
                      controller: reviewController,
                      decoration: const InputDecoration(
                        labelText: 'Tulis review Anda...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Tutup dialog
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: oliveGreen),
                  child: const Text(
                    'Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    // --- SIMPAN DATA REVIEW KE HIVE ---
                    // 1. Update Map data buku
                    bookData['rating'] = currentRating;
                    bookData['review'] = reviewController.text;

                    // 2. Simpan kembali ke Hive
                    final bookBox = Hive.box('bookBox');
                    bookBox.put(hiveKey, bookData);

                    // 3. Tutup dialog
                    Navigator.of(dialogContext).pop();

                    // 4. Kasih notif (opsional)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Review berhasil disimpan!"),
                        backgroundColor: Color(0xFF84994F), // oliveGreen
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FUNGSI BARU: Konfirmasi Hapus Buku ---
  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    String hiveKey,
    String title,
  ) async {
    // Ambil warna BurntRed dari palette-mu
    final Color burntRed = const Color(0xFFA72703);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Buku'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Tambahkan '?' untuk handle jika title null
                Text(
                  'Apakah Anda yakin ingin menghapus "${title ?? 'buku ini'}" dari koleksi Anda?',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Semua log baca dan review untuk buku ini juga akan dihapus secara permanen.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
              },
            ),
            // Tombol Hapus (berwarna merah)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: burntRed),
              child: const Text('HAPUS', style: TextStyle(color: Colors.white)),
              onPressed: () {
                // --- PANGGIL FUNGSI LOGIC HAPUS ---
                _deleteBookData(hiveKey);
                Navigator.of(dialogContext).pop(); // Tutup dialog
              },
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI BARU: Logic Hapus Data ---
  void _deleteBookData(String hiveKey) {
    // 1. Ambil data buku untuk mendapatkan Google Book ID
    // Tambahkan pengecekan null untuk keamanan
    final bookDataMap = bookBox.get(hiveKey);
    if (bookDataMap == null) return; // Keluar jika buku tidak ada

    final bookData = Map<String, dynamic>.from(bookDataMap as Map);
    final String googleBookId = bookData['id'];

    // 2. Hapus buku dari bookBox
    bookBox.delete(hiveKey);

    // 3. Hapus semua log terkait dari logBox
    final logBox = Hive.box('logBox');
    // Cari semua key dari log yang sesuai
    final List<dynamic> keysToDelete = [];
    for (var key in logBox.keys) {
      try {
        final log = Map<String, dynamic>.from(logBox.get(key) as Map);
        // Pastikan filter username juga ada di sini
        if (log['bookId'] == googleBookId && log['username'] == _loggedInUser) {
          keysToDelete.add(key);
        }
      } catch (e) {
        print("Error reading log for deletion: $e");
      }
    }
    // Hapus semua log yang ditemukan
    logBox.deleteAll(keysToDelete);

    // 4. Kasih notif dan kembali ke halaman koleksi
    // Pastikan context masih valid
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Buku berhasil dihapus."),
        backgroundColor: Color(0xFF84994F), // oliveGreen
      ),
    );

    // Kembali ke halaman koleksi (karena halaman ini sudah tidak valid)
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading jika username belum siap
    if (_loggedInUser == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: oliveGreen),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Dengarkan perubahan data buku
    return ValueListenableBuilder(
      valueListenable: bookBox.listenable(keys: [widget.bookId]),
      builder: (context, Box box, _) {
        final bookDataMap = box.get(widget.bookId);
        // Handle jika buku tidak ditemukan
        if (bookDataMap == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Error"),
              backgroundColor: oliveGreen,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text("Data buku tidak ditemukan!")),
          );
        }

        // Konversi data buku
        currentBookData = Map<String, dynamic>.from(bookDataMap as Map);

        // Ekstrak data buku
        final String title = currentBookData['title'] ?? 'Detail Buku';
        final String authors = currentBookData['authors'] ?? 'N/A';
        final String thumbnail = currentBookData['coverUrl'] ?? '';
        final double price =
            currentBookData['price']?.toDouble() ?? 0.0; // Konversi aman
        final int currentPage = currentBookData['currentPage'] ?? 0;
        final int pageCount = currentBookData['pageCount'] ?? 0;
        final double progress = (pageCount > 0)
            ? (currentPage / pageCount)
            : 0.0;
        final String description =
            currentBookData['description'] ?? 'Tidak ada sinopsis.';
        final String category = currentBookData['category'] ?? 'N/A';

        return Scaffold(
          appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            backgroundColor: oliveGreen,
            foregroundColor: Colors.white,

            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: "Hapus Buku",
                onPressed: () {
                  // Panggil fungsi konfirmasi hapus (akan kita buat)
                  _showDeleteConfirmationDialog(context, widget.bookId, title);
                },
              ),
            ],
          ),
          // --- TAMBAHKAN SingleChildScrollView DI SINI ---
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                // Column utama ada di dalam SingleChildScrollView
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Bagian Info Buku (Pastikan ini ada!) ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover
                      thumbnail.isNotEmpty
                          ? Image.network(
                              thumbnail,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    context,
                                    error,
                                    stackTrace,
                                  ) => // Handle error load gambar
                                  Container(
                                    width: 100,
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
                                  ),
                            )
                          : Container(
                              width: 100,
                              height: 150,
                              color: Colors.grey[200],
                              child: const Icon(Icons.book),
                            ),
                      const SizedBox(width: 16),
                      // Teks Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ), // Ukuran font disesuaikan
                            Text(
                              authors,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ), // Ukuran font disesuaikan
                            if (category != 'N/A') // Hanya tampilkan jika ada kategori
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Chip(
                                  label: Text(category, style: TextStyle(fontSize: 12)),
                                  backgroundColor: paleYellow, // Warna dari palette
                                  side: BorderSide.none,
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                            const SizedBox(height: 12),
                            // Progres Bar
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                oliveGreen,
                              ),
                            ),
                            Text(
                              "$currentPage / $pageCount halaman",
                              style: const TextStyle(fontSize: 12),
                            ), // Ukuran font disesuaikan
                            const SizedBox(height: 12),
                            // Panggil Widget Konversi Uang
                            Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Tampilkan harga (widget kita yg baru)
                              _buildPriceDisplay(price),
                              const SizedBox(width: 8),
                              // Dropdown untuk ganti mata uang
                              DropdownButton<String>(
                                value: _selectedCurrency,
                                items: <String>['IDR', 'USD', 'EUR']
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedCurrency = newValue!;
                                  });
                                },
                                underline: Container(), // Hapus garis bawah
                                isDense: true, // Bikin lebih ramping
                              ),
                            ],
                          ),
                            //sinopsis
                            const Divider(height: 32, thickness: 1),
                            ExpansionTile(
                              title: Text(
                                "Sinopsis",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: oliveGreen,
                                ),
                              ),
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(
                                bottom: 16.0,
                              ),
                              iconColor: oliveGreen,
                              collapsedIconColor: Colors.grey[600],
                              children: [
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                  ), // Beri jarak antar baris
                                  textAlign:
                                      TextAlign.justify, // Rata kiri-kanan
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // --- KODE BARU: TAMPILKAN REVIEW JIKA ADA ---
                  if (currentBookData['rating'] > 0 ||
                      (currentBookData['review'] != null &&
                          currentBookData['review'].isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Review Anda:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: oliveGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tampilkan Bintang
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < (currentBookData['rating'] ?? 0)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: warmOrange,
                              );
                            }),
                          ),
                          // Tampilkan Teks Review
                          if (currentBookData['review'] != null &&
                              currentBookData['review'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '"${currentBookData['review']}"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  const Divider(height: 32, thickness: 1),

                  // --- Bagian Riwayat Log (Konversi Waktu) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Riwayat Log Baca",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: oliveGreen,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedZone,
                        items: _timeZoneOffsets.keys.map((String zone) {
                          return DropdownMenuItem<String>(
                            value: zone,
                            child: Text(zone),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedZone = newValue!;
                          });
                        },
                      ),
                    ],
                  ),

                  // --- List Riwayat Log ---
                  // Kita pakai Column + ShrinkWrap karena sudah di dalam SingleChildScrollView
                  // TIDAK PAKAI Expanded lagi
                  ValueListenableBuilder(
                    valueListenable: logBox.listenable(),
                    builder: (context, Box logBoxInstance, _) {
                      final String googleBookId = currentBookData['id'];
                      final userLogs = logBoxInstance.values
                          .where((log) {
                            try {
                              final logMap = Map<String, dynamic>.from(
                                log as Map,
                              );
                              return logMap['bookId'] == googleBookId &&
                                  logMap['username'] == _loggedInUser;
                            } catch (e) {
                              return false;
                            }
                          })
                          .toList()
                          .reversed;

                      if (userLogs.isEmpty) {
                        return const Padding(
                          // Beri padding agar tidak terlalu mepet
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Text("Belum ada log untuk buku ini."),
                          ),
                        );
                      }

                      // Gunakan Column, bukan ListView karena sudah di dalam SingleChildScrollView
                      return Column(
                        children: userLogs.map((logData) {
                          final log = Map<String, dynamic>.from(logData as Map);
                          final DateTime timestamp = log['timestamp'];
                          final String notes =
                              log['notes'] ?? ''; // Default string kosong
                          final int pageLogged = log['pageLogged'] ?? 0;
                          final String? address = log['address'] as String?;
                          final bool hasNotes = notes.isNotEmpty;
                          final bool hasAddress =
                              address != null && address.isNotEmpty;
                          String subtitleText = _formatLogTime(timestamp);
                          if (hasNotes) subtitleText += "\nNotes: $notes";
                          if (hasAddress) subtitleText += "\nLokasi: $address";

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text(
                                "Log: ${pageLogged} Halaman",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(subtitleText), // Tampilkan notes jika ada
                              isThreeLine: hasNotes || hasAddress,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 80,
                  ), // Beri jarak agar tidak tertutup FAB
                ],
              ),
            ),
          ),
          // --- AKHIR DARI SingleChildScrollView ---

          // --- KODE BARU: Tombol Aksi (Bisa lebih dari satu) ---
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end, // Mulai dari bawah
            children: [
              // Tombol "Beri Review"
              // Muncul HANYA jika status buku == "Finished"
              if (currentBookData['status'] == 'Finished')
                FloatingActionButton.extended(
                  onPressed: () {
                    // Panggil fungsi popup (akan kita buat di Langkah 2)
                    _showReviewDialog(context, currentBookData, widget.bookId);
                  },
                  label: const Text("Beri Review"),
                  icon: const Icon(Icons.star),
                  backgroundColor: oliveGreen, // Warna primer
                  foregroundColor: Colors.white,
                  heroTag: 'fab_review', // Tag unik agar tidak bentrok
                ),

              const SizedBox(height: 16), // Jarak antar tombol
              // Tombol untuk "Tambah Log Baru" (Tombol lama kita)
              FloatingActionButton.extended(
                onPressed: () {
                  // Pindah ke halaman Log Entry
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LogEntryPage(bookId: widget.bookId),
                    ),
                  );
                },
                label: const Text("Catat Log"),
                icon: const Icon(Icons.add),
                backgroundColor: warmOrange,
                foregroundColor: Colors.white,
                heroTag: 'fab_log', // Tag unik
              ),
            ],
          ),
          // --- AKHIR KODE BARU ---
        );
      },
    );
  }
}
