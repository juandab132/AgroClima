import '../entities/frost_prediction.dart';

abstract class IPredictionRepository {
  FrostPrediction predictFrost({
    required int altitud,
    required double tempMin,
    required double humedad,
    required int mes,
    required double nubosidad,
  });

  SprayDecision getBestSprayDay(List<dynamic> days);
}
