import 'package:flutter/material.dart';
import 'empleado_model.dart';
import 'database_helper.dart';

class EmpleadoProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Empleado> _empleados = [];

  List<Empleado> get empleados => _empleados;

  Future<void> cargarEmpleados() async {
    _empleados = await _dbHelper.getEmpleados();
    notifyListeners();
  }

  Future<void> agregarEmpleado(Empleado empleado) async {
    await _dbHelper.insertEmpleado(empleado);
    await cargarEmpleados();
  }
}
