import 'package:flutter/material.dart';

// Import 4 halaman (urutan import tidak masalah)
import 'dashboard_page.dart';
import 'collection_page.dart';
import 'add_book_page.dart'; // Ini tetap halaman untuk "Cari"
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; 
  
  // --- DIUBAH: Urutan List Halaman ---
  // Susunan baru: Home -> Cari/Tambah -> Koleksi -> Profil
  static const List<Widget> _pages = <Widget>[
    DashboardPage(),
    AddBookPage(),     // Halaman "Cari" ada di posisi kedua
    CollectionPage(),
    ProfilePage(),
  ];

  // --- DIUBAH: Urutan dan Nama Judul AppBar ---
  static const List<String> _pageTitles = [
    "Dashboard",
    "Cari Buku",       // Judul AppBar untuk halaman "Cari"
    "Koleksiku",
    "Profil"
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Definisikan warna Anda
  final Color oliveGreen = const Color(0xFF84994F);
  final Color warmOrange = const Color(0xFFFCB53B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      bottomNavigationBar: BottomNavigationBar(
        // --- DIUBAH: Urutan, Label, dan Ikon Item Navigasi ---
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded), // Ikon diganti ke "Search"
            label: 'Cari',                   // Label diganti ke "Cari"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: 'Koleksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
        
        currentIndex: _selectedIndex, 
        onTap: _onItemTapped,      

        // Style (Sama seperti sebelumnya)
        backgroundColor: Colors.white,      
        type: BottomNavigationBarType.fixed, 
        selectedItemColor: warmOrange,      
        unselectedItemColor: oliveGreen,    
        showUnselectedLabels: false,        
        showSelectedLabels: true,           
      ),
    );
  }
}