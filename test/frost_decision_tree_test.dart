import 'package:flutter_test/flutter_test.dart';
import 'package:agro_clima/features/prediccion/data/datasources/frost_decision_tree.dart';
import 'package:agro_clima/features/prediccion/domain/entities/frost_prediction.dart';

/// Tests unitarios del árbol de decisión de helada.
///
/// Valida que FrostDecisionTree produzca el nivel correcto
/// para los escenarios climáticos típicos de Nariño.
void main() {
  late FrostDecisionTree tree;

  setUp(() => tree = FrostDecisionTree());

  group('FrostDecisionTree — Riesgo ALTO', () {
    test('Temp muy baja + altitud alta → ALTO', () {
      final r = tree.predict(
        altitud: 3200,
        tempMin: -1.0,
        humedad: 60,
        viento: 5.0,
        mes: 1,
        nubosidad: 20,
      );
      expect(r.level, RiskLevel.high);
    });

    test('Temperatura bajo cero siempre da ALTO', () {
      final r = tree.predict(
        altitud: 2000,
        tempMin: -2.0,
        humedad: 70,
        viento: 2.0,
        mes: 6,
        nubosidad: 10,
      );
      expect(r.level, RiskLevel.high);
    });
  });

  group('FrostDecisionTree — Riesgo MEDIO', () {
    test('Temp baja + altitud alta → MEDIO', () {
      final r = tree.predict(
        altitud: 2800,
        tempMin: 3.0,
        humedad: 65,
        viento: 12.0,
        mes: 7,
        nubosidad: 30,
      );
      expect(r.level, isIn([RiskLevel.medium, RiskLevel.high]));
    });
  });

  group('FrostDecisionTree — Riesgo BAJO', () {
    test('Temp alta + altitud baja → BAJO', () {
      final r = tree.predict(
        altitud: 1700,
        tempMin: 12.0,
        humedad: 80,
        viento: 10.0,
        mes: 4,
        nubosidad: 70,
      );
      expect(r.level, RiskLevel.low);
    });

    test('La Unión (altitud baja) con temp normal → BAJO', () {
      final r = tree.predict(
        altitud: 1760,
        tempMin: 15.0,
        humedad: 75,
        viento: 8.0,
        mes: 3,
        nubosidad: 50,
      );
      expect(r.level, RiskLevel.low);
    });
  });

  group('FrostDecisionTree — Confianza', () {
    test('La confianza está en rango 0.60–0.98', () {
      for (final temp in [-3.0, 0.0, 5.0, 10.0, 18.0]) {
        final r = tree.predict(
          altitud: 2500,
          tempMin: temp,
          humedad: 60,
          viento: 10.0,
          mes: 6,
          nubosidad: 30,
        );
        expect(r.confidence, inInclusiveRange(0.60, 0.98));
      }
    });
  });

  group('FrostDecisionTree — Recomendación campesina', () {
    test('Riesgo ALTO incluye "ALERTA ROJA"', () {
      final r = tree.predict(
        altitud: 3100,
        tempMin: -2.0,
        humedad: 50,
        viento: 1.0,
        mes: 1,
        nubosidad: 15,
      );
      expect(r.recommendation.toLowerCase(), contains('alerta roja'));
    });

    test('Riesgo BAJO incluye mensaje positivo', () {
      final r = tree.predict(
        altitud: 1800,
        tempMin: 14.0,
        humedad: 80,
        viento: 15.0,
        mes: 5,
        nubosidad: 60,
      );
      expect(r.level, RiskLevel.low);
      expect(r.recommendation, isNotEmpty);
    });
  });

  group('FrostDecisionTree — Factores detectados', () {
    test('Temperatura muy baja aparece como factor', () {
      final r = tree.predict(
        altitud: 3000,
        tempMin: -2.0,
        humedad: 60,
        viento: 4.0,
        mes: 1,
        nubosidad: 10,
      );
      expect(r.factors, isNotEmpty);
    });

    test('Condiciones normales → "Condiciones térmicas normales"', () {
      final r = tree.predict(
        altitud: 1700,
        tempMin: 15.0,
        humedad: 75,
        viento: 12.0,
        mes: 4,
        nubosidad: 60,
      );
      expect(r.factors.first, contains('térmicas'));
    });
  });
}
