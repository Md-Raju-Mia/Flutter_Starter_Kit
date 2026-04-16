class WeatherModel {
  final String main;
  final String description;
  final double temp;
  final String cityName;

  WeatherModel({
    required this.main,
    required this.description,
    required this.temp,
    required this.cityName,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      main: json['weather'][0]['main'],
      description: json['weather'][0]['description'],
      // Removing the -273.15 because we are using 'units=metric' in the API call
      temp: (json['main']['temp'] as num).toDouble(),
      cityName: json['name'],
    );
  }
}
