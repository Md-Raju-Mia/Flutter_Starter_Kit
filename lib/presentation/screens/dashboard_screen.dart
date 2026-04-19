import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state_management/dashboard_provider.dart';
import '../state_management/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import 'main_screen.dart'; // To access profilePicProvider and displayNameProvider

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final weatherAsync = ref.watch(weatherProvider('London'));
    final postsAsync = ref.watch(postsProvider);
    final profilePicAsync = ref.watch(profilePicProvider);
    final displayNameAsync = ref.watch(displayNameProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('SmartHub Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(postsProvider);
          ref.invalidate(displayNameProvider);
          ref.invalidate(profilePicProvider);
          ref.invalidate(authStateProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildUserSection(authUser, profilePicAsync, displayNameAsync),
            const SizedBox(height: 20),
            _buildWeatherSection(weatherAsync),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Latest News', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 8),
            _buildPostsSection(postsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(dynamic authUser, AsyncValue<String?> profilePicAsync, AsyncValue<String?> displayNameAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          profilePicAsync.when(
            data: (base64String) => CircleAvatar(
              radius: 30,
              backgroundImage: base64String != null 
                  ? MemoryImage(base64Decode(base64String)) 
                  : null,
              child: base64String == null 
                  ? const Icon(Icons.person, size: 30) 
                  : null,
            ),
            loading: () => const CircleAvatar(radius: 30, child: CircularProgressIndicator()),
            error: (_, __) => const CircleAvatar(radius: 30, child: Icon(Icons.error)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                displayNameAsync.when(
                  data: (name) {
                    final hasName = name != null && name.isNotEmpty;
                    return Text(
                      hasName ? name : 'open drawer to edit your name and profile update', 
                      style: TextStyle(
                        fontSize: hasName ? 18 : 14, 
                        fontWeight: hasName ? FontWeight.bold : FontWeight.normal,
                        fontStyle: hasName ? FontStyle.normal : FontStyle.italic,
                        color: hasName ? null : Colors.blueGrey,
                      )
                    );
                  },
                  loading: () => const Text('Loading...', style: TextStyle(fontSize: 18)),
                  error: (_, __) => const Text('SmartHub User', style: TextStyle(fontSize: 18)),
                ),
                Text(
                  authUser?.email ?? 'Not logged in',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection(AsyncValue weatherAsync) {
    return weatherAsync.when(
      data: (weather) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(weather.cityName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                const Icon(Icons.cloud, color: Colors.white),
              ],
            ),
            const SizedBox(height: 10),
            Text('${weather.temp.toStringAsFixed(1)}°C', 
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
            Text(weather.description.toUpperCase(), 
              style: const TextStyle(color: Colors.white70, letterSpacing: 1.2, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Text('Weather data unavailable'),
    );
  }

  Widget _buildPostsSection(AsyncValue postsAsync) {
    return postsAsync.when(
      data: (posts) {
        final List<Widget> postWidgets = posts.take(5).map<Widget>((post) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article_outlined, color: Colors.orange),
            ),
            title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis, 
              style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        )).toList();

        return Column(
          children: postWidgets,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading news: $err'),
    );
  }
}
