// weather_service.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:weather/weather.dart';
import 'dart:convert';

class WeatherService {
  late final WeatherFactory _wf;
  late final geoapifyApiKey;
  late final weatherApiKey;
  WeatherService() {
    weatherApiKey = dotenv.env['WEATHER_API_KEY'] ?? '';
    geoapifyApiKey = dotenv.env['GEOAPIFY_API_KEY'] ?? '';
    _wf = WeatherFactory(weatherApiKey, language: Language.ENGLISH);
  }

  Future<Weather> fetchCurrentWeather(String city) async {
    try {
      return await _wf.currentWeatherByCityName(city);
    } catch (e) {
      print(e);
      throw Exception('Error fetching current weather: $e');
    }
  }

  Future<List<Weather>> fetchFiveDayForecast(String city) async {
    try {
      return await _wf.fiveDayForecastByCityName(city);
    } catch (e) {
      throw Exception('Error fetching 5-day forecast: $e');
    }
  }

  Future<String> getTimeZoneFromGeoapify(
    double latitude,
    double longitude,
  ) async {
    final url = Uri.parse(
      'https://api.geoapify.com/v1/geocode/reverse?lat=$latitude&lon=$longitude&apiKey=$geoapifyApiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final timezone = data['features'][0]['properties']['timezone']['name'];
        return timezone;
      } else {
        return 'Unknown';
      }
    } else {
      print('Error fetching timezone: ${response.statusCode}');
      return 'Unknown';
    }
  }

  Future<int?> fetchAQI(double lat, double lon) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$weatherApiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['list'][0]['main']['aqi'];
    } else {
      print('Failed to fetch AQI: ${response.statusCode}');
      return null;
    }
  }

  Future<List<dynamic>> searchCities(String query) async {
    final url = Uri.parse(
      'https://api.openweathermap.org/geo/1.0/direct?q=$query&limit=50&appid=$weatherApiKey',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) throw Exception('Failed to fetch cities');

    final data = jsonDecode(res.body);
    return data;
  }
}
