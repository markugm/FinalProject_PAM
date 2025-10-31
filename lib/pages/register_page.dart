import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/helpers.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // 1. Definisikan Warna
  final Color oliveGreen = const Color(0xFF84994F);
  final Color burntRed = const Color(0xFFA72703);

  // 2. Controller
  // BARU: Tambahkan controller untuk Email
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // BARU: State untuk melacak visibilitas password
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // 3. Logic untuk Register
  void _registerUser() {
    // BARU: Ambil data email
    final email = _emailController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // --- Validasi ---
    // DIUBAH: Tambahkan cek email
    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Email, Username, dan Password tidak boleh kosong!",
          ),
          backgroundColor: burntRed,
        ),
      );
      return;
    }

    // BARU: Validasi format email sederhana
    String emailPattern =
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+";
    bool isEmailValid = RegExp(emailPattern).hasMatch(email);
    if (!isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Format email tidak valid!"),
          backgroundColor: burntRed,
        ),
      );
      return;
    }

    if (password.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Password harus terdiri dari minimal 5 karakter!"),
          backgroundColor: burntRed,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Password dan Konfirmasi Password tidak cocok!"),
          backgroundColor: burntRed,
        ),
      );
      return;
    }

    final userBox = Hive.box('userBox');

    //cek duplicate email
    final allUsers = userBox.values.toList();

    final emailExists = allUsers.any((user) {
      try {
        final userMap = Map<String, dynamic>.from(user as Map);
        return userMap['email'] == email;
      } catch (e) {
        return false;
      }
    });

    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Email sudah digunakan. Silakan gunakan email lain.",
          ),
          backgroundColor: burntRed,
        ),
      );
      return;
    }

    if (userBox.containsKey(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Username sudah digunakan."),
          backgroundColor: burntRed,
        ),
      );
      return;
    }

    // --- PROSES SIMPAN DATA (DIUBAH) ---
    final userData = {
      'email': email,
      // Panggil fungsi hashPassword kita
      'password': hashPassword(password), // <-- GANTI BARIS INI
    };

    // Username tetap menjadi Kunci Utama (Key)
    userBox.put(username, userData);

    //inisialisasi profil gamifikasi
    final profileBox = Hive.box('profileBox');
    final userProfile = {
      'xp':0,
      'level':1,
      //daily streak
      'streak':1,
      'lastLoginDate':DateTime.now().toIso8601String(), //catat waktu daftar
      'hasLoggedFirstTime': false,
    };
    profileBox.put(username, userProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Registrasi Berhasil! Silakan kembali dan login."),
        backgroundColor: oliveGreen,
      ),
    );

    Navigator.pop(context);
  }

  // 4. Dispose
  @override
  void dispose() {
    // BARU: dispose email controller
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: oliveGreen),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Buat Akun Diary',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: oliveGreen,
                  ),
                ),
                const SizedBox(height: 32.0),

                // --- BARU: BAGIAN INPUT EMAIL ---
                TextFormField(
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress, // Keyboard khusus email
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: oliveGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: oliveGreen, width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // --- BAGIAN INPUT USERNAME ---
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username Baru',
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
                const SizedBox(height: 16.0),

                // --- DIUBAH: BAGIAN INPUT PASSWORD (dengan icon mata) ---
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible, // Tergantung state
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
                    // BARU: Icon Mata
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: oliveGreen,
                      ),
                      onPressed: () {
                        // Ubah state untuk show/hide password
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // --- DIUBAH: BAGIAN INPUT KONFIRMASI PASSWORD (dengan icon mata) ---
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible, // Tergantung state
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: Icon(Icons.lock_outline, color: oliveGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: oliveGreen, width: 2.0),
                    ),
                    // BARU: Icon Mata
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: oliveGreen,
                      ),
                      onPressed: () {
                        // Ubah state untuk show/hide password
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),

                // --- TOMBOL REGISTER ---
                ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: oliveGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'REGISTER',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
