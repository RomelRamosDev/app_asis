import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'aistencia_model.dart'; //
import 'package:uuid/uuid.dart';
import 'empleado_provider.dart';
import 'package:provider/provider.dart';
import 'sede_provider.dart';

class AsistenciaProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();
  List<Asistencia> _asistencias = [];
  bool _isLoading = false;

  List<Asistencia> get asistencias => _asistencias;

  // Cargar todas las asistencias
  Future<void> cargarAsistencias() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('asistencias')
          .select()
          .order('horaEntrada', ascending: false);

      debugPrint('Respuesta de Supabase: ${response.length} registros');

      final testData = await _supabase
          .from('asistencias')
          .select('id, cedulaEmpleado, horaEntrada, sede_id')
          .limit(1);
      debugPrint('Estructura de datos: $testData');

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

      debugPrint('Asistencias cargadas: ${_asistencias.length}');
    } catch (e) {
      debugPrint('Error crítico al cargar asistencias: $e');
      _asistencias = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener asistencias por empleado
  Future<List<Asistencia>> getAsistenciasPorEmpleado(String cedula) async {
    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedula)
        .order('horaEntrada', ascending: false);
    return response.map((map) {
      return Asistencia.fromMap(
          map, map['id'].toString()); // Convertir a String
    }).toList();
  }

  // Método registrarEntrada
  Future<void> registrarEntrada(
    String cedulaEmpleado,
    bool atrasoEntrada,
    String? observaciones,
    String sedeId, // Aseguramos que siempre se reciba
  ) async {
    try {
      final asistencia = Asistencia(
        id: Uuid().v4(),
        cedulaEmpleado: cedulaEmpleado,
        horaEntrada: DateTime.now(),
        atrasoEntrada: atrasoEntrada,
        observaciones: observaciones,
        sedeId: sedeId, // Usamos el ID proporcionado
      );

      // Debug: Verificar datos antes de insertar
      debugPrint('Registrando entrada con sedeId: $sedeId');
      debugPrint('Datos completos: ${asistencia.toMap()}');

      final response = await _supabase
          .from('asistencias')
          .insert(asistencia.toMap())
          .select()
          .single();

      debugPrint('Registro exitoso: $response');
      await cargarAsistencias();
    } catch (e) {
      debugPrint('Error registrando entrada: $e');
      rethrow;
    }
  }

  // Método registrarSalida
  Future<void> registrarSalida(
    String cedulaEmpleado,
    bool atrasoSalida,
    bool llevaTarjetas,
    String? observaciones,
    String sedeId,
  ) async {
    try {
      final asistencias = await getAsistenciasPorEmpleado(cedulaEmpleado);
      final asistenciaPendiente = asistencias.firstWhere(
        (a) => a.horaSalida == null,
        orElse: () =>
            throw Exception('No hay entrada registrada para marcar salida'),
      );

      await _supabase.from('asistencias').update({
        'horaSalida': DateTime.now().toIso8601String(),
        'atrasoSalida': atrasoSalida,
        'llevaTarjetas': llevaTarjetas,
        'observaciones': observaciones,
        'sede_id': sedeId,
      }).eq('id', asistenciaPendiente.id!);

      await cargarAsistencias();
    } catch (e) {
      debugPrint('Error registrando salida: $e');
      rethrow;
    }
  }

  Future<bool> haRegistradoEntrada(String cedulaEmpleado) async {
    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .isFilter('horaSalida', null);
    // Buscar entradas sin salida
    return response.isNotEmpty;
  }

  Future<bool> haRegistradoSalida(String cedulaEmpleado) async {
    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .not('horaSalida', 'is', 'null');
    // Buscar entradas con salida
    return response.isNotEmpty;
  }

  Future<void> eliminarAsistencia(String id) async {
    await _supabase.from('asistencias').delete().eq('id', id);
    await cargarAsistencias();
  }

  Future<void> eliminarAsistenciasPorCedula(String cedula) async {
    await _supabase.from('asistencias').delete().eq('cedulaEmpleado', cedula);
    await cargarAsistencias();
  }

  Future<void> eliminarAsistenciasPorFecha(
      DateTime fechaInicio, DateTime fechaFin) async {
    await _supabase
        .from('asistencias')
        .delete()
        .gte('horaEntrada', fechaInicio.toIso8601String())
        .lte('horaEntrada', fechaFin.toIso8601String());
    await cargarAsistencias();
  }

  Future<void> marcarAsistenciasAutomaticas(BuildContext context) async {
    final empleadoProvider =
        Provider.of<EmpleadoProvider>(context, listen: false);
    final sedeProvider = Provider.of<SedeProvider>(context, listen: false);

    final empleados = empleadoProvider.empleados;
    final sedeActualId = sedeProvider.sedeActual?.id;

    // Verificar si hay sede seleccionada
    if (sedeActualId == null) {
      debugPrint(
          'No se puede marcar asistencia automática: ninguna sede seleccionada');
      return;
    }

    for (final empleado in empleados) {
      if (empleado.enVacaciones || empleado.enPermisoMedico) {
        final hoy = DateTime.now();
        if (empleado.fechaInicioEstado != null &&
            empleado.fechaFinEstado != null &&
            hoy.isAfter(empleado.fechaInicioEstado!) &&
            hoy.isBefore(empleado.fechaFinEstado!)) {
          // Verificar si ya se registró la asistencia hoy
          final asistenciasHoy = await _supabase
              .from('asistencias')
              .select()
              .eq('cedula_empleado', empleado.cedula)
              .gte('horaEntrada',
                  DateTime(hoy.year, hoy.month, hoy.day).toIso8601String())
              .lte(
                  'horaEntrada',
                  DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59)
                      .toIso8601String());

          if (asistenciasHoy.isEmpty) {
            // Registrar la asistencia automáticamente
            await registrarEntrada(
              empleado.cedula,
              false, // No hay atraso
              'Asistencia automática (${empleado.enVacaciones ? 'Vacaciones' : 'Permiso médico'})',
              sedeActualId, // Añadir el ID de la sede actual
            );
          }
        }
      }
    }
  }

  Future<void> registrarEntradaAutomatica(String cedulaEmpleado,
      DateTime horaEntrada, String observaciones, String sedeId) async {
    final uuid = Uuid().v4();
    final asistencia = Asistencia(
      id: uuid,
      cedulaEmpleado: cedulaEmpleado,
      horaEntrada: horaEntrada,
      atrasoEntrada: true, // Consideramos que es atraso
      observaciones: observaciones,
      entradaAutomatica: true, // Marcamos como automática
      sedeId: sedeId,
    );

    await _supabase.from('asistencias').insert(asistencia.toMap());
    await cargarAsistencias();
  }

  Future<void> registrarSalidaAutomatica(
      String idAsistencia, DateTime horaSalida, String observaciones) async {
    await _supabase.from('asistencias').update({
      'horaSalida': horaSalida.toIso8601String(),
      'atrasoSalida': false, // No se considera atraso
      'observaciones': observaciones,
      'salidaAutomatica': true, // Marcamos como automática
    }).eq('id', idAsistencia);

    await cargarAsistencias();
  }

  Future<List<Asistencia>> getAsistenciasPorSede(String sedeId) async {
    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('sede_id', sedeId)
        .order('horaEntrada', ascending: false);

    return response.map((map) {
      return Asistencia.fromMap(map, map['id']?.toString() ?? '');
    }).toList();
  }

  Future<bool> haRegistradoEntradaHoy(
      String cedulaEmpleado, String sedeId) async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .eq('sede_id', sedeId)
        .gte('horaEntrada', inicioDia.toIso8601String())
        .lte('horaEntrada', finDia.toIso8601String())
        .isFilter('horaSalida', null);

    return response.isNotEmpty;
  }

  Future<bool> haRegistradoSalidaHoy(
      String cedulaEmpleado, String sedeId) async {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);

    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .eq('sede_id', sedeId)
        .gte('horaEntrada', inicioDia.toIso8601String())
        .lte('horaEntrada', finDia.toIso8601String())
        .not('horaSalida', 'is', 'null');

    return response.isNotEmpty;
  }

  Future<List<Asistencia>> getAsistenciasPorEmpleadoYSede(
      String cedulaEmpleado, String sedeId) async {
    final response = await _supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .eq('sede_id', sedeId)
        .order('horaEntrada', ascending: false);

    return response.map((map) {
      return Asistencia.fromMap(map, map['id']?.toString() ?? '');
    }).toList();
  }
}
