import 'package:flutter_test/flutter_test.dart';
import 'package:agro_clima/core/constants/app_strings.dart';

void main() {
  group('AppStrings — AGRO-42: lenguaje campesino', () {
    test('appName contiene el nombre de la app', () {
      expect(AppStrings.appName, isNotEmpty);
      expect(AppStrings.appName.toLowerCase(), contains('agroclima'));
    });

    test('saludo usa lenguaje campesino (compadre)', () {
      expect(AppStrings.bienvenido.toLowerCase(), contains('compadre'));
    });

    test('strings de riesgo tienen iconos visuales', () {
      expect(AppStrings.riesgoBajo, contains('✅'));
      expect(AppStrings.riesgoMedio, contains('⚠️'));
      expect(AppStrings.riesgoAlto, contains('🚨'));
    });

    test('strings de fumigación son descriptivos', () {
      expect(AppStrings.aptoPara, isNotEmpty);
      expect(AppStrings.noApto, isNotEmpty);
      expect(AppStrings.mejorDia, isNotEmpty);
    });

    test('ningún string crítico está vacío', () {
      final strings = [
        AppStrings.appName,
        AppStrings.appSubtitle,
        AppStrings.bienvenido,
        AppStrings.prediccion,
        AppStrings.pronostico,
        AppStrings.fumigacion,
        AppStrings.calcular,
        AppStrings.cargando,
        AppStrings.sinConexion,
      ];
      for (final s in strings) {
        expect(s, isNotEmpty, reason: 'El string no debe estar vacío');
      }
    });

    test('mejorHora sugiere horario de madrugada o tarde', () {
      expect(AppStrings.mejorHora, contains('am'));
    });
  });
}
