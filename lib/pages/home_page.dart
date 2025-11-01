import 'package:flutter/material.dart';
import '../utils/constants.dart';

import 'dashboard_page.dart';
import 'collection_page.dart';
import 'add_book_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      DashboardPage(
        onNavigateToSearch: () => _onItemTapped(1),
        onNavigateToCollection: () => _onItemTapped(2),
      ),
      const AddBookPage(),
      const CollectionPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // --- ✨ FLOATING NAVBAR (FINAL POLISH) ---
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 27),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg, // ✅ flat background
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06), // soft shadow
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: textPrimary,
              unselectedItemColor: textSecondary.withOpacity(0.6),
              showSelectedLabels: false,
              showUnselectedLabels: false,
              iconSize: 26,

              items: [
                _buildNavItem(Icons.home_filled, 0),
                _buildNavItem(Icons.search_rounded, 1),
                _buildNavItem(Icons.library_books_rounded, 2),
                _buildNavItem(Icons.person_rounded, 3),
              ],
            ),
          ),
        ),
      ),

    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, int index) {
    final bool isActive = _selectedIndex == index;

    return BottomNavigationBarItem(
      label: '',
      icon: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: isActive ? 1.15 : 1.0,
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive
                ? accentYellow.withOpacity(0.30) // ✅ warm yellow solid, no glow
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isActive ? accentYellow : textSecondary,
            size: isActive ? 26 : 24,
          ),
        ),
      ),
    );
  }
}
