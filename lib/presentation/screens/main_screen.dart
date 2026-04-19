import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../state_management/auth_provider.dart';
import '../../data/providers/repository_providers.dart';
import 'dashboard_screen.dart';
import 'notes_screen.dart';

final profilePicProvider = FutureProvider<String?>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).getProfilePicture();
});

final displayNameProvider = FutureProvider<String?>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).getDisplayName();
});

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 25);
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        await ref.read(authControllerProvider.notifier).updateProfilePicture(file);
        ref.invalidate(profilePicProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editDisplayName(String? currentName) async {
    final controller = TextEditingController(text: currentName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != currentName) {
      try {
        await ref.read(authControllerProvider.notifier).updateDisplayName(result);
        ref.invalidate(displayNameProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User name updated successfully!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final authState = ref.watch(authControllerProvider);
    final profilePicAsync = ref.watch(profilePicProvider);
    final displayNameAsync = ref.watch(displayNameProvider);

    return Scaffold(
      drawer: _buildDrawer(context, user, authState, profilePicAsync, displayNameAsync),
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

  Widget _buildDrawer(BuildContext context, dynamic user, AsyncValue<void> authState, AsyncValue<String?> profilePicAsync, AsyncValue<String?> displayNameAsync) {
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
            accountName: displayNameAsync.when(
              data: (name) {
                final hasName = name != null && name.isNotEmpty;
                return InkWell(
                  onTap: () => _editDisplayName(name),
                  child: Row(
                    children: [
                      Text(
                        hasName ? name : 'Edit User Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: hasName ? FontStyle.normal : FontStyle.italic,
                          color: hasName ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, size: 14, color: Colors.white70),
                    ],
                  ),
                );
              },
              loading: () => const Text('Loading...'),
              error: (_, __) => const Text('SmartHub User'),
            ),
            accountEmail: Text(user?.email ?? 'Not logged in'),
            currentAccountPicture: GestureDetector(
              onTap: authState.isLoading ? null : _pickImage,
              child: profilePicAsync.when(
                data: (base64String) => Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: base64String != null 
                          ? MemoryImage(base64Decode(base64String)) 
                          : null,
                      child: base64String == null && !authState.isLoading
                          ? const Icon(Icons.person, size: 45, color: Colors.blue) 
                          : (authState.isLoading ? const CircularProgressIndicator() : null),
                    ),
                    if (!authState.isLoading)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.blue),
                        ),
                      ),
                  ],
                ),
                loading: () => const CircleAvatar(child: CircularProgressIndicator()),
                error: (_, __) => const CircleAvatar(child: Icon(Icons.error)),
              ),
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
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.pop(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
