import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart'; // Import warna BARU
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false; // Untuk show/hide password

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIC LOGIN (SUDAH BENAR) ---
  void _loginUser() async {
    // 1. Validasi Input Sederhana
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan Password tidak boleh kosong!"),
          backgroundColor: errorRed, // Pakai warna error baru
        ),
      );
      return; // Hentikan fungsi
    }
    
    setState(() { _isLoading = true; });

    final username = _usernameController.text;
    final password = _passwordController.text;
    final userBox = Hive.box('userBox');
    var userData = userBox.get(username);

    // Cek hash password
    if (userData != null && userData['password'] == hashPassword(password)) {
      // --- LOGIN BERHASIL ---
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loggedInUser', username);
      await updateStreak(username); // Panggil update streak

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      // --- LOGIN GAGAL ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Username atau Password Salah!"),
            backgroundColor: errorRed,
          ),
        );
      }
    }
    
    // Pastikan loading berhenti
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  // --- UI BARU (VIBRANT TECH) ---
  @override
  Widget build(BuildContext context) {
    // Scaffold sudah otomatis pakai 'scaffoldBg' dari main.dart
    return Scaffold(
      body: Center( // Pusatkan konten
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ganti dengan logo/ikonmu
              const Icon(Icons.book_rounded, size: 80, color: accentPink),
              const SizedBox(height: 16),
              const Text(
                'Selamat Datang!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login ke akun Diary-mu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 40),

              // Username Field (Otomatis pakai tema baru)
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              // Password Field (Otomatis pakai tema baru)
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton( // Tombol show/hide password
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Login Button (Otomatis pakai tema baru)
              ElevatedButton(
                onPressed: _isLoading ? null : _loginUser,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'LOGIN',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),

              // Link ke Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Belum punya akun?', style: TextStyle(color: textSecondary)),
                  TextButton(
                    onPressed: _goToRegister,
                    style: TextButton.styleFrom(
                      foregroundColor: primaryPurple, // Pakai warna primer
                    ),
                    child: const Text(
                      'Daftar di sini',
                      style: TextStyle(
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
    );
  }
}