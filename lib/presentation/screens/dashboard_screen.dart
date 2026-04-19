import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state_management/dashboard_provider.dart';
import '../state_management/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import 'main_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final weatherAsync = ref.watch(weatherProvider('London'));
    final postsAsync = ref.watch(postsProvider);
    final profilePicAsync = ref.watch(profilePicProvider);
    final displayNameAsync = ref.watch(displayNameProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(weatherProvider);
          ref.invalidate(postsProvider);
          ref.invalidate(displayNameProvider);
          ref.invalidate(profilePicProvider);
          ref.invalidate(authStateProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.medium(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: theme.colorScheme.surface,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_rounded),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              title: Text(
                'SmartHub',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      theme.brightness == Brightness.light 
                          ? Icons.dark_mode_rounded 
                          : Icons.light_mode_rounded,
                    ),
                  ),
                  onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildUserSection(context, authUser, profilePicAsync, displayNameAsync),
                  const SizedBox(height: 24),
                  Text(
                    'Weather Update',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildWeatherSection(context, weatherAsync),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Latest Insights',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
            ),
            _buildSliverPostsSection(context, postsAsync),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context, dynamic authUser, AsyncValue<String?> profilePicAsync, AsyncValue<String?> displayNameAsync) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            theme.colorScheme.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          profilePicAsync.when(
            data: (base64String) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.surface,
                backgroundImage: base64String != null 
                    ? MemoryImage(base64Decode(base64String)) 
                    : null,
                child: base64String == null 
                    ? Icon(Icons.person_rounded, size: 36, color: theme.colorScheme.primary) 
                    : null,
              ),
            ),
            loading: () => const CircleAvatar(radius: 32, child: CircularProgressIndicator()),
            error: (_, __) => const CircleAvatar(radius: 32, child: Icon(Icons.error)),
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
                      hasName ? 'Hello, $name!' : 'Welcome to SmartHub', 
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      )
                    );
                  },
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('Hello User'),
                ),
                const SizedBox(height: 4),
                displayNameAsync.when(
                  data: (name) => Text(
                    (name == null || name.isEmpty) 
                        ? 'Tap drawer to update profile' 
                        : (authUser?.email ?? ''),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.settings_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection(BuildContext context, AsyncValue weatherAsync) {
    final theme = Theme.of(context);
    return weatherAsync.when(
      data: (weather) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(weather.cityName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${weather.temp.round()}°', 
                  style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold, letterSpacing: -2)),
                Text(weather.description.toUpperCase(), 
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1.5, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            Column(
              children: [
                Icon(_getWeatherIcon(weather.description), color: Colors.white, size: 80),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Cloudy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => Container(
        height: 160,
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(28)),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => const Text('Weather data unavailable'),
    );
  }

  IconData _getWeatherIcon(String description) {
    description = description.toLowerCase();
    if (description.contains('cloud')) return Icons.cloud_rounded;
    if (description.contains('rain')) return Icons.umbrella_rounded;
    if (description.contains('sun') || description.contains('clear')) return Icons.wb_sunny_rounded;
    return Icons.wb_cloudy_rounded;
  }

  Widget _buildSliverPostsSection(BuildContext context, AsyncValue postsAsync) {
    final theme = Theme.of(context);
    return postsAsync.when(
      data: (posts) {
        final filteredPosts = posts.take(5).toList();
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = filteredPosts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.article_rounded, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.title, 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis, 
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    post.body, 
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: filteredPosts.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ))),
      error: (err, stack) => SliverToBoxAdapter(child: Text('Error loading news: $err')),
    );
  }
}
