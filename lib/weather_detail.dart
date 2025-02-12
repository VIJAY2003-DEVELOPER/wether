import 'package:flutter/material.dart';
class WeatherDetail extends StatelessWidget {
  final String time;
  final IconData icon;
  final String temp;

  const WeatherDetail(this.time, this.icon, this.temp, {super.key,  color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(time, style: TextStyle(color: Colors.grey[200])),
        const SizedBox(height: 5),
        Icon(icon, color: Colors.grey[200]),
        const SizedBox(height: 5),
        Text(temp, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }
}
