import 'package:flutter/material.dart';
import 'aistencia_model.dart';
import 'database_helper.dart';

class AsistenciaProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Asistencia> _asistencias = [];

  List<Asistencia> get asistencias => _asistencias;

  // Cargar asistencias desde la base de datos
  Future<void> cargarAsistencias() async {
    _asistencias = await _dbHelper.getAsistencias();
    notifyListeners();
  }

  // Método para registrar la entrada
  Future<void> registrarEntrada(String cedulaEmpleado) async {
    final asistencia = Asistencia(
      cedulaEmpleado: cedulaEmpleado,
      horaEntrada: DateTime.now(),
    );
    await _dbHelper.insertAsistencia(asistencia);
    await cargarAsistencias();
  }

  // Método para registrar la salida
  Future<void> registrarSalida(String cedulaEmpleado) async {
    final asistencia = _asistencias.firstWhere(
      (asist) =>
          asist.cedulaEmpleado == cedulaEmpleado && asist.horaSalida == null,
    );
    asistencia.horaSalida = DateTime.now();
    await _dbHelper.insertAsistencia(asistencia);
    await cargarAsistencias();
  }

  // Método para obtener las asistencias de un empleado
  Future<List<Asistencia>> asistenciasPorEmpleado(String cedulaEmpleado) async {
    await cargarAsistencias(); // Asegurarse de que los datos estén actualizados
    return _asistencias
        .where((asist) => asist.cedulaEmpleado == cedulaEmpleado)
        .toList();
  }

  // Método para verificar si un empleado ha registrado su entrada
  Future<bool> haRegistradoEntrada(String cedulaEmpleado) async {
    await cargarAsistencias(); // Asegurarse de que los datos estén actualizados
    return _asistencias.any((asist) =>
        asist.cedulaEmpleado == cedulaEmpleado && asist.horaSalida == null);
  }

  // Método para verificar si un empleado ha registrado su salida
  Future<bool> haRegistradoSalida(String cedulaEmpleado) async {
    await cargarAsistencias(); // Asegurarse de que los datos estén actualizados
    return _asistencias.any((asist) =>
        asist.cedulaEmpleado == cedulaEmpleado && asist.horaSalida != null);
  }
}
