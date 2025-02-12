import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'weather_detail.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String latitude = '';
  String longitude = '';
  String city = '';
  String pincode = '';
  String state = '';
  double? currentTemperature;
  double? maxTemperature;
  double? minTemperature;
  bool isLoading = true;

  Map<String, Map<String, double>>? forecastTemperatures;
  List<Map<String, String>> forecastDays = [];
  String? selectedDay;

  @override
  void initState() {
    super.initState();
    _setForecastDays();
    _monitorLocation();
  }


  void _setForecastDays() {
    DateTime today = DateTime.now();
    forecastDays = List.generate(5, (index) {
      DateTime day = today.add(Duration(days: index + 1));
      return {
        'day': getDayOfWeek(day),
        'date': '${day.day} ${day.month} ${day.year}',
      };
    });
  }


  Future<void> fetchWeatherData(double lat, double lon) async {
    final String url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=2ea0414e324fb5b932730cca8f11fce0&units=metric';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        setState(() {
          currentTemperature = data['list'][0]['main']['temp'];
          maxTemperature = data['list'][0]['main']['temp_max'];
          minTemperature = data['list'][0]['main']['temp_min'];
        });

        Map<String, Map<String, double>> parsedForecast = {};
        for (var forecast in data['list']) {
          DateTime dateTime = DateTime.parse(forecast['dt_txt']);
          String dayOfWeek = getDayOfWeek(dateTime);

          if (forecastDays.any((day) => day['day'] == dayOfWeek)) {
            if (!parsedForecast.containsKey(dayOfWeek)) {
              parsedForecast[dayOfWeek] = {
                'max': forecast['main']['temp_max'],
                'min': forecast['main']['temp_min'],
              };
            }
          }
        }

        setState(() {
          forecastTemperatures = parsedForecast;
          isLoading = false;
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching weather data: $error');
    }
  }


  void _monitorLocation() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) async {
      setState(() {
        latitude = position.latitude.toString();
        longitude = position.longitude.toString();
      });

      await fetchWeatherData(position.latitude, position.longitude);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          city = place.locality ?? 'Unknown City';
          pincode = place.postalCode ?? 'Unknown Pincode';
          state = place.administrativeArea ?? 'Unknown State';
        });
      }
    });
  }
  String getDayOfWeek(DateTime dateTime) {
    switch (dateTime.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }


  void _resetToToday() {
    setState(() {
      selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(40),
        child: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: selectedDay != null
              ? IconButton(
            icon: const Icon(Icons.arrow_circle_left_outlined,
                color: Colors.white, size: 25),
            onPressed: _resetToToday,
          )
              : null,
          title: const Text(
            'Weather Forecast',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/weather_background_image.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selectedDay != null && forecastTemperatures != null)
                // Display selected day details
                  Column(
                    children: [
                      Text(
                        '$selectedDay',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Max: ${forecastTemperatures?[selectedDay]?['max']?.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Min: ${forecastTemperatures?[selectedDay]?['min']?.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                if (selectedDay == null)
                // Display current day weather
                  Column(
                    children: [
                      Text(
                        '${getDayOfWeek(DateTime.now()).toUpperCase()} ${DateTime.now().day} ${DateTime.now().month} ${DateTime.now().year}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Latitude: $latitude',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.yellowAccent,
                        ),
                      ),
                      Text(
                        'Longitude: $longitude',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.yellowAccent,
                        ),
                      ),
                      Text(
                        city.isNotEmpty ? 'City: $city' : 'Fetching city...',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.yellowAccent,
                        ),
                      ),
                      Text(
                        pincode.isNotEmpty ? 'Pincode: $pincode' : 'Fetching pincode...',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.yellowAccent,
                        ),
                      ),
                      Text(
                        state.isNotEmpty ? 'State: $state' : 'Fetching state...',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.yellowAccent,
                        ),
                      ),
                      const Icon(
                        Icons.cloudy_snowing,
                        size: 100,
                        color: Colors.lightBlueAccent,
                      ),
                      const SizedBox(height: 5),
                      isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                        currentTemperature != null
                            ? '${currentTemperature!.toStringAsFixed(1)}°'
                            : 'N/A',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                        ),
                      ),
                      isLoading
                          ? const SizedBox()
                          : Text(
                        maxTemperature != null && minTemperature != null
                            ? 'Max: ${maxTemperature!.toStringAsFixed(1)}°  Min: ${minTemperature!.toStringAsFixed(1)}°'
                            : 'Fetching temperatures...',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                const Divider(
                  thickness: 3,
                  color: Colors.white,
                ),
                const Text(
                  ' NEXT 5-DAYS FORECAST',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent,
                  ),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: forecastDays.map((day) {
                      String temperatureDisplay = 'Max: ${forecastTemperatures?[day['day']]?['max']?.toStringAsFixed(1)}°\n'
                          'Min: ${forecastTemperatures?[day['day']]?['min']?.toStringAsFixed(1)}°';

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDay = day['day'];
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.yellowAccent),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: WeatherDetail(
                            '${day['day']} ${day['date']}',
                            Icons.cloudy_snowing,
                            temperatureDisplay,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
