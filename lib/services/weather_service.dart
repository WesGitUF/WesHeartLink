import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final String condition;
  final int temperatureF;
  WeatherData({required this.condition, required this.temperatureF});
}

class WeatherService {
  static const String _apiKey = '9b0d493df5dd8e9152befd434d949b42'; 

  // Fetch current weather based on location
  Future<WeatherData?> fetchCurrent() async {
    // request location permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      // if the user denies permission again
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    // Get current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    // OpenWeatherMap API call
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=${position.latitude}&lon=${position.longitude}&units=imperial&appid=$_apiKey',
    );

    // Make the HTTP GET request
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Parse the JSON response
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // weather condition
      final weatherList = data['weather'] as List<dynamic>;
      final condition = weatherList.first['main'] as String? ?? 'Unknown';

      // weather temperature 
      final temperatureF = (data['main']['temp'] as num?)?.round() ?? 0;

      // Return WeatherData object
      return WeatherData(condition: condition, temperatureF: temperatureF);
    } else {
      return null;
    }
  }
}