import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:agro_clima/core/services/municipios_service.dart';
import 'package:agro_clima/features/pronostico/domain/entities/weather_forecast.dart';
import 'package:agro_clima/features/finca/presentation/bloc/finca_bloc.dart';
import 'package:agro_clima/features/finca/presentation/bloc/finca_event_state.dart';
import 'package:agro_clima/features/registro/presentation/pages/registro_finca_page.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockFincaBloc extends Mock implements FincaBloc {}
class MockMunicipiosService extends Mock implements MunicipiosService {}

// ── Helper de construcción del widget ────────────────────────────────────────

Widget _buildSubject(FincaBloc bloc) {
  return MaterialApp(
    routes: {
      '/home': (_) => const Scaffold(body: Text('Home')),
      '/registro': (_) => const RegistroFincaPage(),
    },
    home: BlocProvider<FincaBloc>.value(
      value: bloc,
      child: const RegistroFincaPage(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  late MockFincaBloc mockBloc;
  late MockMunicipiosService mockMunSvc;

  setUp(() async {
    final sl = GetIt.instance;
    await sl.reset();
    mockMunSvc = MockMunicipiosService();
    when(() => mockMunSvc.municipios).thenReturn({
      'Pasto': const MunicipioData(lat: 1.214, lon: -77.279, altitud: 2527),
      'Túquerres': const MunicipioData(lat: 0.823, lon: -77.642, altitud: 3070),
    });
    when(() => mockMunSvc.getMunicipio(any())).thenReturn(
      const MunicipioData(lat: 1.214, lon: -77.279, altitud: 2527)
    );
    sl.registerSingleton<MunicipiosService>(mockMunSvc);

    mockBloc = MockFincaBloc();
    when(() => mockBloc.state).thenReturn(FincaInitial());
    when(() => mockBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  group('RegistroFincaPage — validación de formulario', () {
    testWidgets('Paso 0: muestra error si nombre de finca está vacío', (tester) async {
      await tester.pumpWidget(_buildSubject(mockBloc));
      await tester.pumpAndSettle();

      final nextBtn = find.text('Siguiente →');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('Por favor escriba el nombre de su finca'), findsOneWidget);
    });

    testWidgets('Paso 0: avanza al paso 1 con datos válidos', (tester) async {
      await tester.pumpWidget(_buildSubject(mockBloc));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(0), 'Finca El Mirador');
      await tester.tap(find.text('Siguiente →'));
      await tester.pumpAndSettle();

      expect(find.text('¿En qué municipio está su finca?'), findsOneWidget);
    });

    testWidgets('Paso 1 → 2: botón Siguiente avanza al paso 2 (riego)', (tester) async {
      await tester.pumpWidget(_buildSubject(mockBloc));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(0), 'La Cocha');
      await tester.tap(find.text('Siguiente →'));
      await tester.pumpAndSettle();

      // Scroll down to find the "Siguiente →" button (Step 1 is now longer with GPS fields)
      await tester.scrollUntilVisible(
        find.text('Siguiente →'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Siguiente →'));
      await tester.pumpAndSettle();

      expect(find.text('¿Qué tipo de riego usa usted?'), findsOneWidget);
    });
  });

  group('RegistroFincaPage — navegación atrás', () {
    testWidgets('Botón Atrás en paso 1 regresa al paso 0', (tester) async {
      await tester.pumpWidget(_buildSubject(mockBloc));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextFormField).at(0), 'El Vergel');
      await tester.tap(find.text('Siguiente →'));
      await tester.pumpAndSettle();

      // Scroll down to find the "← Atrás" button (Step 1 is now longer with GPS fields)
      await tester.scrollUntilVisible(
        find.text('← Atrás'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('← Atrás'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo se llama su finca?'), findsOneWidget);
    });
  });
}
