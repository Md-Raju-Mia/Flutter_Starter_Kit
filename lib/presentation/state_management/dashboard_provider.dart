import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/weather_model.dart';
import '../../data/providers/repository_providers.dart';

final userProfileProvider = FutureProvider.family<UserModel, int>((ref, userId) async {
  return ref.watch(dashboardRepositoryProvider).getUserProfile(userId);
});

final weatherProvider = FutureProvider.family<WeatherModel, String>((ref, city) async {
  return ref.watch(dashboardRepositoryProvider).getWeather(city);
});

final postsProvider = FutureProvider<List<PostModel>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getPosts();
});
