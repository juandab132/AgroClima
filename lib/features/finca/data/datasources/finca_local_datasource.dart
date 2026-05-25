import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/finca.dart';

class FincaLocalDataSource {
  static const _key = 'finca_data';

  Future<Finca?> loadFinca() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return Finca.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFinca(Finca finca) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(finca.toMap()));
  }
}
