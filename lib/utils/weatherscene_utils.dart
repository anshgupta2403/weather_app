import 'package:weather_animation/weather_animation.dart';

WeatherScene getWeatherScene(String? iconCode) {
  switch (iconCode) {
    case '01d': // clear sky day
      return WeatherScene.scorchingSun;
    case '01n': // clear sky night
      return WeatherScene.weatherEvery;
    case '02d':
    case '03d':
    case '04d':
      return WeatherScene.scorchingSun;
    case '02n':
    case '03n':
    case '04n':
      return WeatherScene.sunset;
    case '09d':
    case '10d':
    case '09n':
    case '10n':
      return WeatherScene.showerSleet;
    case '11d':
    case '11n':
      return WeatherScene.stormy;
    case '13d':
    case '13n':
      return WeatherScene.snowfall;
    case '50d':
    case '50n':
      return WeatherScene.frosty;
    default:
      return WeatherScene.scorchingSun;
  }
}
