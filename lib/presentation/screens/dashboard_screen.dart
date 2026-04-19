import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state_management/dashboard_provider.dart';
import '../../core/providers/theme_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(1)); // Dummy user ID 1
    final weatherAsync = ref.watch(weatherProvider('London')); // Default city
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: const Text('SmartHub Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(weatherProvider);
          ref.invalidate(postsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildUserSection(userAsync),
            const SizedBox(height: 20),
            _buildWeatherSection(weatherAsync),
            const SizedBox(height: 20),
            const Text('Latest Posts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildPostsSection(postsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(AsyncValue userAsync) {
    return userAsync.when(
      data: (user) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(user.name),
          subtitle: Text(user.email),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading user: $err'),
    );
  }

  Widget _buildWeatherSection(AsyncValue weatherAsync) {
    return weatherAsync.when(
      data: (weather) => Card(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(weather.cityName, style: const TextStyle(fontSize: 18)),
              Text('${weather.temp.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Text(weather.description),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Text('Weather API Key missing or error'),
    );
  }

  Widget _buildPostsSection(AsyncValue postsAsync) {
    return postsAsync.when(
      data: (posts) => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: posts.length > 5 ? 5 : posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Card(
            child: ListTile(
              title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error loading posts: $err'),
    );
  }
}
