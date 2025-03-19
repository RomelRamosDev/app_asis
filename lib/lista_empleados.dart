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
          return Dismissible(
            key: Key(empleado.id.toString()), // Clave única para el empleado
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              // Mostrar un diálogo de confirmación antes de eliminar
              return await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Eliminar empleado'),
                    content: Text(
                        '¿Estás seguro de que deseas eliminar a ${empleado.nombre} ${empleado.apellido}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Eliminar'),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              // Eliminar el empleado
              empleadoProvider.eliminarEmpleado(empleado.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Empleado eliminado: ${empleado.nombre}'),
                ),
              );
            },
            child: ListTile(
              title: Text('${empleado.nombre} ${empleado.apellido}'),
              subtitle:
                  Text('Cédula: ${empleado.cedula} - Cargo: ${empleado.cargo}'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  // Navegar a la pantalla de edición
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmpleadoForm(empleado: empleado),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar a la pantalla del formulario para agregar un nuevo empleado
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
