import 'package:flutter_test/flutter_test.dart';
import 'package:agro_clima/core/errors/failures.dart';
import 'package:agro_clima/core/network/network_info.dart';

void main() {
  group('Failures — AGRO-30', () {
    test('ServerFailure guarda el mensaje correctamente', () {
      const f = ServerFailure('Error del servidor');
      expect(f.message, 'Error del servidor');
    });

    test('CacheFailure guarda el mensaje correctamente', () {
      const f = CacheFailure('Error de caché');
      expect(f.message, 'Error de caché');
    });

    test('NetworkFailure guarda el mensaje correctamente', () {
      const f = NetworkFailure('Sin red');
      expect(f.message, 'Sin red');
    });

    test('InputFailure guarda el mensaje correctamente', () {
      const f = InputFailure('Datos inválidos');
      expect(f.message, 'Datos inválidos');
    });

    test('ServerFailure con mismo mensaje son iguales (Equatable)', () {
      const a = ServerFailure('fallo');
      const b = ServerFailure('fallo');
      expect(a, equals(b));
    });

    test('Failures con distinto mensaje son diferentes', () {
      const a = ServerFailure('A');
      const b = ServerFailure('B');
      expect(a, isNot(equals(b)));
    });

    test('ServerException guarda el mensaje', () {
      const e = ServerException('timeout');
      expect(e.message, 'timeout');
    });

    test('CacheException guarda el mensaje', () {
      const e = CacheException('sin caché');
      expect(e.message, 'sin caché');
    });
  });

  group('NetworkInfoImpl — AGRO-30', () {
    test('isConnected devuelve true por defecto', () async {
      final info = NetworkInfoImpl();
      expect(await info.isConnected, isTrue);
    });
  });
}
