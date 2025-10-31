import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'register_page.dart';
import '../utils/helpers.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Definisikan Warna dari Palette Anda
  // Kita jadikan final agar mudah dipakai
  final Color oliveGreen = const Color(0xFF84994F);
  final Color warmOrange = const Color(0xFFFCB53B);
  final Color burntRed = const Color(0xFFA72703);
  // Pale Yellow akan kita pakai di tempat lain nanti

  // 2. Controller untuk mengambil teks dari TextField
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 3. Logic untuk Login (Langkah 4 & 5 dari Roadmap)
  void _loginUser() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    // Buka 'kotak' user yang sudah kita buat di main.dart
    final userBox = Hive.box('userBox');

    // Cek data di Hive
    var userData = userBox.get(username);

    // DIUBAH: Cek apakah user ada DAN HASH password di dalam Map cocok
    if (userData != null && userData['password'] == hashPassword(password)) {
      // --- LOGIN BERHASIL ---

      // 1. Simpan Session (Status Login)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loggedInUser', username); // Simpan nama user

      await updateStreak(username); // Perbarui daily streak

      // 2. Tampilkan notifikasi sukses (opsional)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Login Berhasil!"),
            backgroundColor: oliveGreen, // Warna sukses
          ),
        );

        // 3. Pindah ke Halaman Utama (Homepage)
        // pushReplacement agar user tidak bisa "Back" ke halaman login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      // --- LOGIN GAGAL ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Username atau Password Salah!"),
            backgroundColor: burntRed, // Warna error
          ),
        );
      }
    }
  }

  // 4. Logic untuk pindah ke Halaman Register
  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  // 5. Jangan lupa hapus controller saat halaman ditutup
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kita pakai SafeArea agar tidak mentok status bar HP
    return Scaffold(
      backgroundColor: Colors.white,
      // SingleChildScrollView agar halaman bisa di-scroll saat keyboard muncul
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 48.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- BAGIAN JUDUL ---
                Text(
                  'Diary', // Nama Aplikasi Anda
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: oliveGreen, // Warna primer
                  ),
                ),
                const Text(
                  'Jangan lupa baca buku hari ini!', // Tagline
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 48.0), // Jarak
                // --- BAGIAN INPUT USERNAME ---
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person, color: oliveGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: oliveGreen, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0), // Jarak
                // --- BAGIAN INPUT PASSWORD ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: true, // Untuk menyembunyikan password
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: oliveGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: oliveGreen, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 32.0), // Jarak
                // --- TOMBOL LOGIN ---
                ElevatedButton(
                  // Panggil fungsi login saat ditekan
                  onPressed: _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: oliveGreen, // Warna primer
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'LOGIN',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16.0), // Jarak
                // --- TOMBOL KE REGISTER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Belum punya akun?',
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      // Panggil fungsi register saat ditekan
                      onPressed: _goToRegister,
                      child: Text(
                        'Register di sini',
                        style: TextStyle(
                          color: warmOrange, // Warna aksen
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
