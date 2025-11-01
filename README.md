# 📚 Diary App
Aplikasi jurnal membaca personal dengan sistem gamifikasi yang mendorong kebiasaan membaca setiap hari.  
Dibangun menggunakan **Flutter & Dart** — dengan penyimpanan data lokal berbasis **Hive**, dan integrasi **Google Books API** untuk pencarian metadata buku.

### Identitas Pengembang
Nama: Sania Dinara Safina
NIM: 124230020
Kelas: PAM SI-D

---

## ✨ Fitur Utama

### Autentikasi
- Registrasi & Login menggunakan **username** dan **password (SHA-256 hash)**.
- Validasi input dan pengecekan duplikat otomatis.
- Penyimpanan status login via `shared_preferences`.
- Sistem **daily streak** untuk memotivasi login rutin.

### Dashboard (Home)
- Menampilkan ringkasan level, XP, streak, dan statistik membaca.
- Progress XP divisualisasikan lewat **LinearProgressIndicator**.
- Menampilkan pencapaian (Achievements) seperti:
  - 📖 Kutu Buku Pemula — selesai 1 buku pertama.
  - 🏃 Maraton Pemula — mencapai 1000 halaman dibaca.
  - 📚 Kolektor — menyimpan ≥5 buku.
  - 🌍 Penjelajah — menggunakan fitur lokasi (LBS).

### Cari Buku
- Pencarian data buku dari **Google Books API**.
- Menampilkan hasil dalam list (judul, penulis, cover).
- Tambah buku ke koleksi pribadi langsung dari hasil pencarian.
- Cegah duplikasi otomatis berdasarkan `GoogleBookID`.

### Koleksi Buku
- Menampilkan seluruh buku milik pengguna aktif (dari Hive).
- Setiap kartu buku menampilkan:
  - Cover, judul, progress baca.
- Navigasi ke detail buku untuk melihat sinopsis, review, dan log.

### Detail Buku
- Menampilkan informasi lengkap buku: cover, judul, penulis, kategori, sinopsis.
- Konversi mata uang **IDR ⇄ USD ⇄ EUR** untuk harga buku.
- Menampilkan **review** dan **rating** pengguna.
- Daftar riwayat log (baca + lokasi + catatan).
- Fitur hapus buku & log terkait.
- Tombol cepat: `Catat Log` dan `Beri Review`.

### Catat Log Membaca
- Tambahkan log bacaan baru dengan:
  - Halaman terakhir dibaca.
  - Catatan opsional.
  - Lokasi (via GPS + Reverse Geocoding).
- Otomatis memperbarui progress buku dan status (Reading/Finished).
- Dapat XP tambahan jika:
  - Pertama kali menambah log (+50 XP).
  - Menyelesaikan buku (+200 XP, +100 XP ekstra jika >100 halaman).

### 🏆 Sistem Gamifikasi
| Aksi | XP |
|------|----|
| Menambah log pertama kali | +50 |
| Selesai membaca 1 buku | +200 |
| Buku >100 halaman | +100 |
| Review pertama kali | +50 |

- XP otomatis menaikkan level (`XP = Level * 150`).
- Notifikasi lokal dikirim saat naik level atau log pertama berhasil.

---

## 🧩 Arsitektur & Teknologi

| Komponen | Teknologi |
|-----------|------------|
| UI | Flutter (Material Design 3) |
| Bahasa | Dart |
| Database Lokal | Hive |
| Session | SharedPreferences |
| API Buku | Google Books API |
| Lokasi | Geolocator + Geocoding |
| Notifikasi | flutter_local_notifications |
| Waktu | timezone |
| Enkripsi | crypto (SHA-256) |

---

##  📡 API Reference

Google Books API digunakan untuk metadata buku:
https://developers.google.com/books
