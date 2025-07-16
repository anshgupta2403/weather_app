// weather_provider.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/models/app_weather.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:weather_app/storage/shared_storage.dart';
import 'package:weather/weather.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherService _weatherService;
  final SharedStorage _storage;
  List<String> _cities = [];
  final Map<String, AppWeather> _weatherData = {};
  final Map<String, bool> _isFetching = {};

  WeatherProvider(this._weatherService, this._storage) {
    _init();
  }

  List<String> get cities => _cities;
  AppWeather? getWeather(String city) => _weatherData[city];
  bool isFetching(String city) => _isFetching[city] == true;

  void _init() {
    _cities = _storage.getCities();
  }

  Future<void> addCity(String city) async {
    if (_cities.contains(city)) return;
    _cities.add(city);
    await _storage.saveCities(_cities);
    notifyListeners();
  }

  void removeCity(String city) async {
    _cities.remove(city);
    await _storage.saveCities(_cities);
    notifyListeners();
  }

  Future<void> loadCitiesFromStorage() async {
    _cities = _storage.getCities();
    notifyListeners();
  }

  Future<void> fetchWeatherForCity(String city) async {
    if (isFetching(city)) return;
    _isFetching[city] = true;
    try {
      // Fetch current weather and forecast from service
      Weather current = await _weatherService.fetchCurrentWeather(city);
      List<Weather> forecastData = await _weatherService.fetchFiveDayForecast(
        city,
      );
      String timezone = await _weatherService.getTimeZoneFromGeoapify(
        current.latitude!,
        current.longitude!,
      );
      int? AQI = await _weatherService.fetchAQI(
        current.latitude!,
        current.longitude!,
      );

      Map<String, List<Weather>> groupedByDay = {};

      for (var w in forecastData) {
        final date = DateFormat('yyyy-MM-dd').format(w.date!);
        groupedByDay.putIfAbsent(date, () => []).add(w);
      }

      List<Forecast> dailySummaries = [];

      groupedByDay.forEach((date, items) {
        int minTemp = (items.map((w) => w.tempMin?.celsius ?? 0).reduce(min))
            .round();
        int maxTemp = (items.map((w) => w.tempMax?.celsius ?? 0).reduce(max))
            .round();
        String description = items.first.weatherDescription ?? '';
        String icon = items.first.weatherIcon ?? '';
        DateTime date = items.first.date!;

        dailySummaries.add(
          Forecast(
            day: getDayLabel(date),
            minTemp: minTemp,
            maxTemp: maxTemp,
            description: description,
            icon: icon,
          ),
        );
      });

      // Build AppWeather model
      final appWeather = AppWeather(
        cityName: current.areaName ?? city,
        country: current.country ?? '',
        description: current.weatherDescription ?? '',
        temperature: (current.temperature?.celsius ?? 0.0).round(),
        minTemp: (current.tempMin?.celsius ?? 0.0).round(),
        maxTemp: (current.tempMax?.celsius ?? 0.0).round(),
        icon: current.weatherIcon ?? '01d',
        humidity: current.humidity ?? 0.0,
        wind: current.windSpeed ?? 0.0,
        latitude: current.latitude ?? 0.0,
        longitude: current.longitude ?? 0.0,
        timeZone: timezone,
        aqi: AQI!,
        forecast: dailySummaries,
      );

      _weatherData[city] = appWeather;
      await _storage.saveWeather(city, appWeather);
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isFetching[city] = false;
    }
  }

  String getDayLabel(DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(Duration(days: 1));

    // Only compare the date parts (ignore time)
    bool isSameDate(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    if (isSameDate(date, today)) {
      return 'Today';
    } else if (isSameDate(date, tomorrow)) {
      return 'Tomorrow';
    } else {
      return DateFormat.EEEE().format(date); // e.g., "Monday"
    }
  }

  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    final data = await _weatherService.searchCities(query);
    return data
        .map<Map<String, dynamic>>(
          (e) => {
            'name': e['name'],
            'state': e['state'],
            'country': e['country'],
            'lat': e['lat'],
            'lon': e['lon'],
          },
        )
        .toList();
  }
}
