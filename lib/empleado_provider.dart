import 'package:supabase_flutter/supabase_flutter.dart';
import 'empleado_model.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:app_asis/sede_provider.dart';

class EmpleadoProvider with ChangeNotifier {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Empleado> _empleados = [];

  List<Empleado> get empleados => _empleados;

  // Agregar un empleado
  Future<void> agregarEmpleado(Empleado empleado) async {
    final uuid = Uuid().v4(); // Generar un UUID
    empleado.id = uuid; // Asignar el UUID al empleado
    assert(
        empleado.sedeId.isNotEmpty, 'El empleado debe tener una sede asignada');
    await supabase.from('empleados').insert(empleado.toMap());
    await cargarEmpleados(); // Recargar la lista de empleados
  }

  // Obtener todos los empleados
  Future<void> cargarEmpleados() async {
    final response = await supabase.from('empleados').select();
    _empleados = response.map((map) {
      return Empleado.fromMap(map, map['id'].toString()); // Convertir a String
    }).toList();
    notifyListeners(); // Notificar a los widgets que los datos han cambiado
  }

  // Eliminar un empleado
  Future<void> eliminarEmpleado(String id) async {
    await supabase.from('empleados').delete().eq('id', id);
    await cargarEmpleados();
  }

  // Actualizar un empleado
  Future<void> actualizarEmpleado(Empleado empleado) async {
    await supabase
        .from('empleados')
        .update(empleado.toMap())
        .eq('id', empleado.id!); // Usar .eq() correctamente
    await cargarEmpleados();
  }
}
