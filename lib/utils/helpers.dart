import 'dart:convert'; // Untuk mengubah string ke bytes
import 'package:crypto/crypto.dart'; // Package crypto
import 'package:hive/hive.dart';

// Ini adalah fungsi untuk mengubah password menjadi hash SHA-256
String hashPassword(String password) {
  // Ubah password string menjadi bytes
  var bytes = utf8.encode(password);
  // Lakukan hashing
  var digest = sha256.convert(bytes);
  // Kembalikan sebagai string
  return digest.toString();
}

//ngurusin XP dan Level up
int xpForNextLevel (int level) {
  return level * 150;
}

//ketrigger kalo user daoet xp. true kalo naik level
Future<bool> addXp(String username, int amount) async {
  if (amount <= 0) return false;
  final profileBox = Hive.box('profileBox');
  var profile = Map<String, dynamic>.from(profileBox.get(username));
  int currentLevel = profile['level'];
  int currentXp = profile['xp'] + amount;

  int xpToNextLevel = xpForNextLevel(currentLevel);
  bool didLevelUp = false;

  // Cek apakah XP cukup untuk naik level
  while (currentXp >= xpToNextLevel) {
    currentLevel++; // NAIK LEVEL!
    currentXp -= xpToNextLevel; // Kurangi XP
    didLevelUp = true;

    // MENGGUNAKAN NAMA FUNGSI BARU
    xpToNextLevel = xpForNextLevel(currentLevel); // Hitung XP untuk level baru
  }

  // Simpan data baru
  profile['level'] = currentLevel;
  profile['xp'] = currentXp;
  await profileBox.put(username, profile);

  print(
    "User $username dapat $amount XP. Total XP: $currentXp. Level: $currentLevel",
  );
  return didLevelUp; // Kembalikan status
}

//ngurusin daily streak
Future<void> updateStreak(String username) async {
  final profileBox = Hive.box('profileBox');
  var profile = Map<String, dynamic>.from(profileBox.get(username));

  int currentStreak = profile['streak'] ?? 1;
  DateTime lastLogin = DateTime.parse(profile['lastLoginDate']);
  DateTime now = DateTime.now();

  //normalisasi tanggal
  DateTime lastLoginDateOnly = DateTime(
    lastLogin.year,
    lastLogin.month,
    lastLogin.day,
  );
  DateTime todayDateOnly = DateTime(now.year, now.month, now.day);

  int differenceInDays = todayDateOnly.difference(lastLoginDateOnly).inDays;
  if (differenceInDays == 1) {
    //beruntun
    currentStreak++;
  } else if (differenceInDays > 1) {
    //streak mati
    currentStreak = 1;
  }

  //update data
  profile['streak'] = currentStreak;
  profile['lastLoginDate'] = now.toIso8601String();
  await profileBox.put(username, profile);

  print("User $username login. Streak: $currentStreak hari.");
}
