import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/cultivos_bloc.dart';
import '../bloc/cultivos_event_state.dart';
import '../../domain/entities/cultivo.dart';

class CultivosPage extends StatefulWidget {
  const CultivosPage({super.key});

  @override
  State<CultivosPage> createState() => _CultivosPageState();
}

class _CultivosPageState extends State<CultivosPage> {
  @override
  void initState() {
    super.initState();
    context.read<CultivosBloc>().add(LoadAllCropsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.crema,
      body: BlocBuilder<CultivosBloc, CultivosState>(
        builder: (context, state) {
          if (state is CultivosLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CultivosError) {
            return Center(child: Text(state.message));
          } else if (state is CultivosLoaded) {
            return _buildContent(state.allCrops);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildContent(List<Cultivo> crops) {
    final selectedCrops = crops.where((c) => c.activo).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.blanco,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🌱 Mis Cultivos',
                    style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.verdeOscuro)),
                const SizedBox(height: 4),
                Text('Seleccione los cultivos que tiene activos en su finca',
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.gris)),
              ],
            ),
          ),
        ),
        if (selectedCrops.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fichas Agronómicas',
                      style: GoogleFonts.fraunces(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.verdeOscuro)),
                  const SizedBox(height: 12),
                  ...selectedCrops.map((c) => _CropDetailCard(crop: c)),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Text('Todos los Cultivos',
                  style: GoogleFonts.fraunces(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.verdeOscuro)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final crop = crops[index];
                return _CropSelectTile(crop: crop);
              },
              childCount: crops.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _CropSelectTile extends StatelessWidget {
  final Cultivo crop;
  const _CropSelectTile({required this.crop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<CultivosBloc>().add(
            ToggleCropEvent(cropId: crop.id, isActive: !crop.activo));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: crop.activo ? AppColors.verde : AppColors.blanco,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: crop.activo ? AppColors.verde : AppColors.niebla,
              width: 2),
          boxShadow: crop.activo
              ? [
                  BoxShadow(
                      color: AppColors.verde.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_getEmoji(crop.id), style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              crop.nombre,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: crop.activo ? Colors.white : AppColors.verdeOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmoji(String id) {
    switch (id) {
      case 'papa': return '🥔';
      case 'mora': return '🍇';
      case 'cafe': return '☕';
      case 'maiz': return '🌽';
      case 'frijol': return '🫘';
      case 'lulo': return '🍈';
      case 'tomate': return '🍅';
      case 'cebolla': return '🧅';
      case 'ajo': return '🧄';
      case 'arveja': return '🫛';
      case 'habichuela': return '🥒';
      case 'frutilla': return '🍓';
      default: return '🌱';
    }
  }
}

class _CropDetailCard extends StatelessWidget {
  final Cultivo crop;
  const _CropDetailCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.niebla),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        backgroundColor: AppColors.blanco,
        collapsedBackgroundColor: AppColors.blanco,
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(crop.nombre,
            style: GoogleFonts.fraunces(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.verdeOscuro)),
        subtitle: Text('${crop.altitudMin}-${crop.altitudMax} m.s.n.m.',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.gris)),
        leading: CircleAvatar(
          backgroundColor: AppColors.niebla,
          child: Text(_getEmoji(crop.id)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                _InfoRow(label: 'Temperatura Óptima', value: '${crop.tempOptima}°C'),
                _InfoRow(label: 'Ciclo de Cosecha', value: crop.cicloCosecha),
                _InfoRow(label: 'Lluvia requerida', value: '${crop.lluviaRequerida} mm/año'),
                const SizedBox(height: 16),
                Text('Consejos para Nariño:',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tierra)),
                const SizedBox(height: 8),
                ...crop.consejosLocales.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(c, style: GoogleFonts.dmSans(fontSize: 13, height: 1.4))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getEmoji(String id) {
    switch (id) {
      case 'papa': return '🥔';
      case 'mora': return '🍇';
      case 'cafe': return '☕';
      case 'maiz': return '🌽';
      case 'frijol': return '🫘';
      case 'lulo': return '🍈';
      case 'tomate': return '🍅';
      case 'cebolla': return '🧅';
      case 'ajo': return '🧄';
      case 'arveja': return '🫛';
      case 'habichuela': return '🥒';
      case 'frutilla': return '🍓';
      default: return '🌱';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.gris)),
          Text(value, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.verdeOscuro)),
        ],
      ),
    );
  }
}
