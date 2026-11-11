import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherInfo {
  final double tempMax;
  final double tempMin;
  final String description;
  final String icon;

  const WeatherInfo({
    required this.tempMax,
    required this.tempMin,
    required this.description,
    required this.icon,
  });
}

class WeatherService {
  WeatherService._();

  // Cache em memória para não fazer chamadas repetidas
  static final Map<String, WeatherInfo> _cache = {};

  static Future<WeatherInfo?> getWeatherForDate(DateTime date) async {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=38.7223&longitude=-9.1393&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=Europe%2FLisbon',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final daily = data['daily'];
        final dates = List<String>.from(daily['time']);
        final idx = dates.indexOf(key);

        if (idx != -1) {
          final code = (daily['weathercode'][idx] as num).toInt();
          final max = (daily['temperature_2m_max'][idx] as num).toDouble();
          final min = (daily['temperature_2m_min'][idx] as num).toDouble();

          final info = _parseWeatherCode(code, max, min);
          _cache[key] = info;
          return info;
        }
      }
    } catch (_) {
      // Caso sem internet ou timeout
    }
    return null;
  }

  static WeatherInfo _parseWeatherCode(int code, double max, double min) {
    if (code == 0) {
      return WeatherInfo(tempMax: max, tempMin: min, description: 'Céu Limpo', icon: '☀️');
    } else if (code <= 3) {
      return WeatherInfo(tempMax: max, tempMin: min, description: 'Parcialmente Nublado', icon: '⛅');
    } else if (code == 45 || code == 48) {
      return WeatherInfo(tempMax: max, tempMin: min, description: 'Nevoeiro', icon: '🌫️');
    } else if (code >= 51 && code <= 67) {
      return WeatherInfo(tempMax: max, tempMin: min, description: 'Chuva Fraca / Moderada', icon: '🌧️');
    } else if (code >= 80 && code <= 82) {
      return WeatherInfo(tempMax: max, tempMin: min, description: 'Aguaceiros', icon: '🌦️');
    } else if (code >= 95) {
      return WeatherInfo(tempMax: max, tempMin: min, description: 'Trovoada', icon: '⛈️');
    }
    return WeatherInfo(tempMax: max, tempMin: min, description: 'Céu Aberto', icon: '🌤️');
  }
}
