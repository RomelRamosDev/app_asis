import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sede_model.dart';

class SedeProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Sede> _sedes = [];
  Sede? _sedeActual;

  List<Sede> get sedes => _sedes;
  Sede? get sedeActual => _sedeActual;

  Future<void> cargarSedes() async {
    try {
      final response = await _supabase.from('sedes').select();
      _sedes = response.map((map) => Sede.fromMap(map, map['id'])).toList();
      notifyListeners();
    } catch (e) {
      print('Error cargando sedes: $e');
    }
  }

  void seleccionarSede(Sede sede) {
    _sedeActual = sede;
    notifyListeners();
  }
}
