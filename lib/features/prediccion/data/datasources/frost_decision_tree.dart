import '../../domain/entities/frost_prediction.dart';
import '../../../pronostico/domain/entities/weather_forecast.dart';

class FrostDecisionTree {
  FrostPrediction predict({
    required int altitud,
    required double tempMin,
    required double humedad,
    required double viento,
    required int mes,
    required double nubosidad,
  }) {
    int risk = 0;
    final List<String> factors = [];

    // Factor 1: Altitud
    if (altitud > 3000) {
      risk += 3;
      factors.add('Altitud muy alta (>3.000m) - Fuerte retención de frío');
    } else if (altitud > 2500) {
      risk += 2;
      factors.add('Altitud alta - Mayor exposición a heladas');
    } else if (altitud > 2000) {
      risk += 1;
    }

    // Factor 2: Temperatura mínima
    if (tempMin <= 0) {
      risk += 6;
      factors.add('Temperatura bajo cero ❄️');
    } else if (tempMin <= 2) {
      risk += 4;
      factors.add('Temperatura crítica (0°C a 2°C)');
    } else if (tempMin <= 4) {
      risk += 2;
      factors.add('Temperatura muy baja');
    } else if (tempMin <= 6) {
      risk += 1;
    } else {
      risk -= 2; // Temps over 6 are generally safe
    }

    // Factor 3: Cielo despejado y sequedad (helada radiativa)
    if (humedad < 50 && nubosidad < 30) {
      risk += 3;
      factors.add('Cielo despejado y seco — Fuerte pérdida radiativa térmica');
    } else if (humedad > 80 && nubosidad > 70) {
      risk -= 2; // Nubes altas previenen heladas radiativas
    }

    // Factor 4: Viento (Mitigante de helada radiativa)
    if (viento > 15) {
      risk -= 3;
      factors.add('Viento fuerte — Mezcla el aire e impide la acumulación de frío superficial');
    } else if (viento > 8) {
      risk -= 1;
      factors.add('Viento moderado — Ayuda a mitigar la helada radiativa');
    } else if (viento < 3) {
      risk += 1;
      factors.add('Ausencia de viento — Permite el asentamiento de aire gélido (helada blanca)');
    }

    // Factor 5: Mes seco de Nariño
    if ([1, 2, 6, 7, 8, 12].contains(mes)) {
      risk += 1;
    }

    risk = risk.clamp(0, 10);

    final level = risk >= 7
        ? RiskLevel.high
        : risk >= 4
            ? RiskLevel.medium
            : RiskLevel.low;

    final confidence = ((60 + risk * 3.5) / 100.0).clamp(0.60, 0.98);

    final recommendation = switch (level) {
      RiskLevel.high =>
        '⚠️ ¡ALERTA ROJA! Aplica riego por aspersión al atardecer y cubre tus cultivos vulnerables (papa, mora, frutales).',
      RiskLevel.medium => '🟡 Precaución. Si el viento cesa por la noche, encienda quemadores ecológicos o revise a las 10 PM.',
      RiskLevel.low => '✅ Riesgo mínimo hoy. Condiciones térmicas estables para sus cultivos.',
    };

    return FrostPrediction(
      level: level,
      confidence: confidence,
      factors: factors.isEmpty ? ['Condiciones térmicas normales y estables'] : factors,
      recommendation: recommendation,
    );
  }
}

class SprayDecisionTree {
  SprayDecision predictFromForecast(List<WeatherDay> days) {
    if (days.isEmpty) {
      return const SprayDecision(
        isGood: false,
        windOk: false,
        rainOk: false,
        bestDay: 'Sin datos',
        bestTime: '7–10am o después de las 4pm',
      );
    }

    final bestIdx = days.indexWhere(
      (d) => d.windSpeed < 20 && d.rainProbability < 40,
    );

    final today = days.first;
    final isGood = today.windSpeed < 20 && today.rainProbability < 40;

    return SprayDecision(
      isGood: isGood,
      windOk: today.windSpeed < 20,
      rainOk: today.rainProbability < 40,
      bestDay: bestIdx >= 0 ? days[bestIdx].dayName : 'Revisa en 2 días',
      bestTime: '7–10am o después de las 4pm',
    );
  }
}
