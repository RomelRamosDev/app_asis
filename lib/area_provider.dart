import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'area_model.dart';

class AreaProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Area> _areas = [];
  Area? _areaActual;

  List<Area> get areas => _areas;
  Area? get areaActual => _areaActual;

  Future<void> cargarAreas() async {
    try {
      final response = await _supabase.from('areas').select();

      if (response != null && response is List) {
        _areas = response.map<Area>((map) {
          try {
            return Area.fromMap(map, map['id']?.toString() ?? '');
          } catch (e) {
            debugPrint('Error mapeando área: $e');
            return Area(id: '', nombre: 'Área inválida', sedeId: '');
          }
        }).toList();
      } else {
        _areas = [];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando áreas: $e');
      _areas = [];
      notifyListeners();
      rethrow;
    }
  }

  List<Area> areasPorSede(String sedeId) {
    return _areas.where((area) => area.sedeId == sedeId).toList();
  }

  void seleccionarArea(Area area) {
    _areaActual = area;
    notifyListeners();
  }

  Future<void> agregarArea(Area area) async {
    try {
      await _supabase.from('areas').insert(area.toMap());
      await cargarAreas();
    } catch (e) {
      debugPrint('Error agregando área: $e');
      rethrow;
    }
  }
}
