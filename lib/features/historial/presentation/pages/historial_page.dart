import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/historial_bloc.dart';
import '../bloc/historial_event_state.dart';
import '../../domain/entities/historial_registro.dart';
import '../../../prediccion/domain/entities/frost_prediction.dart';
import '../../../../core/database/app_database.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/municipios_service.dart';
import '../../../../core/widgets/municipio_search_bottom_sheet.dart';
import '../../../finca/presentation/bloc/finca_bloc.dart';
import '../../../finca/presentation/bloc/finca_event_state.dart';
import '../../../finca/data/datasources/finca_sqlite_datasource.dart';
import '../../../finca/domain/entities/finca.dart';

class HistorialPage extends StatefulWidget {
  const HistorialPage({super.key});

  @override
  State<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends State<HistorialPage> {
  String _selectedMunicipio = 'Pasto';
  List<String> _userMunicipios = [];

  @override
  void initState() {
    super.initState();
    _initMunicipios();
  }

  Future<void> _initMunicipios() async {
    // 1. Obtener la finca activa actualmente seleccionada desde el BLoC
    final fincaBloc = context.read<FincaBloc>();
    final fincaState = fincaBloc.state;
    String initialMunicipio = 'Pasto';
    if (fincaState is FincaLoaded) {
      initialMunicipio = fincaState.finca.municipio;
    } else if (fincaState is FincaSaved) {
      initialMunicipio = fincaState.finca.municipio;
    }

    // 2. Cargar todas las fincas para sacar sus municipios únicos
    final sqliteDataSource = GetIt.I<FincaSQLiteDataSource>();
    final fincas = await sqliteDataSource.loadAllFincas();
    
    // Si no hay fincas, mostramos al menos el municipio inicial
    final municipios = fincas.map((f) => f.municipio).toSet().toList();
    if (municipios.isEmpty) {
      municipios.add(initialMunicipio);
    }

    setState(() {
      _userMunicipios = municipios;
      if (_userMunicipios.contains(initialMunicipio)) {
        _selectedMunicipio = initialMunicipio;
      } else {
        _selectedMunicipio = _userMunicipios.first;
      }
    });

    _loadData();
  }

  void _loadData() {
    context.read<HistorialBloc>().add(LoadHistorialEvent(_selectedMunicipio));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      appBar: AppBar(
        title: Text('📊 Historial Climático'),
        actions: [
          TextButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return MunicipioSearchBottomSheet(
                    municipios: _userMunicipios,
                    onSelected: (m) {
                      setState(() => _selectedMunicipio = m);
                      _loadData();
                    },
                  );
                },
              );
            },
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.verdeOscuro),
            label: Text(
              _selectedMunicipio,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.verdeOscuro,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<HistorialBloc, HistorialState>(
        builder: (context, state) {
          if (state is HistorialLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistorialError) {
            return Center(child: Text(state.message));
          }
          if (state is HistorialLoaded) {
            if (state.historial.isEmpty) {
              return _buildEmpty();
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChartCard(registros: state.historial),
                  const SizedBox(height: 24),
                  _EventsTable(eventos: state.eventosHelada),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('No hay datos históricos aún', style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Consulte el pronóstico para empezar a registrar.', style: GoogleFonts.dmSans(color: AppColors.gris)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<HistorialRegistro> registros;
  const _ChartCard({required this.registros});

  @override
  Widget build(BuildContext context) {
    // Tomamos los últimos 28 registros o lo que haya
    final data = registros.take(28).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.niebla),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Temperatura Mínima (°C)', style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Últimos 28 registros guardados', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gris)),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.tempMin)).toList(),
                    isCurved: true,
                    color: AppColors.verde,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: data.length < 10),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.verde.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsTable extends StatelessWidget {
  final List<HistorialRegistro> eventos;
  const _EventsTable({required this.eventos});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.niebla),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Alertas de Helada (Alto Riesgo)', 
              style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          if (eventos.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text('No se han registrado heladas en el último año.', 
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.gris)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: eventos.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final e = eventos[index];
                return ListTile(
                  leading: const Text('❄️', style: TextStyle(fontSize: 24)),
                  title: Text(DateFormat('dd MMMM, yyyy', 'es').format(e.fecha), 
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                  subtitle: Text('Temp Mín: ${e.tempMin}°C | ${e.municipio}', 
                    style: GoogleFonts.dmSans(fontSize: 12)),
                  trailing: Icon(Icons.chevron_right, color: AppColors.gris),
                );
              },
            ),
        ],
      ),
    );
  }
}
