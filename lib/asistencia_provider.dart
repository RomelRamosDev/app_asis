import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'aistencia_model.dart'; //
import 'package:uuid/uuid.dart';
import 'empleado_provider.dart';
import 'empleado_model.dart';
import 'package:provider/provider.dart';

class AsistenciaProvider with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Asistencia> _asistencias = [];
  bool _isLoading = false;

  List<Asistencia> get asistencias => _asistencias;

  // Cargar todas las asistencias
  Future<void> cargarAsistencias() async {
    if (_isLoading) return; // Evitar múltiples llamadas
    _isLoading = true; // Marcar como cargando

    try {
      final response = await supabase.from('asistencias').select();
      print("Datos de asistencias: $response"); // Log para verificar los datos
      _asistencias = response.map((map) {
        return Asistencia.fromMap(map, map['id'].toString());
      }).toList();
      notifyListeners(); // Notificar a los listeners
    } catch (e) {
      print("Error al cargar asistencias: $e");
    } finally {
      _isLoading = false; // Marcar como no cargando
    }
  }

  // Obtener asistencias por empleado
  Future<List<Asistencia>> getAsistenciasPorEmpleado(String cedula) async {
    final response = await supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedula);
    return response.map((map) {
      return Asistencia.fromMap(
          map, map['id'].toString()); // Convertir a String
    }).toList();
  }

  // Método registrarEntrada
  Future<void> registrarEntrada(
      String cedulaEmpleado, bool atrasoEntrada, String? observaciones) async {
    final uuid = Uuid().v4(); // Generar un UUID
    final horaEntrada = DateTime.now();
    final asistencia = Asistencia(
      id: uuid,
      cedulaEmpleado: cedulaEmpleado,
      horaEntrada: horaEntrada, // Guardar en UTC
      atrasoEntrada: atrasoEntrada,
      observaciones: observaciones,
    );
    await supabase.from('asistencias').insert(asistencia.toMap());
    await cargarAsistencias();
  }

  // Método registrarSalida
  Future<void> registrarSalida(String cedulaEmpleado, bool atrasoSalida,
      bool llevaTarjetas, String? observaciones) async {
    final asistencias = await getAsistenciasPorEmpleado(cedulaEmpleado);
    final horaSalida = DateTime.now();
    final asistencia = asistencias.firstWhere(
      (asist) => asist.horaSalida == null,
    );
    asistencia.horaSalida = horaSalida;
    asistencia.atrasoSalida = atrasoSalida;
    asistencia.llevaTarjetas = llevaTarjetas;
    asistencia.observaciones = observaciones;
    await supabase
        .from('asistencias')
        .update(asistencia.toMap())
        .eq('id', asistencia.id!);
    await cargarAsistencias();
  }

  Future<bool> haRegistradoEntrada(String cedulaEmpleado) async {
    final response = await supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .isFilter('horaSalida', null); // Buscar entradas sin salida
    return response.isNotEmpty;
  }

  Future<bool> haRegistradoSalida(String cedulaEmpleado) async {
    final response = await supabase
        .from('asistencias')
        .select()
        .eq('cedulaEmpleado', cedulaEmpleado)
        .not('horaSalida', 'is', 'null'); // Buscar entradas con salida
    return response.isNotEmpty;
  }

  Future<void> eliminarAsistencia(String id) async {
    await supabase.from('asistencias').delete().eq('id', id);
    await cargarAsistencias();
  }

  Future<void> eliminarAsistenciasPorCedula(String cedula) async {
    await supabase.from('asistencias').delete().eq('cedulaEmpleado', cedula);
    await cargarAsistencias();
  }

  Future<void> eliminarAsistenciasPorFecha(
      DateTime fechaInicio, DateTime fechaFin) async {
    await supabase
        .from('asistencias')
        .delete()
        .gte('horaEntrada', fechaInicio.toIso8601String())
        .lte('horaEntrada', fechaFin.toIso8601String());
    await cargarAsistencias();
  }

  Future<void> marcarAsistenciasAutomaticas(BuildContext context) async {
    final empleadoProvider =
        Provider.of<EmpleadoProvider>(context, listen: false);
    final empleados = empleadoProvider.empleados;

    for (final empleado in empleados) {
      if (empleado.enVacaciones || empleado.enPermisoMedico) {
        final hoy = DateTime.now();
        if (empleado.fechaInicioEstado != null &&
            empleado.fechaFinEstado != null &&
            hoy.isAfter(empleado.fechaInicioEstado!) &&
            hoy.isBefore(empleado.fechaFinEstado!)) {
          // Verificar si ya se registró la asistencia hoy
          final asistenciasHoy = await supabase
              .from('asistencias')
              .select()
              .eq('cedulaEmpleado', empleado.cedula)
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
            );
          }
        }
      }
    }
  }

  Future<void> registrarEntradaAutomatica(
      String cedulaEmpleado, DateTime horaEntrada, String observaciones) async {
    final uuid = Uuid().v4();
    final asistencia = Asistencia(
      id: uuid,
      cedulaEmpleado: cedulaEmpleado,
      horaEntrada: horaEntrada,
      atrasoEntrada: true, // Consideramos que es atraso
      observaciones: observaciones,
      entradaAutomatica: true, // Marcamos como automática
    );

    await supabase.from('asistencias').insert(asistencia.toMap());
    await cargarAsistencias();
  }

  Future<void> registrarSalidaAutomatica(
      String idAsistencia, DateTime horaSalida, String observaciones) async {
    await supabase.from('asistencias').update({
      'horaSalida': horaSalida.toIso8601String(),
      'atrasoSalida': false, // No se considera atraso
      'observaciones': observaciones,
      'salidaAutomatica': true, // Marcamos como automática
    }).eq('id', idAsistencia);

    await cargarAsistencias();
  }
}
