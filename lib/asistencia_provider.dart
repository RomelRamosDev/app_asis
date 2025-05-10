import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'empleado_provider.dart';
import 'package:provider/provider.dart';
import 'sede_provider.dart';
import 'area_provider.dart';
import 'aistencia_model.dart';

class AsistenciaProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();
  List<Asistencia> _asistencias = [];
  bool _isLoading = false;

  List<Asistencia> get asistencias => _asistencias;

  // Cargar todas las asistencias (ahora incluye área)
  Future<void> cargarAsistencias() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('asistencias')
          .select()
          .order('horaEntrada', ascending: false);

      _asistencias = response
          .map((map) {
            try {
              return Asistencia.fromMap(map, map['id']?.toString() ?? '');
            } catch (e) {
              debugPrint('Error al mapear asistencia: $e\nDatos: $map');
              return null;
            }
          })
          .where((a) => a != null)
          .cast<Asistencia>()
          .toList();
    } catch (e) {
      debugPrint('Error al cargar asistencias: $e');
      _asistencias = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener asistencias por empleado (actualizado para filtrar por área si se especifica)
  Future<List<Asistencia>> getAsistenciasPorEmpleado(
    String cedula, {
    String? areaId,
  }) async {
    try {
      // Construimos la consulta base
      var query =
          _supabase.from('asistencias').select().eq('cedulaEmpleado', cedula);

      // Aplicamos el filtro de área si está presente
      if (areaId != null) {
        query = query.eq('area_id', areaId);
      }
      // Ejecutamos la consulta final
      final response = await query;

      return response
          .map((map) => Asistencia.fromMap(map, map['id'].toString()))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo asistencias por empleado: $e');
      return [];
    }
  }

  // Registrar entrada con validación de horario por área
  Future<void> registrarEntrada(
    BuildContext context, // Necesario para acceder a otros providers
    String cedulaEmpleado,
    String? observaciones,
    String sedeId,
    String areaId,
  ) async {
    try {
      final areaProvider = Provider.of<AreaProvider>(context, listen: false);
      final area = areaProvider.areas.firstWhere((a) => a.id == areaId);

      final horaActual = DateTime.now();
      bool atrasoEntrada = false;
      DateTime? horaEntradaArea = area.hora_entrada_area;

      // Calcular atraso si el área tiene horario definido
      if (horaEntradaArea != null) {
        final diferencia = horaActual.difference(horaEntradaArea);
        atrasoEntrada = diferencia.inMinutes > 15;
      }

      final Map<String, dynamic> datosAsistencia = {
        'id': _uuid.v4(),
        'cedulaEmpleado': cedulaEmpleado,
        'horaEntrada': horaActual.toIso8601String(),
        'atrasoEntrada': atrasoEntrada,
        'observaciones': observaciones,
        'sede_id': sedeId,
        'area_id': areaId,
      };

      // Solo agregar hora_entrada_area si existe
      if (horaEntradaArea != null) {
        datosAsistencia['hora_entrada_area'] =
            horaEntradaArea.toIso8601String();
      }

      await _supabase.from('asistencias').insert(datosAsistencia);
      await cargarAsistencias();
    } catch (e) {
      debugPrint('Error registrando entrada: $e');
      rethrow;
    }
  }

  // Registrar salida con validación de horario por área
  Future<void> registrarSalida(
    BuildContext context,
    String cedulaEmpleado,
    bool llevaTarjetas,
    String? observaciones,
    String sedeId,
    String areaId,
  ) async {
    try {
      final areaProvider = Provider.of<AreaProvider>(context, listen: false);
      final area = areaProvider.areas.firstWhere((a) => a.id == areaId);

      final horaActual = DateTime.now();
      DateTime? horaSalidaArea = area.hora_salida_area;
      bool atrasoSalida = false;

      // Calcular atraso si el área tiene horario definido
      if (horaSalidaArea != null) {
        final diferencia = horaActual.difference(horaSalidaArea);
        atrasoSalida = diferencia.inMinutes > 15; // Atraso después de 15 mins
      }

      // Buscar entrada pendiente en la misma área
      final asistencias =
          await getAsistenciasPorEmpleado(cedulaEmpleado, areaId: areaId);
      final asistenciaPendiente = asistencias.firstWhere(
        (a) => a.horaSalida == null,
        orElse: () => throw Exception('No hay entrada registrada en esta área'),
      );

      // Crear mapa de datos para actualizar
      final Map<String, dynamic> datosActualizacion = {
        'horaSalida': horaActual.toIso8601String(),
        'atrasoSalida': atrasoSalida,
        'llevaTarjetas': llevaTarjetas,
        'observaciones': observaciones,
      };

      // Solo agregar hora_salida_area si existe
      if (horaSalidaArea != null) {
        datosActualizacion['hora_salida_area'] =
            horaSalidaArea.toIso8601String();
      }

      await _supabase
          .from('asistencias')
          .update(datosActualizacion)
          .eq('id', asistenciaPendiente.id!);

      await cargarAsistencias();
    } catch (e) {
      debugPrint('Error registrando salida: $e');
      rethrow;
    }
  }

  // Métodos de consulta con filtrado por área
  Future<List<Asistencia>> getAsistenciasPorSedeYArea(
      String sedeId, String areaId,
      {bool ordenDescendente = true}) async {
    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('sede_id', sedeId)
        .eq('area_id', areaId)
        .order('horaEntrada', ascending: !ordenDescendente);

    return response
        .map((map) => Asistencia.fromMap(map, map['id']?.toString() ?? ''))
        .toList();
  }

  Future<List<Asistencia>> getAsistenciasPorEmpleadoYSedeYArea(
    String cedulaEmpleado,
    String sedeId,
    String areaId,
  ) async {
    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .eq('sede_id', sedeId)
        .eq('area_id', areaId)
        .order('horaEntrada', ascending: false);

    return response
        .map((map) => Asistencia.fromMap(map, map['id']?.toString() ?? ''))
        .toList();
  }

  // Verificaciones de estado con área
  Future<bool> haRegistradoEntradaHoy(
    String cedulaEmpleado,
    String sedeId,
    String areaId,
  ) async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .eq('sede_id', sedeId)
        .eq('area_id', areaId)
        .gte('horaEntrada', inicioDia.toIso8601String())
        .lte('horaEntrada', finDia.toIso8601String())
        .isFilter('horaSalida', null);

    return response.isNotEmpty;
  }

  Future<bool> haRegistradoSalidaHoy(
    String cedulaEmpleado,
    String sedeId,
    String areaId,
  ) async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .eq('sede_id', sedeId)
        .eq('area_id', areaId)
        .gte('horaEntrada', inicioDia.toIso8601String())
        .lte('horaEntrada', finDia.toIso8601String())
        .not('horaSalida', 'is', 'null');

    return response.isNotEmpty;
  }

  // Métodos para marcación automática (actualizados)
  Future<void> registrarEntradaAutomatica(
    String cedulaEmpleado,
    DateTime horaEntrada,
    String observaciones,
    String sedeId,
    String areaId,
    DateTime? horaEntradaArea,
  ) async {
    final asistencia = Asistencia(
      id: _uuid.v4(),
      cedulaEmpleado: cedulaEmpleado,
      horaEntrada: horaEntrada,
      atrasoEntrada: false,
      observaciones: observaciones,
      entradaAutomatica: true,
      sedeId: sedeId,
      areaId: areaId,
      horaEntradaArea: horaEntradaArea,
    );

    await _supabase.from('asistencias').insert(asistencia.toMap());
    await cargarAsistencias();
  }

  Future<void> registrarSalidaAutomatica(
    String idAsistencia,
    DateTime horaSalida,
    String observaciones,
    String areaId,
    DateTime? horaSalidaArea,
  ) async {
    await _supabase.from('asistencias').update({
      'horaSalida': horaSalida.toIso8601String(),
      'atrasoSalida': false,
      'observaciones': observaciones,
      'salidaAutomatica': true,
      'area_id': areaId,
      'hora_salida_area': horaSalidaArea?.toIso8601String(),
    }).eq('id', idAsistencia);

    await cargarAsistencias();
  }

  // Métodos de eliminación (actualizados para incluir área)
  Future<void> eliminarAsistenciasPorArea(String areaId) async {
    await _supabase.from('asistencias').delete().eq('area_id', areaId);
    await cargarAsistencias();
  }

  Future<void> eliminarAsistenciasPorSedeYArea(
    String sedeId,
    String areaId,
  ) async {
    await _supabase
        .from('asistencias')
        .delete()
        .eq('sede_id', sedeId)
        .eq('area_id', areaId);
    await cargarAsistencias();
  }

  // Resto de métodos permanecen igual (pero usarán los nuevos parámetros donde sea necesario)
  Future<void> eliminarAsistencia(String id) async {
    await _supabase.from('asistencias').delete().eq('id', id);
    await cargarAsistencias();
  }

  Future<void> eliminarAsistenciasPorCedula(String cedula) async {
    await _supabase.from('asistencias').delete().eq('cedulaEmpleado', cedula);
    await cargarAsistencias();
  }

  Future<void> eliminarAsistenciasPorFecha(
      DateTime fechaInicio, DateTime fechaFin,
      {String? areaId}) async {
    var query = _supabase
        .from('asistencias')
        .delete()
        .gte('horaEntrada', fechaInicio.toIso8601String())
        .lte('horaEntrada', fechaFin.toIso8601String());

    if (areaId != null) {
      query = query.eq('area_id', areaId);
    }

    await query;
    await cargarAsistencias();
  }
}
