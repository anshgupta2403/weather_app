import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:weather_app/features/weather/presentation/WeatherScreen.dart';
import 'package:weather_app/providers/geolocator_provider.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/services/geolocator_service.dart';
import 'package:weather_app/services/weather_service.dart';
import 'package:weather_app/storage/shared_storage.dart';
import 'package:weather_app/themes/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize shared preferences and weather service
  final storage = await SharedStorage.init();
  final weatherService = WeatherService();
  final geolocatorService = GeolocatorService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(weatherService, storage),
        ),
        ChangeNotifierProvider(
          create: (_) => GeolocatorProvider(geolocatorService, storage),
        ),
      ],
      child: const WeatherApp(),
    ),
  );
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Weather App',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const WeatherScreen(),
    );
  }
}
