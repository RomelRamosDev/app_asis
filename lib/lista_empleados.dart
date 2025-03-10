import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'main.dart';

class ListaEmpleados extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final empleados = empleadoProvider.empleados;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Empleados'),
      ),
      body: ListView.builder(
        itemCount: empleados.length,
        itemBuilder: (context, index) {
          final empleado = empleados[index];
          return ListTile(
            title: Text('${empleado.nombre} ${empleado.apellido}'),
            subtitle:
                Text('Cédula: ${empleado.cedula} - Cargo: ${empleado.cargo}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla del formulario
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmpleadoForm(),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Agregar nuevo empleado',
      ),
    );
  }
}
