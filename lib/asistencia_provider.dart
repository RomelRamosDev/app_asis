import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'aistencia_model.dart'; //
import 'package:uuid/uuid.dart';

class AsistenciaProvider with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Asistencia> _asistencias = [];

  List<Asistencia> get asistencias => _asistencias;

  // Cargar todas las asistencias
  Future<void> cargarAsistencias() async {
    final response = await supabase.from('asistencias').select();
    _asistencias = response.map((map) {
      return Asistencia.fromMap(
          map, map['id'].toString()); // Convertir a String
    }).toList();
    notifyListeners(); // Notificar a los widgets que los datos han cambiado
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

  // Registrar la entrada de un empleado
  Future<void> registrarEntrada(
      String cedulaEmpleado, bool atrasoEntrada) async {
    final uuid = Uuid().v4(); // Generar un UUID
    final horaEntrada = DateTime.now(); // Hora local del dispositivo
    final asistencia = Asistencia(
      id: uuid, // Asignar el UUID a la asistencia
      cedulaEmpleado: cedulaEmpleado,
      horaEntrada: horaEntrada, // Guardar la hora local
      atrasoEntrada: atrasoEntrada, // Registrar el atraso
    );
    await supabase.from('asistencias').insert(asistencia.toMap());
    await cargarAsistencias(); // Recargar la lista de asistencias
  }

  Future<void> registrarSalida(
      String cedulaEmpleado, bool atrasoSalida, bool llevaTarjetas) async {
    final asistencias =
        await getAsistenciasPorEmpleado(cedulaEmpleado); // Usar cedulaEmpleado
    final asistencia = asistencias.firstWhere(
      (asist) => asist.horaSalida == null,
    );
    asistencia.horaSalida =
        DateTime.now().toUtc(); // Convertir la hora local a UTC
    asistencia.atrasoSalida = atrasoSalida; // Registrar el atraso
    asistencia.llevaTarjetas = llevaTarjetas; // Registrar si lleva tarjetas
    await supabase
        .from('asistencias')
        .update(asistencia.toMap())
        .eq('id', asistencia.id!); // Usar .eq() correctamente
    await cargarAsistencias(); // Recargar la lista de asistencias
  }

  // Verificar si un empleado ha registrado su entrada
  Future<bool> haRegistradoEntrada(String cedulaEmpleado) async {
    await cargarAsistencias();
    return _asistencias.any((asist) =>
        asist.cedulaEmpleado == cedulaEmpleado && asist.horaSalida == null);
  }

  // Verificar si un empleado ha registrado su salida
  Future<bool> haRegistradoSalida(String cedulaEmpleado) async {
    await cargarAsistencias();
    return _asistencias.any((asist) =>
        asist.cedulaEmpleado == cedulaEmpleado && asist.horaSalida != null);
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
}
