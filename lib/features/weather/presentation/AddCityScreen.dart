import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/features/weather/presentation/SearchCityScreen.dart';
import 'package:weather_app/models/app_weather.dart';
import 'package:weather_app/navigation/weather_navigation_helper.dart';
import 'package:weather_app/providers/weather_provider.dart';

class AddCityScreen extends StatefulWidget {
  final Function(String) onCitySelected;

  const AddCityScreen({super.key, required this.onCitySelected});

  @override
  State<AddCityScreen> createState() => _AddCityScreenState();
}

class _AddCityScreenState extends State<AddCityScreen> {
  final TextEditingController _textEditController = TextEditingController();
  bool isSelectionMode = false;
  Set<String> selectedCities = {};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (isSelectionMode) {
              setState(() {
                isSelectionMode = false;
                selectedCities.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
          icon: Icon(
            isSelectionMode ? Icons.clear : Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: isSelectionMode
            ? [
                IconButton(
                  icon: Icon(
                    Icons.list,
                    color: selectedCities.isEmpty ? Colors.black : Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      if (selectedCities.isEmpty) {
                        for (var city in provider.cities) {
                          selectedCities.add(city);
                        }
                        selectedCities.remove(selectedCities.first);
                      } else {
                        selectedCities.clear();
                      }
                    });
                  },
                ),
              ]
            : [],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSelectionMode)
                Text(
                  'Manage Cities',
                  style: TextStyle(fontSize: 36, color: Colors.black),
                ),
              if (!isSelectionMode) SizedBox(height: 20),
              if (isSelectionMode)
                Text(
                  selectedCities.isEmpty
                      ? 'Select items'
                      : selectedCities.length == 1
                      ? '1 item selected'
                      : '${selectedCities.length} items selected',
                  style: TextStyle(fontSize: 36, color: Colors.black),
                ),
              if (isSelectionMode) SizedBox(height: 20),
              Container(
                child: TextField(
                  controller: _textEditController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Enter location',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: TextStyle(fontSize: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SearchCityScreen()),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.cities.length,
                  itemBuilder: (context, index) {
                    String city = provider.cities[index];
                    AppWeather? weatherData = provider.getWeather(city);
                    if (weatherData == null) {
                      return SizedBox.shrink(); // or a placeholder
                    }
                    return ListItem(
                      weatherData.toJson(),
                      index,
                      provider.cities.length,
                    );
                  },
                ),
              ),
              if (isSelectionMode)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: selectedCities.isNotEmpty
                            ? () {
                                final provider = Provider.of<WeatherProvider>(
                                  context,
                                  listen: false,
                                );
                                for (String city in selectedCities) {
                                  provider.removeCity(city);
                                }
                                setState(() {
                                  selectedCities.clear();
                                  isSelectionMode = false;
                                });
                              }
                            : null,
                        child: Opacity(
                          opacity: selectedCities.isNotEmpty ? 1.0 : 0.4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outlined,
                                size: 28,
                                color: selectedCities.isNotEmpty
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: selectedCities.isNotEmpty
                                      ? Colors.blue
                                      : Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget ListItem(Map<String, dynamic> data, int index, int totalCities) {
    bool isSelected = selectedCities.contains(data['cityName']);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {
          if (isSelectionMode) {
            if (index != 0) {
              setState(() {
                selectedCities.contains(data['cityName'])
                    ? selectedCities.remove(data['cityName'])
                    : selectedCities.add(data['cityName']);
              });
            }
          } else {
            WeatherNavigationHelper.setCityToJump(data['cityName']);
            WeatherNavigationHelper.setCountryToJump(data['country']);
            widget.onCitySelected(data['cityName']);
          }
        },
        onLongPress: () {
          if (totalCities > 1) {
            setState(() {
              isSelectionMode = true;
            });
          }
          if (index != 0 && !selectedCities.contains(data['cityName'])) {
            selectedCities.add(data['cityName']);
          }
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.green,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // City Info (name + aqi)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data['cityName'], style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      const Icon(Icons.location_pin, size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "AQI ${data["aqi"]}  ${data["minTemp"]}° / ${data["maxTemp"]}°",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),

              // Temperature
              Text("${data["temperature"]}°", style: TextStyle(fontSize: 48)),

              // Selection Circle
              if (isSelectionMode && index != 0)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.white,
                      width: 2,
                    ),
                    color: isSelected ? Colors.blue : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
