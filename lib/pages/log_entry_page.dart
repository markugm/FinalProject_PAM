import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_project/utils/notification_service.dart';
import 'package:final_project/utils/helpers.dart';
import 'package:final_project/utils/constants.dart'; // Import warna BARU

class LogEntryPage extends StatefulWidget {
  final String bookId; // Ini adalah HIVE KEY

  const LogEntryPage({super.key, required this.bookId});

  @override
  State<LogEntryPage> createState() => _LogEntryPageState();
}

class _LogEntryPageState extends State<LogEntryPage> {
  // --- SEMUA LOGIC & STATE (SAMA) ---
  late Box bookBox;
  late Box logBox;
  Map<String, dynamic> currentBookData = {};
  Map<String, dynamic> _originalBookData = {};
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _locationMessage = "Tambah Check-In Lokasi";
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false; // Untuk loading tombol Simpan

  @override
  void initState() {
    super.initState();
    bookBox = Hive.box('bookBox');
    logBox = Hive.box('logBox');
    var data = bookBox.get(widget.bookId);
    if (data != null) {
      currentBookData = Map<String, dynamic>.from(data as Map);
      _originalBookData = Map<String, dynamic>.from(data);
    }
    _pageController.text = currentBookData['currentPage'].toString();
    _priceController.text = currentBookData['price'].toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- SEMUA FUNGSI LOGIC (SAMA PERSIS, TIDAK DIUBAH) ---

  Future<void> _getCurrentLocation() async {
    setState(() { _locationMessage = "Sedang mencari lokasi..."; _currentAddress = null; });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationMessage = "Izin lokasi ditolak."; });
          return;
        }
      }
      _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude);
        Placemark place = placemarks[0];
        _currentAddress = "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}";
        _currentAddress = _currentAddress!.replaceAll(RegExp(r'^, |, , '), ''); // Bersihkan koma
        _currentAddress = _currentAddress!.replaceAll(RegExp(r'^, '), ''); // Bersihkan koma di awal
        setState(() { _locationMessage = "Check-in di: $_currentAddress"; });
      } catch (e) {
        setState(() { _locationMessage = "Check-in LBS Berhasil (Tanpa Alamat)"; _currentAddress = null; });
      }
    } catch (e) {
      setState(() { _locationMessage = "Gagal mendapatkan lokasi. Cek GPS."; });
    }
  }

  Future<void> _triggerFirstLogNotification(bool wasFirstLog, String username) async {
    if (wasFirstLog) {
      final notificationService = NotificationService();
      await notificationService.requestPermissions();
      await notificationService.scheduleNotificationNow(
        title: "Diary: Log Pertamamu!",
        body: "Keren! Kamu dapat +50 XP. Terus baca untuk naik level!",
        delaySeconds: 3,
        notificationId: 2,
      );
      print("Notifikasi first log dipicu untuk $username!");
    } else {
      print("Bukan log pertama, notifikasi dilewati.");
    }
  }

  void _saveLog() async {
    setState(() { _isLoading = true; }); 

    final int currentPage = int.tryParse(_pageController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final String notes = _notesController.text;

    // Validasi
    if (currentPage > (currentBookData['pageCount'] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Halaman tidak boleh melebihi total halaman (${currentBookData['pageCount']})"), backgroundColor: errorRed));
      setState(() { _isLoading = false; });
      return;
    }
    if (_pageController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Halaman terakhir dibaca tidak boleh kosong!"), backgroundColor: errorRed));
       setState(() { _isLoading = false; });
       return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? loggedInUser = prefs.getString('loggedInUser');
    if (loggedInUser == null) {
       setState(() { _isLoading = false; });
       return;
    }
    final profileBox = Hive.box('profileBox');
    var profile = Map<String, dynamic>.from(profileBox.get(loggedInUser));

    // Simpan Log
    final logData = {
      'bookId': currentBookData['id'], 'timestamp': DateTime.now(),
      'pageLogged': currentPage, 'notes': notes,
      'latitude': _currentPosition?.latitude, 'longitude': _currentPosition?.longitude,
      'address': _currentAddress, 'username': loggedInUser,
    };
    logBox.add(logData);

    // Update Buku (termasuk patch re-reading)
    currentBookData['currentPage'] = currentPage;
    currentBookData['price'] = price;
    if (currentPage == (currentBookData['pageCount'] ?? 0) && currentPage > 0) {
      currentBookData['status'] = 'Finished';
    } else if (_originalBookData['status'] != 'Finished') {
      currentBookData['status'] = 'Reading Now';
    }
    bookBox.put(widget.bookId, currentBookData);

    // Logic XP
    int gainedXP = 0;
    bool wasFirstLog = !(profile['hasLoggedFirstTime'] ?? false);
    if (wasFirstLog) {
      gainedXP += 50; 
      profile['hasLoggedFirstTime'] = true; 
    }
    bool justFinishedBook = (currentBookData['status'] == 'Finished' &&
          _originalBookData['status'] != 'Finished');
    if (justFinishedBook) {
      gainedXP += 200; 
      if (currentBookData['pageCount'] >= 100){
        gainedXP += 100; 
      }
    }
    await profileBox.put(loggedInUser, profile); 

    if (gainedXP > 0) {
      bool leveledUp = await addXp(loggedInUser, gainedXP);
      if (leveledUp && mounted) {
        var updatedProfile = Map<String, dynamic>.from(profileBox.get(loggedInUser));
        int newLevel = updatedProfile['level'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Level Up! Kamu naik ke Level $newLevel!"),
            backgroundColor: accentYellow,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    _triggerFirstLogNotification(wasFirstLog, loggedInUser);
    
    setState(() { _isLoading = false; }); 

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Log berhasil disimpan!"), backgroundColor: accentGreen),
      );
      Navigator.pop(context);
    }
  }

  // --- UI BARU (VIBRANT & COLORFUL) ---
  @override
  Widget build(BuildContext context) {
    final title = currentBookData['title'] ?? 'Catat Log';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        // Style AppBar sudah di-set dari main.dart
      ),
      // --- Tombol Simpan 'Sticky' di Bawah ---
      bottomNavigationBar: _buildStickySaveButton(),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian 1: Input Utama ---
            _buildSectionHeader(Icons.edit_note_rounded, "Catat Progres"),
            const SizedBox(height: 12),
            
            // Kartu Progres
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Halaman Buku: ${currentBookData['pageCount'] ?? '-'}",
                      style: const TextStyle(color: textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    // Field Halaman (sudah pakai style dari main.dart)
                    TextField(
                      controller: _pageController,
                      decoration: const InputDecoration(
                        labelText: 'Halaman Terakhir Dibaca',
                        prefixIcon: Icon(Icons.menu_book_rounded),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Field Harga (sudah pakai style dari main.dart)
                    TextField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Beli Buku (IDR)',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- Bagian 2: Catatan & Lokasi ---
            const SizedBox(height: 28),
            _buildSectionHeader(Icons.notes_rounded, "Catatan & Lokasi"),
            const SizedBox(height: 12),
            
            // Kartu Catatan
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: "Tulis pemikiranmu di sini...",
                    border: InputBorder.none, // Bikin lebih 'clean'
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                  ),
                  maxLines: 4,
                  maxLength: 200,
                  style: const TextStyle(color: textPrimary, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol LBS (Style OutlinedButton baru)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.location_on_outlined, size: 22),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0), // Padding
                  child: Text(
                    _locationMessage,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryPurple, // <-- WARNA BARU
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: primaryPurple.withOpacity(0.5), // <-- WARNA BARU
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14), // <-- Samakan dengan input
                  ),
                  backgroundColor: cardBg,
                  foregroundColor: primaryPurple, // <-- WARNA BARU
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 100), // Padding bawah
          ],
        ),
      ),
    );
  }

  // --- Helper Widget: Judul Bagian ---
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: textPrimary, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  // --- Helper Widget: Tombol Simpan 'Sticky' ---
  Widget _buildStickySaveButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), // Padding
        decoration: BoxDecoration(
          color: cardBg, // Background putih
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5), // Shadow ke atas
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveLog,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPurple, // <-- WARNA UNGU (AKSI UTAMA)
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: _isLoading // Tampilkan Loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Row( // Tampilkan Ikon dan Teks
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      'SIMPAN LOG',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}