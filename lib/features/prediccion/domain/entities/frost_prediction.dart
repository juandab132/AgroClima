import 'package:equatable/equatable.dart';

enum RiskLevel { low, medium, high }

class FrostPrediction extends Equatable {
  final RiskLevel level;
  final double confidence;
  final List<String> factors;
  final String recommendation;

  const FrostPrediction({
    required this.level,
    required this.confidence,
    required this.factors,
    required this.recommendation,
  });

  String get levelLabel {
    switch (level) {
      case RiskLevel.high:
        return 'ALTO';
      case RiskLevel.medium:
        return 'MEDIO';
      case RiskLevel.low:
        return 'BAJO';
    }
  }

  @override
  List<Object?> get props => [level, confidence, factors];
}

class SprayDecision extends Equatable {
  final bool isGood;
  final bool windOk;
  final bool rainOk;
  final String bestDay;
  final String bestTime;

  const SprayDecision({
    required this.isGood,
    required this.windOk,
    required this.rainOk,
    required this.bestDay,
    required this.bestTime,
  });

  @override
  List<Object?> get props => [isGood, windOk, rainOk, bestDay, bestTime];
}
