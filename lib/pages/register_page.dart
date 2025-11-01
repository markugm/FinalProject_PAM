import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart'; // Import warna BARU

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _registerUser() async {
    setState(() { _isLoading = true; });

    final email = _emailController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validasi
    if (username.isEmpty || password.isEmpty || email.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email, Username, dan Password tidak boleh kosong!"), backgroundColor: errorRed));
       setState(() { _isLoading = false; });
       return;
    }
    String emailPattern = r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
    if (!RegExp(emailPattern).hasMatch(email)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Format email tidak valid!"), backgroundColor: errorRed));
       setState(() { _isLoading = false; });
       return;
    }
    String usernamePattern = r"^[a-zA-Z0-9_.-]+$"; 
    if (username.isEmpty || !RegExp(usernamePattern).hasMatch(username)) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username tidak valid! Hanya boleh huruf, angka, dan '_', '.', '-' (tanpa spasi)."), 
          backgroundColor: errorRed
        ),
      );
       setState(() { _isLoading = false; });
       return;
    }
    if (password.contains(' ')) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password tidak boleh mengandung spasi!"), 
          backgroundColor: errorRed
        ),
      );
       setState(() { _isLoading = false; });
       return;
    }
    if (password.length < 5) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password minimal harus 5 karakter!"), backgroundColor: errorRed));
       setState(() { _isLoading = false; });
       return;
    }
    if (password != confirmPassword) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password dan Konfirmasi Password tidak cocok!"), backgroundColor: errorRed));
       setState(() { _isLoading = false; });
       return;
    }

    final userBox = Hive.box('userBox');
    
    final emailExists = userBox.values.any((user) {
        try { return (user as Map)['email'] == email; } 
        catch (e) { return false; }
    });
    if (emailExists) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email ini sudah terdaftar."), backgroundColor: errorRed));
       setState(() { _isLoading = false; });
       return;
    }
    
    if (userBox.containsKey(username)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username sudah digunakan."), backgroundColor: errorRed));
       setState(() { _isLoading = false; });
       return;
    }

    final userData = {
      'email': email,
      'password': hashPassword(password),
    };
    userBox.put(username, userData);

    final profileBox = Hive.box('profileBox');
    final userProfile = {
      'xp': 0,
      'level': 1,
      'streak': 1,
      'lastLoginDate': DateTime.now().toIso8601String(),
      'hasLoggedFirstTime': false,
    };
    profileBox.put(username, userProfile);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registrasi Berhasil! Silakan login."),
          backgroundColor: accentGreen,
        ),
      );
      Navigator.pop(context); // Kembali ke halaman login
    }
  }

  // --- UI BARU (VIBRANT TECH - DITINGKATKAN) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""), // Judul kosong, kita pakai custom di body
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ilustrasi/Ikon Besar untuk Menarik Perhatian
              // Kamu bisa ganti ini dengan Asset gambar ilustrasi kalau ada
              Icon(Icons.menu_book, size: 80, color: accentPink),
              const SizedBox(height: 16),
              const Text(
                'Daftar Sekarang!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Buat akun Diary-mu dan mulai petualangan membaca.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 40), // Jarak lebih jauh

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: textSecondary,
                    ),
                    onPressed: () {
                      setState(() { _isPasswordVisible = !_isPasswordVisible; });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: textSecondary,
                    ),
                    onPressed: () {
                      setState(() { _isConfirmPasswordVisible = !_isConfirmPasswordVisible; });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        'DAFTAR',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24), // Jarak dari tombol ke teks

              // Link ke Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun?', style: TextStyle(color: textSecondary)),
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Kembali ke Login
                    style: TextButton.styleFrom(
                      foregroundColor: primaryPurple,
                    ),
                    child: const Text(
                      'Login di sini',
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