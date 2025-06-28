import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/features/weather/presentation/WeatherScreen.dart';
import 'package:weather_app/navigation/weather_navigation_helper.dart';
import 'package:weather_app/providers/geolocator_provider.dart';
import 'package:weather_app/providers/weather_provider.dart';
import 'package:weather_app/utils/popular_cities_utils.dart';

class SearchCityScreen extends StatefulWidget {
  const SearchCityScreen({super.key});

  @override
  State<SearchCityScreen> createState() => _SearchCityScreenState();
}

class _SearchCityScreenState extends State<SearchCityScreen> {
  final TextEditingController _textEditController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _textEditController.addListener(_onTextChanged);
  }

  void _onTextChanged() async {
    final query = _textEditController.text.trim();
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final weatherApiProvider = Provider.of<WeatherProvider>(
        context,
        listen: false,
      );
      final results = await weatherApiProvider.searchCities(query);
      print(results);
      setState(() => _searchResults = results);
    } catch (e) {
      print('City search failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 2.8 / 4,
                    child: TextField(
                      controller: _textEditController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
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
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      cursorColor: Colors.blue,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.all(
                        Colors.blue[400],
                      ),
                    ),
                    child: Text('Cancel', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (_textEditController.text.trim().isEmpty) ...[
                Text('Popular cities', style: TextStyle(color: Colors.black)),
              ] else if (_isLoading) ...[
                Center(
                  child: const Text(
                    'Searching...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ] else if (_searchResults.isEmpty) ...[
                Center(
                  child: const Text(
                    'No results',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ] else
                Expanded(child: _buildSearchList(context)),

              if (_textEditController.text.trim().isEmpty)
                getPopularCitiesGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchList(BuildContext context) {
    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final city = _searchResults[index];
        final name = city['name'] ?? '';
        final country = city['country'] ?? '';
        final state = city['state'] ?? '';
        final isIncluded = isAlreadyIncluded(name);

        return ListTile(
          title: Text(name, style: TextStyle(fontSize: 16)),
          subtitle: Row(children: [Text('$state,'), Text('$country')]),
          onTap: () => _onCityTap(context, name, isIncluded, country),
        );
      },
    );
  }

  Widget getPopularCitiesGrid(BuildContext context) {
    final geolocatorProvider = Provider.of<GeolocatorProvider>(context);
    final cities = PopularCitiesUtil.getCitiesByCountry(
      geolocatorProvider.getUserCountryCode(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Wrap(
        spacing: 20, // space between items horizontally
        runSpacing: 20, // space between rows
        children: cities.map((city) {
          final cityName = city['name']!;
          final isIncluded = isAlreadyIncluded(cityName);
          return InkWell(
            onTap: () => _onCityTap(
              context,
              cityName,
              isIncluded,
              geolocatorProvider.country,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                cityName,
                style: TextStyle(
                  fontSize: 14,
                  color: isIncluded ? Colors.blue : Colors.black,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool isAlreadyIncluded(String city) {
    final weatherProvider = Provider.of<WeatherProvider>(
      context,
      listen: false,
    );
    List<String> cities = weatherProvider.cities;
    return cities.contains(city);
  }

  Future<void> _onCityTap(
    BuildContext context,
    String cityId,
    bool isIncluded,
    String country,
  ) async {
    if (isIncluded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('City "$cityId" is already in your list.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_city,
                  size: 48,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  'Add City?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Do you want to add "$cityId" to your saved cities?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.cancel, color: Colors.grey),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[800],
                        backgroundColor: Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmed == true) {
        final weatherProvider = Provider.of<WeatherProvider>(
          context,
          listen: false,
        );
        await weatherProvider.addCity(cityId);
        WeatherNavigationHelper.setCityToJump(cityId);
        WeatherNavigationHelper.setCountryToJump(country);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const WeatherScreen()),
          (route) => false, // remove all previous routes
        );
      }
    }
  }
}
