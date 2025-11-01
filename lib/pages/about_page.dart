import 'package:flutter/material.dart';
import 'package:final_project/utils/constants.dart'; // Import warna

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar otomatis pakai style dari main.dart
      appBar: AppBar(
        title: const Text("Tentang Aplikasi"),
        // Tombol back akan muncul otomatis
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0), // Padding besar agar rapi
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Bagian Header ---
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.book_rounded, size: 62, color: primaryPurple),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Diary (Daily Read)",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryPurple,
                        ),
                      ),
                      Text(
                        "Final Project Pemrograman Aplikasi Mobile",
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 48, thickness: 1),

            // --- 1. Identitas Pembuat ---
            _buildSectionHeader("Identitas Pembuat"),
            const SizedBox(height: 8),
            _buildSectionContent(
              "Aplikasi ini dirancang dan dikembangkan oleh:\n"
              "Nama: Sania Dinara Safina\n"
              "NIM: 124230020\n"
              "Kelas: PAM SI-D"
            ),
            const SizedBox(height: 32),

            // --- 2. Pesan dan Kesan ---
            _buildSectionHeader("Pesan & Kesan"),
            const SizedBox(height: 8),
            _buildSectionContent(
              "Mata kuliah Pemrograman Aplikasi Mobile memberikan pengalaman yang sangat berharga dalam memahami dan mengembangkan aplikasi mobile. Walau pembelajaran yang diberikan sangat ringkas, mahasiswa ditantang untuk dapat langsung mengaplikasikan teori ke dalam proyek nyata.\n"
              "Semoga kedepannya mata kuliah ini terus berkembang dan dapat memberikan lebih banyak wawasan tentang teknologi mobile terkini. Untuk mahasiswa yang akan mengambil mata kuliah ini, persiapkan diri dengan baik dan jangan ragu untuk bereksperimen dengan berbagai fitur Flutter."
            ),
            const SizedBox(height: 32),

            // --- 3. Ucapan Terima Kasih ---
            _buildSectionHeader("Ucapan Terima Kasih"),
            const SizedBox(height: 8),
            _buildSectionContent(
              "Saya ingin mengucapkan terima kasih yang sebesar-besarnya kepada:\n"
              "1. Allah SWT, Tuhan yang maha esa\n"
              "2. Mamah, yang telah memberi uang saku sehingga saya bisa stress-relief\n"
              "3. Sahabat-sahabat yang telah memberikan dukungan, bantuan, dan masukan\n"
              "4. Band-band rock dan metal kecintaan saya, Xdinary Heroes, BMTH, 5SOS, dan Linkin Park, yang telah membersamai melalui karya-karyanya\n"
              "5. Pihak-pihak lain yang tidak dapat saya sebutkan satu per satu\n"
              "6. dan terakhir, Pak Bagus, selaku dosen mata kuliah Pemrograman Aplikasi Mobile atas tugasnya yang sangat menyenangkan.\n\n"
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget untuk Judul ---
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryPurple,
      ),
    );
  }

  // --- Helper Widget untuk Isi Teks ---
  Widget _buildSectionContent(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: textPrimary,
        height: 1.5, // Jarak antar baris
      ),
    );
  }
}