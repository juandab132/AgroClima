import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import '../constants/app_colors.dart';
import '../services/municipios_service.dart';

class MunicipioSearchBottomSheet extends StatefulWidget {
  final List<String> municipios;
  final ValueChanged<String> onSelected;

  const MunicipioSearchBottomSheet({
    super.key,
    required this.municipios,
    required this.onSelected,
  });

  @override
  State<MunicipioSearchBottomSheet> createState() => _MunicipioSearchBottomSheetState();
}

class _MunicipioSearchBottomSheetState extends State<MunicipioSearchBottomSheet> {
  late List<String> _filteredMunicipios;
  late TextEditingController _searchCtrl;
  bool _isLoading = false;
  List<Map<String, dynamic>> _apiResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _filteredMunicipios = widget.municipios;
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchOnline(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _apiResults = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('https://geocoding-api.open-meteo.com/v1/search').replace(queryParameters: {
        'name': query,
        'count': '15',
        'language': 'es',
        'format': 'json',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['results'] != null) {
          final resultsList = List<Map<String, dynamic>>.from(data['results']);
          final narinoResults = resultsList.where((item) {
            final countryCode = item['country_code']?.toString().toUpperCase();
            final admin1 = item['admin1']?.toString().toLowerCase() ?? '';
            return countryCode == 'CO' && (admin1.contains('nariño') || admin1.contains('narino'));
          }).toList();

          setState(() {
            _apiResults = narinoResults;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() {
      _apiResults = [];
      _isLoading = false;
    });
  }

  void _filter(String query) {
    setState(() {
      _filteredMunicipios = widget.municipios
          .where((m) => m.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _searchOnline(query);
    });
  }

  Future<void> _saveCustomMunicipio(String name, double lat, double lon, int alt) async {
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getString('custom_municipios_data');
    Map<String, dynamic> data = {};
    if (customJson != null) {
      try {
        data = json.decode(customJson);
      } catch (_) {}
    }
    data[name] = {
      'lat': lat,
      'lon': lon,
      'alt': alt,
    };
    await prefs.setString('custom_municipios_data', json.encode(data));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.crema,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 20 + bottomInset,
      ),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seleccionar Municipio',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.verdeOscuro,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.gris),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            style: GoogleFonts.dmSans(),
            decoration: InputDecoration(
              hintText: 'Buscar municipio de Nariño...',
              hintStyle: GoogleFonts.dmSans(color: AppColors.gris),
              prefixIcon: const Icon(Icons.search, color: AppColors.verdeOscuro),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.gris),
                      onPressed: () {
                        _searchCtrl.clear();
                        _filter('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.blanco,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.niebla),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.niebla),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.verde, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.verde))
                : (_filteredMunicipios.isEmpty && _apiResults.isEmpty)
                    ? Center(
                        child: Text(
                          'No se encontraron municipios.',
                          style: GoogleFonts.dmSans(color: AppColors.gris),
                        ),
                      )
                    : ListView(
                        children: [
                          if (_filteredMunicipios.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('Recientes',
                                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gris)),
                            ),
                            ..._filteredMunicipios.map((m) => Card(
                              color: AppColors.blanco,
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.niebla)),
                              child: ListTile(
                                title: Text(m, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: AppColors.verdeOscuro)),
                                leading: const Icon(Icons.location_on_outlined, color: AppColors.verde),
                                trailing: const Icon(Icons.chevron_right, color: AppColors.gris),
                                onTap: () {
                                  widget.onSelected(m);
                                  Navigator.pop(context);
                                },
                              ),
                            )),
                          ],
                          if (_apiResults.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: Text('Resultados en la nube (Nariño)',
                                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gris)),
                            ),
                            ..._apiResults.map((item) {
                              final name = item['name'] as String;
                              final admin2 = item['admin2'] as String?;
                              final subtitleText = admin2 != null ? '$admin2, Nariño' : 'Nariño, Colombia';
                              return Card(
                                color: AppColors.blanco,
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.niebla)),
                                child: ListTile(
                                  title: Text(name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: AppColors.verdeOscuro)),
                                  subtitle: Text(subtitleText, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.gris)),
                                  leading: const Icon(Icons.cloud_queue_rounded, color: AppColors.verde),
                                  trailing: const Icon(Icons.star_border_rounded, color: AppColors.acento),
                                  onTap: () async {
                                    final lat = (item['latitude'] as num).toDouble();
                                    final lon = (item['longitude'] as num).toDouble();
                                    final alt = (item['elevation'] as num?)?.toInt() ?? 2500;

                                    // Dynamic registration in memory
                                    GetIt.I<MunicipiosService>().registerMunicipio(name, lat, lon, alt);
                                    
                                    // Persist local custom coordinate
                                    await _saveCustomMunicipio(name, lat, lon, alt);

                                    widget.onSelected(name);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
