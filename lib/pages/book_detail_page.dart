import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/utils/constants.dart';
import 'package:final_project/utils/helpers.dart'; // Untuk addXp
import 'log_entry_page.dart';

class BookDetailPage extends StatefulWidget {
  final String bookId; // Ini adalah HIVE KEY
  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  // --- SEMUA STATE (LENGKAP) ---
  late Box bookBox;
  late Box logBox;
  Map<String, dynamic> currentBookData = {};
  String? _loggedInUser;

  // State Konversi Uang
  final double rateUSD = 0.000061;
  final double rateEUR = 0.000057;
  String _selectedCurrency = "IDR";
  
  // State Konversi Waktu
  String _selectedZone = "WIB";
  final Map<String, int> _timeZoneOffsets = {
    "WIB": 0, "WITA": 1, "WIT": 2, "London": -7,
  };

  @override
  void initState() {
    super.initState();
    bookBox = Hive.box('bookBox');
    logBox = Hive.box('logBox');
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _loggedInUser = prefs.getString('loggedInUser'));
  }

  // --- FUNGSI HELPER WAKTU ---
  String _formatLogTime(DateTime timestamp) {
    final adjustedTime = timestamp.add(Duration(hours: _timeZoneOffsets[_selectedZone]!));
    return DateFormat('dd MMM yyyy, HH:mm').format(adjustedTime) + " ($_selectedZone)";
  }

  // --- FUNGSI HELPER HARGA ---
  Widget _buildPriceDisplay(double priceIDR) {
    String formattedPrice;
    String symbol = 'Rp ';
    double converted = priceIDR;

    if (_selectedCurrency == "USD") {
      converted = priceIDR * rateUSD;
      symbol = "\$ ";
    } else if (_selectedCurrency == "EUR") {
      converted = priceIDR * rateEUR;
      symbol = "€ ";
    }
    
    formattedPrice = NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(converted);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Harga Buku", style: TextStyle(color: textSecondary, fontSize: 14)),
            Text(
              formattedPrice,
              style: const TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
        // Dropdown Konversi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: scaffoldBg,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButton<String>(
            value: _selectedCurrency,
            dropdownColor: cardBg,
            underline: Container(), // Hapus garis bawah
            items: ['IDR', 'USD', 'EUR']
                .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v,
                        style: const TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w600))))
                .toList(),
            onChanged: (v) => setState(() => _selectedCurrency = v!),
          ),
        )
      ],
    );
  }

  // --- FUNGSI DIALOG REVIEW (FIXED OVERFLOW & XP) ---
  Future<void> _showReviewDialog(
      BuildContext ctx, Map<String, dynamic> data, String key) async {
    int current = data['rating'] ?? 0;
    final controller = TextEditingController(text: data['review'] ?? '');
    bool isNewReview = (data['review'] == null || (data['review'] as String).isEmpty);

    return showDialog(
      context: ctx,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Beri Review Buku", style: TextStyle(color: textPrimary)),
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            // FIX OVERFLOW: Bungkus dengan Column mainAxisSize.min
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      icon: Icon(
                        i < current
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: accentYellow,
                        size: 32,
                      ),
                      onPressed: () => setDialogState(() => current = i + 1),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField( // Pakai style dari main.dart
                  controller: controller,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Tulis pendapatmu...",
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("Batal", style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async { // <-- JADIKAN ASYNC
                  data['rating'] = current;
                  data['review'] = controller.text;
                  await Hive.box('bookBox').put(key, data); // Pakai await

                  // --- LOGIC XP REVIEW (YANG HILANG) ---
                  if (isNewReview && controller.text.isNotEmpty && _loggedInUser != null) {
                    bool leveledUp = await addXp(_loggedInUser!, 50); // +50 XP
                    if (leveledUp && mounted) {
                      final profile = Hive.box('profileBox').get(_loggedInUser!);
                      final newLevel = (profile as Map)['level'] ?? '?';
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text("LEVEL UP! Kamu sekarang Level $newLevel! (+50 XP)"),
                        backgroundColor: accentYellow,
                      ));
                    }
                  }
                  // --- AKHIR LOGIC XP ---

                  Navigator.pop(c);
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text("Review disimpan!"),
                    backgroundColor: accentGreen,
                  ));
                },
                style: ElevatedButton.styleFrom(backgroundColor: accentGreen),
                child: const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- FUNGSI KONFIRMASI HAPUS BUKU ---
  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, String hiveKey, String title) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Buku'),
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Text('Apakah Anda yakin ingin menghapus "$title" dan semua log-nya?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal', style: TextStyle(color: textSecondary)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: errorRed), // Warna error
              child: const Text('HAPUS', style: TextStyle(color: Colors.white)),
              onPressed: () {
                _deleteBookData(hiveKey);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI LOGIC HAPUS DATA ---
  void _deleteBookData(String hiveKey) {
    final data = bookBox.get(hiveKey);
    if (data == null) return;
    final book = Map<String, dynamic>.from(data as Map);
    final googleId = book['id'];
    bookBox.delete(hiveKey);

    final toDelete = logBox.keys.where((k) {
      try {
        final log = Map<String, dynamic>.from(logBox.get(k) as Map);
        return log['bookId'] == googleId && log['username'] == _loggedInUser;
      } catch (e) { return false; }
    }).toList();
    logBox.deleteAll(toDelete);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Buku berhasil dihapus."),
      backgroundColor: accentGreen,
    ));
    Navigator.pop(context); // Kembali
  }

  // --- FUNGSI BUILD UTAMA ---
  @override
  Widget build(BuildContext context) {
    if (_loggedInUser == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: primaryPurple)),
      );
    }

    return ValueListenableBuilder(
      valueListenable: bookBox.listenable(keys: [widget.bookId]),
      builder: (context, Box box, _) {
        final data = box.get(widget.bookId);
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: const Center(child: Text("Buku ini telah dihapus.")),
          );
        }

        currentBookData = Map<String, dynamic>.from(data as Map);
        final title = currentBookData['title'] ?? 'Detail Buku';
        final authors = currentBookData['authors'] ?? 'Tanpa Penulis';
        final cover = currentBookData['coverUrl'] ?? '';
        final desc = currentBookData['description'] ?? 'Tidak ada sinopsis.';
        final category = currentBookData['category'] ?? '';
        final price = currentBookData['price']?.toDouble() ?? 0.0;
        final pages = currentBookData['pageCount'] ?? 0;
        final curPage = currentBookData['currentPage'] ?? 0;
        final progress = pages > 0 ? curPage / pages : 0.0;
        final reviewText = currentBookData['review'] ?? '';
        final rating = currentBookData['rating'] ?? 0;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            // Style AppBar sudah di-set dari main.dart
            actions: [
              IconButton(
                onPressed: () => _showDeleteConfirmationDialog(context, widget.bookId, title),
                icon: const Icon(Icons.delete_rounded),
                color: errorRed,
                tooltip: "Hapus Buku",
              ),
            ],
          ),

          // --- Tombol Floating (SAMA) ---
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (currentBookData['status'] == 'Finished')
                FloatingActionButton.extended(
                  heroTag: 'review',
                  backgroundColor: accentGreen,
                  label: const Text("Beri Review", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  icon: const Icon(Icons.star_rounded, color: Colors.white),
                  onPressed: () =>
                      _showReviewDialog(context, currentBookData, widget.bookId),
                ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'log',
                backgroundColor: accentYellow,
                label: const Text("Catat Log", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LogEntryPage(bookId: widget.bookId)),
                  );
                },
              ),
            ],
          ),

          // --- BODY UTAMA ---
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER BUKU ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: cover.isNotEmpty
                              ? Image.network(cover, width: 90, height: 130, fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(width: 90, height: 130, color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                              : Container(width: 90, height: 130, color: Colors.grey[200], child: const Icon(Icons.book, size: 40)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textPrimary)),
                                const SizedBox(height: 4),
                                Text(authors,
                                    style: const TextStyle(
                                        color: textSecondary, fontSize: 13)),
                                if (category.isNotEmpty && category != 'N/A')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Chip(
                                      label: Text(category, style: const TextStyle(fontSize: 11, color: textPrimary)),
                                      backgroundColor: accentYellow.withOpacity(0.3),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: accentYellow.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(accentYellow),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                const SizedBox(height: 4),
                                Text("$curPage / $pages halaman",
                                    style: const TextStyle(
                                        fontSize: 12, color: textSecondary))
                              ]),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- Harga Buku + Konversi ---
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildPriceDisplay(price),
                  ),
                ),
                
                const SizedBox(height: 20),

                // --- Sinopsis ---
                Card(
                  child: ExpansionTile(
                    title: const Text("Sinopsis",
                        style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    iconColor: primaryPurple,
                    collapsedIconColor: textSecondary,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(desc,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                                height: 1.5, color: textSecondary)),
                      )
                    ],
                  ),
                ),

                // --- Review Section ---
                if (rating > 0 || reviewText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Review Anda",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < rating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: accentYellow,
                                ),
                              ),
                            ),
                            if (reviewText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '"$reviewText"',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // --- Riwayat Log ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Riwayat Log Baca",
                        style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    DropdownButton<String>(
                      value: _selectedZone,
                      dropdownColor: cardBg,
                      items: _timeZoneOffsets.keys
                          .map((z) => DropdownMenuItem(
                              value: z,
                              child: Text(z,
                                  style: const TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedZone = v!),
                    )
                  ],
                ),
                const SizedBox(height: 8),

                // --- INI ADALAH KODE LOG YANG HILANG (BUKAN PLACEHOLDER) ---
                ValueListenableBuilder(
                  valueListenable: logBox.listenable(),
                  builder: (context, Box logs, _) {
                    final id = currentBookData['id'];
                    final userLogs = logs.values.where((e) {
                      try {
                        final m = Map<String, dynamic>.from(e as Map);
                        return m['bookId'] == id &&
                            m['username'] == _loggedInUser;
                      } catch (_) {
                        return false;
                      }
                    }).toList().reversed;

                    if (userLogs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                            child: Text("Belum ada log untuk buku ini.",
                                style: TextStyle(color: textSecondary))),
                      );
                    }

                    return Column(
                      children: userLogs.map((d) {
                        final log = Map<String, dynamic>.from(d as Map);
                        final t = _formatLogTime(log['timestamp']);
                        final note = log['notes'] ?? '';
                        final addr = log['address'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Halaman ${log['pageLogged']}",
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary)),
                                const SizedBox(height: 4),
                                Text(t,
                                    style: const TextStyle(
                                        fontSize: 12, color: textSecondary)),
                                if (note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('"$note"',
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: textPrimary,
                                            fontStyle: FontStyle.italic)),
                                  ),
                                if (addr.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text("$addr", // Ikon lokasi
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: textSecondary)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                // --- AKHIR KODE LOG ---
                const SizedBox(height: 100), // Padding bawah
              ],
            ),
          ),
        );
      },
    );
  }
}