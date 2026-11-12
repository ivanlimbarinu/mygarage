import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherAdvice {
  final String title, message;
  const WeatherAdvice(this.title, this.message);
}

class WeatherService {
  static Future<WeatherAdvice> fetchAdvice({
    double latitude = 45.0703,
    double longitude = 7.6869,
  }) async {
    final response = await http
        .get(
          Uri.https('api.open-meteo.com', '/v1/forecast', {
            'latitude': '$latitude',
            'longitude': '$longitude',
            'current': 'temperature_2m,weather_code,wind_speed_10m',
            'timezone': 'auto',
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw Exception('Meteo non disponibile');
    final current =
        (jsonDecode(response.body) as Map<String, dynamic>)['current']
            as Map<String, dynamic>;
    return adviceFor(
      (current['temperature_2m'] as num).toDouble(),
      (current['weather_code'] as num).toInt(),
      (current['wind_speed_10m'] as num).toDouble(),
    );
  }

  static WeatherAdvice adviceFor(double temperature, int code, double wind) {
    if ({71, 73, 75, 77, 85, 86}.contains(code) || temperature <= 3) {
      return WeatherAdvice(
        'Freddo e possibile ghiaccio · ${temperature.round()}°',
        'Valuta pneumatici adatti al freddo e alle condizioni previste. Riduci la velocità e aumenta la distanza.',
      );
    }
    if (code >= 95 || wind >= 50) {
      return const WeatherAdvice(
        'Attenzione in strada',
        'Temporali o vento forte: guida con prudenza e valuta di rimandare il viaggio.',
      );
    }
    if ({45, 48}.contains(code)) {
      return const WeatherAdvice(
        'Visibilità ridotta',
        'Possibile nebbia: rallenta e aumenta la distanza di sicurezza.',
      );
    }
    if (code >= 51) {
      return const WeatherAdvice(
        'Pioggia: controlla le gomme',
        'Verifica battistrada e pressione. Riduci la velocità sul bagnato.',
      );
    }
    if (temperature < 7) {
      return WeatherAdvice(
        'È tempo di controllare le gomme · ${temperature.round()}°',
        'Con il freddo valuta con un gommista pneumatici adatti alla stagione e al tuo percorso.',
      );
    }
    return WeatherAdvice(
      'Buon viaggio · ${temperature.round()}°',
      'Condizioni favorevoli. Controlla comunque pressione e usura delle gomme prima di partire.',
    );
  }
}
