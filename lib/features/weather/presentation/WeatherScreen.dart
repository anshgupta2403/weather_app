// 📄 weather_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:weather_app/features/weather/presentation/AddCityScreen.dart';
import 'package:weather_app/models/app_weather.dart';
import 'package:weather_app/navigation/weather_navigation_helper.dart';
import 'package:weather_app/providers/geolocator_provider.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/utils/country_utils.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final PageController _controller = PageController(viewportFraction: 0.95);
  String? myCity = '';
  String? myCountry = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onPageChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WeatherProvider>(context, listen: false);
      Provider.of<WeatherProvider>(
        context,
        listen: false,
      ).loadCitiesFromStorage().then((_) {
        final selectedCity = WeatherNavigationHelper.consumeCityToJump();
        final selectedCountry = WeatherNavigationHelper.consumeCountryToJump();
        if (selectedCity != null && selectedCountry != null) {
          final index = provider.cities.indexOf(selectedCity);
          if (index != -1) {
            _controller.jumpToPage(index);
            setState(() {
              myCity = selectedCity;
              myCountry = selectedCountry;
            });
          }
        }
      });
    });
  }

  void _onPageChanged() {
    final int page = _controller.page?.round() ?? 0;
    final provider = Provider.of<WeatherProvider>(context, listen: false);
    final city = provider.cities[page];
    final weather = provider.getWeather(city);

    if (weather != null && (myCity != city || myCountry != weather.country)) {
      setState(() {
        myCity = city;
        myCountry = weather.country;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final geolocatorProvider = Provider.of<GeolocatorProvider>(context);
    final weatherProvider = Provider.of<WeatherProvider>(
      context,
      listen: false,
    );

    if (!_isInitialized && geolocatorProvider.isInitialized) {
      final city = geolocatorProvider.city;
      final country = geolocatorProvider.country;

      if (city.isNotEmpty) {
        // Add detected city if not already present
        if (!weatherProvider.cities.contains(city)) {
          weatherProvider.addCity(city);
          weatherProvider.fetchWeatherForCity(city);
        }

        setState(() {
          myCity = city;
          myCountry = country;
        });
      }

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      locationWidget(context, size),
                      IconButton(
                        onPressed: () async {
                          final provider = Provider.of<WeatherProvider>(
                            context,
                            listen: false,
                          );

                          final selectedCity = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddCityScreen(
                                onCitySelected: (city) {
                                  Navigator.pop(
                                    context,
                                    city,
                                  ); // Return the city to WeatherScreen
                                },
                              ),
                            ),
                          );

                          if (selectedCity != null) {
                            if (!provider.cities.contains(selectedCity)) {
                              await provider.addCity(selectedCity);
                              await provider.fetchWeatherForCity(selectedCity);
                            }

                            final index = provider.cities.indexOf(selectedCity);
                            if (index != -1) {
                              _controller.jumpToPage(
                                index,
                              ); // Jump to newly added city's page

                              final weather = provider.getWeather(selectedCity);
                              if (weather != null) {
                                setState(() {
                                  myCity = selectedCity;
                                  myCountry = weather.country;
                                });
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.add),
                        iconSize: size.width * 0.08,
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.15),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: provider.cities.length,
                      itemBuilder: (context, index) {
                        String city = provider.cities[index];
                        AppWeather? weatherData = provider.getWeather(city);

                        if (weatherData == null && !provider.isFetching(city)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            provider.fetchWeatherForCity(city).catchError((e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error in fetching the city'),
                                ),
                              );
                            });
                          });
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Updating data...')),
                            );
                            try {
                              await provider.fetchWeatherForCity(city);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Data updated successfully'),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update failed: $e')),
                              );
                            }
                          },
                          child: weatherData == null
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : weatherCard(
                                  context,
                                  {
                                    'City': weatherData.cityName,
                                    'Weather': weatherData.description,
                                    'Temperature':
                                        '${weatherData.temperature}°C',
                                    'Humidity': '${weatherData.humidity}%',
                                    'Wind': '${weatherData.wind} m/s',
                                    'Icon': weatherData.icon,
                                    'TimeZone': weatherData.timeZone,
                                    'AQI': weatherData.aqi,
                                    // extend with more if needed
                                  },
                                  weatherData.forecast,
                                  index,
                                  size,
                                ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  provider.cities.isEmpty
                      ? SizedBox.shrink()
                      : SmoothPageIndicator(
                          controller: _controller,
                          count: provider.cities.length,
                          effect: ExpandingDotsEffect(
                            activeDotColor: Colors.white,
                            dotColor: Colors.white38,
                            dotHeight: size.width * 0.025,
                            dotWidth: size.width * 0.025,
                            spacing: size.width * 0.015,
                            expansionFactor: 3,
                          ),
                        ),
                  SizedBox(height: size.height * 0.015),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Data provided by ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.width * 0.04,
                          ),
                        ),
                        TextSpan(
                          text: 'Open Weather',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: size.width * 0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget weatherCard(
    BuildContext context,
    Map<String, dynamic> data,
    List<Forecast> forecast,
    int index,
    Size size,
  ) {
    final iconSize = size.width * 0.12;
    final fontSize = size.width * 0.2;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double value = 1.0;
        if (_controller.position.haveDimensions) {
          value = _controller.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return Transform.scale(scale: value, child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, ${getGreeting(data["TimeZone"])}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: size.height * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Temperature Text
              Flexible(
                flex: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: data['Temperature']?.replaceAll('°C', ''),
                          style: TextStyle(fontSize: fontSize),
                        ),
                        TextSpan(
                          text: '°C',
                          style: TextStyle(fontSize: fontSize),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Weather Icon + Description + AQI
              Flexible(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize
                          .min, // Important to avoid stretching unnecessarily
                      children: [
                        Image.network(
                          'https://openweathermap.org/img/wn/${data["Icon"]}@2x.png',
                          width: iconSize,
                          height: iconSize,
                        ),
                        const SizedBox(width: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            data['Weather'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'AQI ${getAqiDescription(data['AQI'])}',
                          style: TextStyle(
                            fontSize: 16,
                            color: getAqiColor(data['AQI']),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.02),
          Row(
            children: [
              iconTextWithContainer(
                context,
                Icons.air,
                data['Wind'] ?? '',
                size,
              ),
              SizedBox(width: size.width * 0.05),
              iconTextWithContainer(
                context,
                Icons.water_drop,
                data['Humidity'] ?? '',
                size,
              ),
            ],
          ),
          SizedBox(height: size.height * 0.03),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.black26, Colors.black38],
                ),
              ),
              width: double.infinity,
              child: ListView.builder(
                itemCount: forecast.length > 5
                    ? forecast.length - 1
                    : forecast.length,
                itemBuilder: (context, i) {
                  final f = forecast[i];
                  return myListTile(context, f.toJson(), size);
                },
              ),
            ),
          ),
          SizedBox(height: size.height * 0.02),
        ],
      ),
    );
  }

  Widget iconTextWithContainer(
    BuildContext context,
    IconData icon,
    String text,
    Size size,
  ) {
    final iconSize = size.width * 0.05;
    final fontSize = size.width * 0.035;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.black12, Colors.black26],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      height: size.height * 0.05,
      width: size.width * 0.25,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: iconSize),
          SizedBox(width: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(fontSize: fontSize, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget myListTile(
    BuildContext context,
    Map<String, dynamic> data,
    Size size,
  ) {
    final fontSize = size.width * 0.035;
    final iconSize = size.width * 0.09;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        leading: Image.network(
          'https://openweathermap.org/img/wn/${data["icon"]}@2x.png',
          width: iconSize,
          height: iconSize,
        ),
        title: Wrap(
          runSpacing: 2,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data['day'] ?? '',
                style: TextStyle(fontSize: fontSize, color: Colors.white),
              ),
            ),
            SizedBox(width: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data['description'] ?? '',
                style: TextStyle(fontSize: fontSize, color: Colors.white70),
              ),
            ),
          ],
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "${data['maxTemp']}° / ${data['minTemp']}°",
            style: TextStyle(fontSize: fontSize, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget locationWidget(BuildContext context, Size size) {
    final locationFontSize = size.width * 0.04;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.black12, Colors.black26],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.01,
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_pin,
            size: locationFontSize + 2,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$myCity,',
              style: TextStyle(fontSize: locationFontSize, color: Colors.white),
            ),
          ),
          SizedBox(width: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              getCountryName(myCountry ?? ''),
              style: TextStyle(fontSize: locationFontSize, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String getGreeting(String timeZone) {
    final location = tz.getLocation(timeZone);

    final now = tz.TZDateTime.now(location);
    final hour = now.hour;

    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String getAqiDescription(int aqi) {
    switch (aqi) {
      case 1:
        return 'Good';
      case 2:
        return 'Fair';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Very Poor';
      default:
        return 'Unknown';
    }
  }

  Color getAqiColor(int aqi) {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
