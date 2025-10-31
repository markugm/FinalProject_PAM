import 'package:final_project/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk membatasi input (hanya angka)
import 'package:geolocator/geolocator.dart'; // Wajib untuk LBS
import 'package:geocoding/geocoding.dart'; // Untuk konversi lat/lon ke alamat
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk cek 'sudah pernah notif?'
import '../utils/notification_service.dart'; // Service notifikasi kita
import '../utils/helpers.dart'; // Untuk fungsi addXp

class LogEntryPage extends StatefulWidget {
  // Kita butuh ID buku agar tahu buku mana yang di-log
  final String bookId;

  const LogEntryPage({
    super.key,
    required this.bookId, // Wajib dikirim dari halaman koleksi
  });

  @override
  State<LogEntryPage> createState() => _LogEntryPageState();
}

class _LogEntryPageState extends State<LogEntryPage> {
  // 1. Definisikan Warna
  final Color oliveGreen = const Color(0xFF84994F);
  final Color warmOrange = const Color(0xFFFCB53B);
  final Color burntRed = const Color(0xFFA72703);

  // 2. Database Boxes
  late Box bookBox; // "late" berarti kita akan mengisinya nanti
  late Box logBox;

  // 3. Data Buku Saat Ini
  Map<String, dynamic> currentBookData = {};
  Map<String, dynamic> _originalBookData = {};

  // 4. Controllers untuk Form
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // 5. State untuk LBS
  String _locationMessage = "Tambah Check-In Lokasi";
  Position? _currentPosition; // Untuk menyimpan Lat/Lon
  String? _currentAddress; // Untuk menyimpan alamat

  // 6. Inisialisasi: Ambil data buku saat halaman dibuka
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

    // Isi form dengan data yang sudah ada (jika ada)
    _pageController.text = currentBookData['currentPage'].toString();
    _priceController.text = currentBookData['price'].toString();
  }

  // 7. Logic LBS (Roadmap Day 3, Step 3)
  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationMessage = "Sedang mencari lokasi...";
      _currentAddress = null;
    });

    try {
      // 1. Cek izin
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = "Izin lokasi ditolak.";
          });
          return;
        }
      }

      // 2. Ambil Lokasi
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
        Placemark place = placemarks[0];
        _currentAddress =
            "${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}";
        _currentAddress = _currentAddress!.replaceAll(RegExp(r', ,'), ',');
        setState(() {
          _locationMessage = "Check-in di: $_currentAddress";
        });
      } catch (e) {
        print("Error reverse geocoding: $e");
        setState(() {
          _locationMessage =
              "Lat: ${_currentPosition!.latitude}, Lon: ${_currentPosition!.longitude}";
          _currentAddress = null;
        });
      }
    } catch (e) {
      setState(() {
        _locationMessage = "Gagal mendapatkan lokasi. Cek GPS.";
      });
    }
  }

  void _saveLog() async {
    // Validasi sederhana
    final int currentPage = int.tryParse(_pageController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final String notes = _notesController.text;

    if (currentPage > (currentBookData['pageCount'] ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Halaman tidak boleh melebihi total halaman (${currentBookData['pageCount']})",
          ),
          backgroundColor: burntRed,
        ),
      );
      return;
    }

    // DAPATKAN USERNAME YANG LOGIN
    final prefs = await SharedPreferences.getInstance();
    final String? loggedInUser = prefs.getString(
      'loggedInUser',
    ); // Ambil dari session
    if (loggedInUser == null) return;

    final profileBox = Hive.box('profileBox');
    var profile = Map<String, dynamic>.from(profileBox.get(loggedInUser));

    // --- A. Simpan Log ke logBox ---
    final logData = {
      'bookId': currentBookData['id'],
      'timestamp': DateTime.now(),
      'pageLogged': currentPage,
      'notes': notes,
      'latitude': _currentPosition?.latitude,
      'longitude': _currentPosition?.longitude,
      'address': _currentAddress,
      'username': loggedInUser,
    };
    logBox.add(logData);

    // --- B. Update data utama di bookBox ---
    currentBookData['currentPage'] = currentPage;
    currentBookData['price'] = price; // Kriteria Konversi Uang

    // Cek jika buku selesai
    if (currentPage == (currentBookData['pageCount'] ?? 0) && currentPage > 0) {
      currentBookData['status'] = 'Finished';
    } else if (currentBookData['status'] != 'Finished') {
      currentBookData['status'] = 'Reading Now';
    }

    // Simpan kembali Map yang sudah di-update ke bookBox
    bookBox.put(widget.bookId, currentBookData);

    //kasi XP
    int gainedXP = 0;
    bool wasFirstLog = !(profile['hasLoggedFirstTime'] ?? false);
    if (wasFirstLog) {
      gainedXP += 50; // XP untuk log pertama
      profile['hasLoggedFirstTime'] = true; // Tandai sudah log pertama
    }

    bool justFinishedBook = (currentBookData['status'] == 'Finished' &&
        _originalBookData['status'] != 'Finished');
    if (justFinishedBook) {
      gainedXP += 200; // XP untuk menyelesaikan buku
      //baca 100 halaman
      if (currentBookData['pageCount'] >= 100){
        gainedXP += 100; // Bonus untuk buku tebal
      }
    }

    await profileBox.put(loggedInUser, profile); // Simpan perubahan profil

    if (gainedXP > 0) {
      bool leveledUp = await addXp(loggedInUser, gainedXP);
      if (leveledUp && mounted) {
        var updatedProfile = Map<String, dynamic>.from(profileBox.get(loggedInUser));
        int newLevel = updatedProfile['level'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Level Up! Kamu naik ke Level $newLevel!"),
            backgroundColor: warmOrange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    _triggerFirstLogNotification(wasFirstLog, loggedInUser);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Log berhasil disimpan!"),
          backgroundColor: oliveGreen,
        ),
      );
    }

    Navigator.pop(context);
  }

  Future<void> _triggerFirstLogNotification(bool wasFirstLog, String username) async {
    if (wasFirstLog) {
      // Jika ini adalah log pertama, kirim notif
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

  @override
  void dispose() {
    _pageController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentBookData['title'] ?? 'Catat Log'),
        backgroundColor: oliveGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Form Halaman ---
            Text(
              "Total Halaman Buku: ${currentBookData['pageCount']}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pageController,
              decoration: const InputDecoration(
                labelText: 'Halaman Terakhir Dibaca',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly, // Hanya boleh angka
              ],
            ),
            const SizedBox(height: 24),

            // --- Form Harga (Kriteria Konversi Uang) ---
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Harga Beli Buku (IDR)',
                prefixText: "Rp ",
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 24),

            // --- Form Notes ---
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan Baca (Opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4, // Teks area
            ),
            const SizedBox(height: 24),

            // --- Tombol LBS (Kriteria LBS) ---
            OutlinedButton.icon(
              icon: const Icon(Icons.location_on),
              label: Text(_locationMessage),
              onPressed: _getCurrentLocation, // Panggil fungsi LBS
              style: OutlinedButton.styleFrom(
                foregroundColor: oliveGreen,
                side: BorderSide(color: oliveGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // --- Tombol Simpan ---
            ElevatedButton(
              onPressed: _saveLog, // Panggil fungsi Simpan
              style: ElevatedButton.styleFrom(
                backgroundColor: warmOrange, // Warna aksen
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text(
                'SIMPAN LOG',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
