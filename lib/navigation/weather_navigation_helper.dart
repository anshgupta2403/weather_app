class WeatherNavigationHelper {
  static String? cityToJump;
  static String? countryToJump;

  static void setCityToJump(String city) {
    cityToJump = city;
  }

  static void setCountryToJump(String country) {
    countryToJump = country;
  }

  static String? consumeCityToJump() {
    final city = cityToJump;
    cityToJump = null; // clear after consuming
    return city;
  }

  static String? consumeCountryToJump() {
    final country = countryToJump;
    countryToJump = null;
    return country;
  }
}
