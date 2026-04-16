import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../models/weather_model.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DioClient _dioClient;

  DashboardRepositoryImpl(this._dioClient);

  @override
  Future<UserModel> getUserProfile(int userId) async {
    final response = await _dioClient.get('${ApiConstants.users}/$userId');
    return UserModel.fromJson(response.data);
  }

  @override
  Future<WeatherModel> getWeather(String city) async {
    // Note: Weather API usually needs a different base URL and API Key
    // This is a simplified example. In production, you'd use ApiConstants.weatherBaseUrl
    final response = await _dioClient.get(
      '${ApiConstants.weatherBaseUrl}${ApiConstants.weather}',
      queryParameters: {
        'q': city,
        'appid': ApiConstants.weatherApiKey,
        'units': 'metric',
      },
    );
    return WeatherModel.fromJson(response.data);
  }

  @override
  Future<List<PostModel>> getPosts() async {
    final response = await _dioClient.get(ApiConstants.posts);
    return (response.data as List)
        .map((post) => PostModel.fromJson(post))
        .toList();
  }
}
