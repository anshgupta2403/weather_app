// app_weather.dart
class Forecast {
  final String day;
  final int minTemp;
  final int maxTemp;
  final String description;
  final String icon;

  Forecast({
    required this.day,
    required this.minTemp,
    required this.maxTemp,
    required this.description,
    required this.icon,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      day: json['day'],
      minTemp: json['minTemp'],
      maxTemp: json['maxTemp'],
      description: json['description'],
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'description': description,
      'icon': icon,
    };
  }
}

class AppWeather {
  final String cityName;
  final String country;
  final String description;
  final int temperature;
  final int minTemp;
  final int maxTemp;
  final double humidity;
  final double wind;
  final String icon;
  final List<Forecast> forecast;
  final double latitude;
  final double longitude;
  final String timeZone;
  final int aqi;

  AppWeather({
    required this.cityName,
    required this.country,
    required this.description,
    required this.temperature,
    required this.minTemp,
    required this.maxTemp,
    required this.icon,
    required this.forecast,
    required this.humidity,
    required this.wind,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    required this.aqi,
  });

  factory AppWeather.fromJson(Map<String, dynamic> json) {
    return AppWeather(
      cityName: json['cityName'],
      country: json['country'],
      description: json['description'],
      temperature: json['temperature'],
      minTemp: json['minTemp'],
      maxTemp: json['maxTemp'],
      icon: json['icon'],
      humidity: json['humidity'],
      wind: json['wind'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timeZone: json['timezone'],
      aqi: json['aqi'],
      forecast: (json['forecast'] as List<dynamic>)
          .map((f) => Forecast.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'country': country,
      'description': description,
      'temperature': temperature,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'icon': icon,
      'humidity': humidity,
      'wind': wind,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timeZone,
      'aqi': aqi,
      'forecast': forecast.map((f) => f.toJson()).toList(),
    };
  }
}
