import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state_management/auth_provider.dart';
import 'dashboard_screen.dart';
import 'notes_screen.dart';
import '../state_management/notes_provider.dart';

final scaffoldKeyProvider = Provider((ref) => GlobalKey<ScaffoldState>());

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = ref.watch(scaffoldKeyProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      key: scaffoldKey,
      drawer: _buildDrawer(context, user),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DashboardScreen(),
          NotesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        elevation: 10,
        height: 65,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Notes',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('SmartHub User', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.email ?? 'Not logged in'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 45, color: Colors.blue),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
          _buildDrawerItem(Icons.note_alt, 'Notes', 1),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => _showLogoutDialog(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(title, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      )),
      selected: isSelected,
      onTap: () {
        _onItemTapped(index);
        Navigator.pop(context);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to sign out of SmartHub?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Working')),
          ElevatedButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
