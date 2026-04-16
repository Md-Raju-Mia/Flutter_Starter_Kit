import '../../data/models/user_model.dart';
import '../../data/models/weather_model.dart';
import '../../data/models/post_model.dart';

abstract class DashboardRepository {
  Future<UserModel> getUserProfile(int userId);
  Future<WeatherModel> getWeather(String city);
  Future<List<PostModel>> getPosts();
}
