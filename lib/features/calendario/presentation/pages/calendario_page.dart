import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/calendario_bloc.dart';
import '../../domain/entities/calendario_cultivo.dart';
import '../../../cultivos/presentation/bloc/cultivos_bloc.dart';
import '../../../cultivos/presentation/bloc/cultivos_event_state.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  String? _selectedCropId;

  @override
  void initState() {
    super.initState();
    context.read<CalendarioBloc>().add(LoadCalendarioEvent());
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateTime.now().month;

    return Scaffold(
      backgroundColor: AppColors.crema,
      body: BlocBuilder<CalendarioBloc, CalendarioState>(
        builder: (context, state) {
          if (state is CalendarioLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CalendarioError) {
            return Center(child: Text(state.message));
          }
          if (state is CalendarioLoaded) {
            return BlocBuilder<CultivosBloc, CultivosState>(
              builder: (context, cultState) {
                final activeIds = cultState is CultivosLoaded ? cultState.selectedCrops.map((c) => c.id).toList() : <String>[];
                final filteredCalendars = state.calendarios
                    .where((c) => activeIds.contains(c.id))
                    .toList();
                
                // Si no hay ninguno seleccionado de los activos, tomamos el primero disponible
                if (_selectedCropId == null && filteredCalendars.isNotEmpty) {
                  _selectedCropId = filteredCalendars.first.id;
                } else if (_selectedCropId == null && state.calendarios.isNotEmpty) {
                  _selectedCropId = state.calendarios.first.id;
                }

                final selectedCal = state.calendarios.firstWhere(
                  (c) => c.id == _selectedCropId,
                  orElse: () => state.calendarios.first,
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📅 Calendario Agrícola',
                          style: GoogleFonts.fraunces(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.verdeOscuro)),
                      const SizedBox(height: 16),
                      
                      // Selector de cultivos activos
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: state.calendarios.map((c) {
                            final isActive = activeIds.contains(c.id);
                            final isSelected = _selectedCropId == c.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c.nombre),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) setState(() => _selectedCropId = c.id);
                                },
                                selectedColor: AppColors.verde,
                                labelStyle: GoogleFonts.dmSans(
                                  color: isSelected ? Colors.white : (isActive ? AppColors.verdeOscuro : AppColors.gris),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      _CalendarGrid(calendario: selectedCal, currentMonth: currentMonth),
                      
                      const SizedBox(height: 24),
                      _CropInfoCard(calendario: selectedCal),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final CalendarioCultivo calendario;
  final int currentMonth;

  const _CalendarGrid({required this.calendario, required this.currentMonth});

  @override
  Widget build(BuildContext context) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.niebla),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(color: Colors.green, label: 'Siembra'),
              _LegendItem(color: Colors.orange, label: 'Cosecha'),
              _LegendItem(color: Colors.blue, label: 'Fumigar'),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monthIdx = index + 1;
              final isCurrent = monthIdx == currentMonth;
              final isSiembra = calendario.mesesSiembra.contains(monthIdx);
              final isCosecha = calendario.mesesCosecha.contains(monthIdx);
              final isFumigacion = calendario.mesesFumigacion.contains(monthIdx);

              return Container(
                decoration: BoxDecoration(
                  color: isCurrent ? Colors.amber.withOpacity(0.1) : AppColors.crema.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrent ? Colors.amber : AppColors.niebla,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    if (isCurrent)
                      Positioned(
                        top: 4, right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                          child: Text('Hoy', style: GoogleFonts.dmSans(fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(months[index], 
                            style: GoogleFonts.dmSans(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: AppColors.verdeOscuro
                            )
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSiembra) _Dot(color: Colors.green),
                              if (isCosecha) _Dot(color: Colors.orange),
                              if (isFumigacion) _Dot(color: Colors.blue),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gris)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: 6, height: 6, 
      decoration: BoxDecoration(color: color, shape: BoxShape.circle)
    );
  }
}

class _CropInfoCard extends StatelessWidget {
  final CalendarioCultivo calendario;
  const _CropInfoCard({required this.calendario});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.verdeOscuro,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Observaciones para ${calendario.nombre}',
              style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.menta)),
          const SizedBox(height: 12),
          Text(calendario.observaciones,
              style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.5)),
        ],
      ),
    );
  }
}
