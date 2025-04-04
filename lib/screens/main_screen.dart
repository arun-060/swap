import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'settings_screen.dart';
import 'rewards_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const CartScreen(),
    const RewardsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.grey[200],
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.black87),
              selectedIcon: Icon(Icons.home, color: Colors.black),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined, color: Colors.black87),
              selectedIcon: Icon(Icons.search, color: Colors.black),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined, color: Colors.black87),
              selectedIcon: Icon(Icons.shopping_cart, color: Colors.black),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.stars_outlined, color: Colors.black87),
              selectedIcon: Icon(Icons.stars, color: Colors.black),
              label: 'Rewards',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: Colors.black87),
              selectedIcon: Icon(Icons.settings, color: Colors.black),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
} 